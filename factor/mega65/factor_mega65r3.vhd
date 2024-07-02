library ieee;
   use ieee.std_logic_1164.all;
   use ieee.numeric_std_unsigned.all;

library xpm;
   use xpm.vcomponents.all;

library work;
   use work.video_modes_pkg.all;

entity factor_mega65r3 is
   generic (
      G_NUM_WORKERS     : natural;
      G_PRIME_ADDR_SIZE : natural;
      G_DATA_SIZE       : natural;
      G_VECTOR_SIZE     : natural
   );
   port (
      -- Clock
      sys_clk_i      : in    std_logic; -- 100 MHz
      sys_rstn_i     : in    std_logic;
      uart_rxd_i     : in    std_logic;
      uart_txd_o     : out   std_logic;
      vga_red_o      : out   std_logic_vector(7 downto 0);
      vga_green_o    : out   std_logic_vector(7 downto 0);
      vga_blue_o     : out   std_logic_vector(7 downto 0);
      vga_hs_o       : out   std_logic;
      vga_vs_o       : out   std_logic;
      vdac_clk_o     : out   std_logic;
      vdac_blank_n_o : out   std_logic;
      vdac_sync_n_o  : out   std_logic;
      kb_io0_o       : out   std_logic;
      kb_io1_o       : out   std_logic;
      kb_io2_i       : in    std_logic
   );
end entity factor_mega65r3;

architecture synthesis of factor_mega65r3 is

   constant C_VIDEO_MODE : video_modes_type := C_VIDEO_MODE_1280_720_60;

   signal   clk : std_logic;
   signal   rst : std_logic;

   signal   uart_tx_valid : std_logic;
   signal   uart_tx_ready : std_logic;
   signal   uart_tx_data  : std_logic_vector(7 downto 0);
   signal   uart_rx_valid : std_logic;
   signal   uart_rx_ready : std_logic;
   signal   uart_rx_data  : std_logic_vector(7 downto 0);

   signal   vga_clk    : std_logic;
   signal   vga_hcount : std_logic_vector(10 downto 0);
   signal   vga_vcount : std_logic_vector(10 downto 0);
   signal   vga_blank  : std_logic;
   signal   vga_rgb    : std_logic_vector(7 downto 0);

begin

   mega65_inst : entity work.mega65
      generic map (
         G_UART_DIVISOR => 100_000_000 / 2_000_000,
         G_VIDEO_MODE   => C_VIDEO_MODE
      )
      port map (
         -- MEGA65 I/O ports
         sys_clk_i       => sys_clk_i,
         sys_rstn_i      => sys_rstn_i,
         uart_rxd_i      => uart_rxd_i,
         uart_txd_o      => uart_txd_o,
         kb_io0_o        => kb_io0_o,
         kb_io1_o        => kb_io1_o,
         kb_io2_i        => kb_io2_i,
         vga_red_o       => vga_red_o,
         vga_green_o     => vga_green_o,
         vga_blue_o      => vga_blue_o,
         vga_hs_o        => vga_hs_o,
         vga_vs_o        => vga_vs_o,
         vdac_clk_o      => vdac_clk_o,
         vdac_blank_n_o  => vdac_blank_n_o,
         vdac_sync_n_o   => vdac_sync_n_o,
         -- Connection to design
         vga_clk_o       => vga_clk,
         vga_hcount_o    => vga_hcount,
         vga_vcount_o    => vga_vcount,
         vga_blank_o     => vga_blank,
         vga_rgb_i       => vga_rgb,
         clk_o           => clk,
         rst_o           => rst,
         uart_rx_valid_o => uart_rx_valid,
         uart_rx_ready_i => uart_rx_ready,
         uart_rx_data_o  => uart_rx_data,
         uart_tx_valid_i => uart_tx_valid,
         uart_tx_ready_o => uart_tx_ready,
         uart_tx_data_i  => uart_tx_data
      ); -- mega65_inst

   factor_wrapper_inst : entity work.factor_wrapper
      generic map (
         G_NUM_WORKERS     => G_NUM_WORKERS,
         G_PRIME_ADDR_SIZE => G_PRIME_ADDR_SIZE,
         G_DATA_SIZE       => G_DATA_SIZE,
         G_VECTOR_SIZE     => G_VECTOR_SIZE
      )
      port map (
         clk_i           => clk,
         rst_i           => rst,
         uart_rx_valid_i => uart_rx_valid,
         uart_rx_ready_o => uart_rx_ready,
         uart_rx_data_i  => uart_rx_data,
         uart_tx_valid_o => uart_tx_valid,
         uart_tx_ready_i => uart_tx_ready,
         uart_tx_data_o  => uart_tx_data,
         vga_clk_i       => vga_clk,
         vga_hcount_i    => vga_hcount,
         vga_vcount_i    => vga_vcount,
         vga_blank_i     => vga_blank,
         vga_rgb_o       => vga_rgb
      ); -- factor_wrapper_inst

end architecture synthesis;

