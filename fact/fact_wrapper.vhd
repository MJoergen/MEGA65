library ieee;
   use ieee.std_logic_1164.all;
   use ieee.numeric_std_unsigned.all;

entity fact_wrapper is
   generic (
      G_SIZE     : integer := 256;
      G_VAL_SIZE : integer := 64;
      G_LOG_SIZE : integer := 8
   );
   port (
      clk_i           : in    std_logic;
      rst_i           : in    std_logic;

      uart_rx_valid_i : in    std_logic;
      uart_rx_ready_o : out   std_logic;
      uart_rx_data_i  : in    std_logic_vector(7 downto 0);
      uart_tx_valid_o : out   std_logic;
      uart_tx_ready_i : in    std_logic;
      uart_tx_data_o  : out   std_logic_vector(7 downto 0);

      vga_clk_i       : in    std_logic;
      vga_hcount_i    : in    std_logic_vector(10 downto 0);
      vga_vcount_i    : in    std_logic_vector(10 downto 0);
      vga_blank_i     : in    std_logic;
      vga_rgb_o       : out   std_logic_vector(7 downto 0)
   );
end entity fact_wrapper;

architecture behavioral of fact_wrapper is

   signal epp_val2 : std_logic_vector(G_VAL_SIZE - 1 downto 0);

   signal fact_data  : std_logic_vector(G_VAL_SIZE - 1 downto 0);
   signal fact_start : std_logic;

   signal ctrl_val2      : std_logic_vector(G_SIZE - 1 downto 0);
   signal ctrl_valid     : std_logic;
   signal ctrl_ready     : std_logic;
   signal ctrl_state_log : std_logic_vector(G_LOG_SIZE - 1 downto 0);

   signal eol_valid : std_logic;
   signal eol_ready : std_logic;
   signal eol_data  : std_logic_vector(7 downto 0);

   signal dec_valid : std_logic;
   signal dec_last  : std_logic;
   signal dec_ready : std_logic;
   signal dec_data  : std_logic_vector(3 downto 0);

begin

   uart_rx_ready_o <= '1';

   uart_rx_proc : process (clk_i)
   begin
      if rising_edge(clk_i) then
         fact_start <= '0';
         if uart_rx_valid_i = '1' then
            if uart_rx_data_i >= character'pos('0') and uart_rx_data_i <= character'pos('9') then
               epp_val2 <= (epp_val2(G_VAL_SIZE - 4 downto 0) & "000") +
                           (epp_val2(G_VAL_SIZE - 2 downto 0) & "0") +
                           to_stdlogicvector(to_integer(uart_rx_data_i - character'pos('0')), G_VAL_SIZE);
            elsif uart_rx_data_i = X"0D" then
               fact_start <= '1';
               fact_data  <= epp_val2;
               epp_val2   <= (others => '0');
            end if;
         end if;

         if rst_i = '1' then
            epp_val2 <= (others => '0');
         end if;
      end if;
   end process uart_rx_proc;

   fact_inst : entity work.fact
      generic map (
         G_SIZE     => G_SIZE,
         G_VAL_SIZE => G_VAL_SIZE,
         G_LOG_SIZE => G_LOG_SIZE
      )
      port map (
         clk_i            => clk_i,
         rst_i            => rst_i,
         epp_val2_i       => fact_data,
         epp_start_i      => fact_start,
         ctrl_val2_o      => ctrl_val2,
         ctrl_valid_o     => ctrl_valid,
         ctrl_ready_i     => ctrl_ready,
         ctrl_state_log_o => ctrl_state_log
      ); -- fact_inst

   slv_to_dec_inst : entity work.slv_to_dec
      generic map (
         G_SIZE => G_SIZE
      )
      port map (
         clk_i       => clk_i,
         rst_i       => rst_i,
         slv_valid_i => ctrl_valid,
         slv_ready_o => ctrl_ready,
         slv_data_i  => ctrl_val2,
         dec_valid_o => dec_valid,
         dec_ready_i => dec_ready,
         dec_data_o  => dec_data,
         dec_last_o  => dec_last
      ); -- slv_to_dec_inst

   serializer_inst : entity work.serializer
      generic map (
         G_DATA_SIZE_IN  => 16,
         G_DATA_SIZE_OUT => 8
      )
      port map (
         clk_i     => clk_i,
         rst_i     => rst_i,
         s_valid_i => dec_last,
         s_ready_o => open,
         s_data_i  => X"0D0A",
         m_valid_o => eol_valid,
         m_ready_i => eol_ready,
         m_data_o  => eol_data
      ); -- serializer_inst

   merginator_inst : entity work.merginator
      generic map (
         G_DATA_SIZE => 8
      )
      port map (
         clk_i      => clk_i,
         rst_i      => rst_i,
         s1_valid_i => dec_valid,
         s1_ready_o => dec_ready,
         s1_data_i  => "0011" & dec_data,
         s2_valid_i => eol_valid,
         s2_ready_o => eol_ready,
         s2_data_i  => eol_data,
         m_valid_o  => uart_tx_valid_o,
         m_ready_i  => uart_tx_ready_i,
         m_data_o   => uart_tx_data_o
      ); -- merginator_inst

end architecture behavioral;

