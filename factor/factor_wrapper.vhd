library ieee;
   use ieee.std_logic_1164.all;
   use ieee.numeric_std_unsigned.all;

entity factor_wrapper is
   generic (
      G_NUM_WORKERS     : natural;
      G_PRIME_ADDR_SIZE : natural;
      G_DATA_SIZE       : natural;
      G_VECTOR_SIZE     : natural
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

   signal dut_s_ready : std_logic;
   signal dut_s_valid : std_logic;
   signal dut_s_data  : std_logic_vector(G_DATA_SIZE - 1 downto 0);
   signal dut_m_ready : std_logic;
   signal dut_m_valid : std_logic;
   signal dut_m_data  : std_logic_vector(G_DATA_SIZE - 1 downto 0);

begin

   controller_inst : entity work.controller
      generic map (
         G_DATA_SIZE => G_DATA_SIZE / 2
      )
      port map (
         clk_i           => clk_i,
         rst_i           => rst_i,
         uart_rx_valid_i => uart_rx_valid_i,
         uart_rx_ready_o => uart_rx_ready_o,
         uart_rx_data_i  => uart_rx_data_i,
         uart_tx_valid_o => uart_tx_valid_o,
         uart_tx_ready_i => uart_tx_ready_i,
         uart_tx_data_o  => uart_tx_data_o,
         vga_clk_i       => vga_clk_i,
         vga_hcount_i    => vga_hcount_i,
         vga_vcount_i    => vga_vcount_i,
         vga_blank_i     => vga_blank_i,
         vga_rgb_o       => vga_rgb_o,
         dut_s_ready_i   => dut_s_ready,
         dut_s_valid_o   => dut_s_valid,
         dut_s_data_o    => dut_s_data,
         dut_m_ready_o   => dut_m_ready,
         dut_m_valid_i   => dut_m_valid,
         dut_m_data_i    => dut_m_data
      ); -- controller_inst

   factor_inst : entity work.factor
      generic map (
         G_NUM_WORKERS     => G_NUM_WORKERS,
         G_PRIME_ADDR_SIZE => G_PRIME_ADDR_SIZE,
         G_DATA_SIZE       => G_DATA_SIZE,
         G_VECTOR_SIZE     => G_VECTOR_SIZE
      )
      port map (
         clk_i     => clk_i,
         rst_i     => rst_i,
         s_ready_o => dut_s_ready,
         s_valid_i => dut_s_valid,
         s_data_i  => dut_s_data,
         m_ready_i => dut_m_ready,
         m_valid_o => dut_m_valid,
         m_data_o  => dut_m_data
      ); -- factor_inst

end architecture behavioral;

