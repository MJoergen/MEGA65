library ieee;
   use ieee.std_logic_1164.all;
   use ieee.numeric_std_unsigned.all;

entity factor_wrapper is
   generic (
      G_PRIME_ADDR_SIZE : integer;
      G_DATA_SIZE       : integer;
      G_VECTOR_SIZE     : integer
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
end entity factor_wrapper;

architecture behavioral of factor_wrapper is

   signal dut_s_start : std_logic;
   signal dut_s_val   : std_logic_vector(2 * G_DATA_SIZE - 1 downto 0);
   signal dut_m_ready : std_logic;
   signal dut_m_valid : std_logic;
   signal dut_m_data  : std_logic_vector(2 * G_DATA_SIZE - 1 downto 0);
   signal dut_m_fail  : std_logic;

   signal s2d_s_ready : std_logic;
   signal s2d_s_valid : std_logic;
   signal s2d_s_data  : std_logic_vector(2 * G_DATA_SIZE - 1 downto 0);
   signal s2d_m_ready : std_logic;
   signal s2d_m_valid : std_logic;
   signal s2d_m_data  : std_logic_vector(3 downto 0);
   signal s2d_m_last  : std_logic;

   signal ser_s_ready : std_logic;
   signal ser_s_valid : std_logic;
   signal ser_s_data  : std_logic_vector(15 downto 0);
   signal ser_m_ready : std_logic;
   signal ser_m_valid : std_logic;
   signal ser_m_data  : std_logic_vector(7 downto 0);

   signal merg_s1_ready : std_logic;
   signal merg_s1_valid : std_logic;
   signal merg_s1_data  : std_logic_vector(7 downto 0);
   signal merg_s2_ready : std_logic;
   signal merg_s2_valid : std_logic;
   signal merg_s2_data  : std_logic_vector(7 downto 0);

begin

   uart_rx_ready_o <= '1';

   -- Read decimal number from UART input
   uart_rx_proc : process (clk_i)
   begin
      if rising_edge(clk_i) then
         dut_s_start <= '0';

         if uart_rx_valid_i = '1' then
            if uart_rx_data_i = X"0D" then
               dut_s_start <= '1';
            elsif uart_rx_data_i /= X"0A" then
               dut_s_val <= (dut_s_val(2 * G_DATA_SIZE - 2 downto 0) & "0") +
                            (dut_s_val(2 * G_DATA_SIZE - 4 downto 0) & "000") +
                             uart_rx_data_i - X"30";
            end if;
         end if;

         if rst_i = '1' or dut_s_start = '1' then
            dut_s_start <= '0';
            dut_s_val   <= (others => '0');
         end if;
      end if;
   end process uart_rx_proc;

   factor_inst : entity work.factor
      generic map (
         G_PRIME_ADDR_SIZE => G_PRIME_ADDR_SIZE,
         G_DATA_SIZE       => G_DATA_SIZE,
         G_VECTOR_SIZE     => G_VECTOR_SIZE
      )
      port map (
         clk_i     => clk_i,
         rst_i     => rst_i,
         s_start_i => dut_s_start,
         s_val_i   => dut_s_val,
         m_ready_i => dut_m_ready,
         m_valid_o => dut_m_valid,
         m_data_o  => dut_m_data,
         m_fail_o  => dut_m_fail
      ); -- factor_inst

   dut_m_ready <= s2d_s_ready;
   s2d_s_valid <= dut_m_valid;
   s2d_s_data  <= dut_m_data;

   slv_to_dec_inst : entity work.slv_to_dec
      generic map (
         G_DATA_SIZE => 2 * G_DATA_SIZE
      )
      port map (
         clk_i     => clk_i,
         rst_i     => rst_i,
         s_ready_o => s2d_s_ready,
         s_valid_i => s2d_s_valid,
         s_data_i  => s2d_s_data,
         m_ready_i => s2d_m_ready,
         m_valid_o => s2d_m_valid,
         m_data_o  => s2d_m_data,
         m_last_o  => s2d_m_last
      ); -- slv_to_dec_inst


   ser_s_valid <= s2d_m_last;
   ser_s_data  <= X"0D0A";

   serializer_inst : entity work.serializer
      generic map (
         G_DATA_SIZE_IN  => 16,
         G_DATA_SIZE_OUT => 8
      )
      port map (
         clk_i     => clk_i,
         rst_i     => rst_i,
         s_ready_o => ser_s_ready,
         s_valid_i => ser_s_valid,
         s_data_i  => ser_s_data,
         m_ready_i => ser_m_ready,
         m_valid_o => ser_m_valid,
         m_data_o  => ser_m_data
      ); -- serializer_inst


   s2d_m_ready   <= merg_s1_ready;
   merg_s1_valid <= s2d_m_valid;
   merg_s1_data  <= "0011" & s2d_m_data;
   ser_m_ready   <= merg_s2_ready;
   merg_s2_valid <= ser_m_valid;
   merg_s2_data  <= ser_m_data;

   merginator_inst : entity work.merginator
      generic map (
         G_DATA_SIZE => 8
      )
      port map (
         clk_i      => clk_i,
         rst_i      => rst_i,
         s1_ready_o => merg_s1_ready,
         s1_valid_i => merg_s1_valid,
         s1_data_i  => merg_s1_data,
         s2_ready_o => merg_s2_ready,
         s2_valid_i => merg_s2_valid,
         s2_data_i  => merg_s2_data,
         m_ready_i  => uart_tx_ready_i,
         m_valid_o  => uart_tx_valid_o,
         m_data_o   => uart_tx_data_o
      ); -- merginator_inst

end architecture behavioral;

