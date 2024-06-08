library ieee;
   use ieee.std_logic_1164.all;
   use ieee.numeric_std_unsigned.all;

entity cf_wrapper is
   generic (
      G_DATA_SIZE : integer
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
end entity cf_wrapper;

architecture behavioral of cf_wrapper is

   signal cf_s_start : std_logic;
   signal cf_s_val   : std_logic_vector(2 * G_DATA_SIZE - 1 downto 0);
   signal cf_m_ready : std_logic;
   signal cf_m_valid : std_logic;
   signal cf_m_res_x : std_logic_vector(2 * G_DATA_SIZE - 1 downto 0);
   signal cf_m_res_p : std_logic_vector(G_DATA_SIZE - 1 downto 0);
   signal cf_m_res_w : std_logic;

   signal dec_valid : std_logic;
   signal dec_last  : std_logic;
   signal dec_ready : std_logic;
   signal dec_data  : std_logic_vector(3 downto 0);

   signal eol_valid : std_logic;
   signal eol_ready : std_logic;
   signal eol_data  : std_logic_vector(7 downto 0);

begin

   uart_rx_ready_o <= '1';

   uart_rx_proc : process (clk_i)
   begin
      if rising_edge(clk_i) then
         cf_s_start <= '0';

         if uart_rx_valid_i = '1' then
            if uart_rx_data_i = X"0D" then
               cf_s_start <= '1';
            else
               cf_s_val <= cf_s_val * 10 + uart_rx_data_i - X"30";
            end if;
         end if;

         if rst_i = '1' then
            cf_s_start <= '0';
            cf_s_val   <= (others => '0');
         end if;
      end if;
   end process uart_rx_proc;

   cf_inst : entity work.cf
      generic map (
         G_DATA_SIZE => G_DATA_SIZE
      )
      port map (
         clk_i     => clk_i,
         rst_i     => rst_i,
         s_start_i => cf_s_start,
         s_val_i   => cf_s_val,
         m_ready_i => cf_m_ready,
         m_valid_o => cf_m_valid,
         m_res_x_o => cf_m_res_x,
         m_res_p_o => cf_m_res_p,
         m_res_w_o => cf_m_res_w
      ); -- cf_inst

   slv_to_dec_inst : entity work.slv_to_dec
      generic map (
         G_DATA_SIZE => G_DATA_SIZE
      )
      port map (
         clk_i     => clk_i,
         rst_i     => rst_i,
         s_valid_i => cf_m_valid,
         s_ready_o => cf_m_ready,
         s_data_i  => cf_m_res_x,
         m_valid_o => dec_valid,
         m_ready_i => dec_ready,
         m_data_o  => dec_data,
         m_last_o  => dec_last
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

