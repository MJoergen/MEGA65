library ieee;
   use ieee.std_logic_1164.all;
   use ieee.numeric_std_unsigned.all;

library unisim;
   use unisim.vcomponents.all;

library xpm;
   use xpm.vcomponents.all;

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

   signal pll_clk_fb   : std_logic;
   signal pll_clk_core : std_logic;
   signal pll_locked   : std_logic;

   signal dut_s_ready : std_logic;
   signal dut_s_valid : std_logic;
   signal dut_s_data  : std_logic_vector(G_DATA_SIZE - 1 downto 0);
   signal dut_m_ready : std_logic;
   signal dut_m_valid : std_logic;
   signal dut_m_data  : std_logic_vector(G_DATA_SIZE - 1 downto 0);

   signal core_clk     : std_logic;
   signal core_rst     : std_logic;
   signal core_s_ready : std_logic;
   signal core_s_valid : std_logic;
   signal core_s_data  : std_logic_vector(G_DATA_SIZE - 1 downto 0);
   signal core_m_ready : std_logic;
   signal core_m_valid : std_logic;
   signal core_m_data  : std_logic_vector(G_DATA_SIZE - 1 downto 0);

begin

   pll_inst : component plle2_base
      generic map (
         BANDWIDTH          => "OPTIMIZED",
         CLKFBOUT_MULT      => 12,   -- 1200 MHz
         CLKFBOUT_PHASE     => 0.000,
         CLKIN1_PERIOD      => 10.0, -- INPUT @ 100 MHz
         CLKOUT0_DIVIDE     => 10,   -- OUTPUT @ 120 MHz
         CLKOUT0_DUTY_CYCLE => 0.500,
         CLKOUT0_PHASE      => 0.000,
         DIVCLK_DIVIDE      => 1,
         REF_JITTER1        => 0.010,
         STARTUP_WAIT       => "FALSE"
      )
      port map (
         clkfbin  => pll_clk_fb,
         clkfbout => pll_clk_fb,
         clkin1   => clk_i,
         clkout0  => pll_clk_core,
         locked   => pll_locked,
         pwrdwn   => '0',
         rst      => rst_i
      ); -- pll_inst

   bufg_inst : component bufg
      port map (
         i => pll_clk_core,
         o => core_clk
      ); -- bufg_inst

   xpm_cdc_sync_rst_inst : component xpm_cdc_sync_rst
      generic map (
         INIT_SYNC_FF => 1
      )
      port map (
         src_rst  => rst_i or not pll_locked,
         dest_clk => core_clk,
         dest_rst => core_rst
      ); -- xpm_cdc_sync_rst_inst

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

   axi_fifo_s_inst : entity work.axi_fifo
      generic map (
         G_DEPTH     => 16,
         G_DATA_SIZE => G_DATA_SIZE
      )
      port map (
         s_clk_i   => clk_i,
         s_rst_i   => rst_i,
         s_ready_o => dut_s_ready,
         s_valid_i => dut_s_valid,
         s_data_i  => dut_s_data,
         m_clk_i   => core_clk,
         m_ready_i => core_s_ready,
         m_valid_o => core_s_valid,
         m_data_o  => core_s_data
      ); -- axi_fifo_s_inst

   axi_fifo_m_inst : entity work.axi_fifo
      generic map (
         G_DEPTH     => 16,
         G_DATA_SIZE => G_DATA_SIZE
      )
      port map (
         s_clk_i   => core_clk,
         s_rst_i   => core_rst,
         s_ready_o => core_m_ready,
         s_valid_i => core_m_valid,
         s_data_i  => core_m_data,
         m_clk_i   => clk_i,
         m_ready_i => dut_m_ready,
         m_valid_o => dut_m_valid,
         m_data_o  => dut_m_data
      ); -- axi_fifo_m_inst

   factor_inst : entity work.factor
      generic map (
         G_NUM_WORKERS     => G_NUM_WORKERS,
         G_PRIME_ADDR_SIZE => G_PRIME_ADDR_SIZE,
         G_DATA_SIZE       => G_DATA_SIZE,
         G_VECTOR_SIZE     => G_VECTOR_SIZE
      )
      port map (
         clk_i     => core_clk,
         rst_i     => core_rst,
         s_ready_o => core_s_ready,
         s_valid_i => core_s_valid,
         s_data_i  => core_s_data,
         m_ready_i => core_m_ready,
         m_valid_o => core_m_valid,
         m_data_o  => core_m_data
      ); -- factor_inst

end architecture behavioral;

