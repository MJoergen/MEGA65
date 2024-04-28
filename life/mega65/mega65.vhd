library ieee;
   use ieee.std_logic_1164.all;
   use ieee.numeric_std_unsigned.all;

library xpm;
   use xpm.vcomponents.all;

library work;
   use work.video_modes_pkg.all;

entity mega65 is
   generic (
      G_ROWS : integer;
      G_COLS : integer
   );
   port (
      -- MEGA65 I/O ports
      sys_clk_i       : in    std_logic;
      sys_rstn_i      : in    std_logic;
      uart_rxd_i      : in    std_logic;
      uart_txd_o      : out   std_logic;
      kb_io0_o        : out   std_logic;
      kb_io1_o        : out   std_logic;
      kb_io2_i        : in    std_logic;
      vga_red_o       : out   std_logic_vector(7 downto 0);
      vga_green_o     : out   std_logic_vector(7 downto 0);
      vga_blue_o      : out   std_logic_vector(7 downto 0);
      vga_hs_o        : out   std_logic;
      vga_vs_o        : out   std_logic;
      vdac_clk_o      : out   std_logic;
      vdac_blank_n_o  : out   std_logic;
      vdac_sync_n_o   : out   std_logic;
      -- Connection to design
      clk_o           : out   std_logic;
      rst_o           : out   std_logic;
      uart_tx_valid_i : in    std_logic;
      uart_tx_ready_o : out   std_logic;
      uart_tx_data_i  : in    std_logic_vector(7 downto 0);
      uart_rx_valid_o : out   std_logic;
      uart_rx_ready_i : in    std_logic;
      uart_rx_data_o  : out   std_logic_vector(7 downto 0);
      board_i         : in    std_logic_vector(G_ROWS * G_COLS - 1 downto 0)
   );
end entity mega65;

architecture synthesis of mega65 is

   -- video mode selection: 720p @ 60 Hz
   constant C_VIDEO_MODE : video_modes_type := C_VIDEO_MODE_1280_720_60;
   constant C_FONT_FILE  : string           := "font8x8.txt";

   signal   vga_clk   : std_logic;
   signal   vga_rst   : std_logic;
   signal   vga_board : std_logic_vector(G_ROWS * G_COLS - 1 downto 0);

begin

   clk_inst : entity work.clk
      port map (
         sys_clk_i  => sys_clk_i,
         sys_rstn_i => sys_rstn_i,
         vga_clk_o  => vga_clk,
         vga_rst_o  => vga_rst,
         clk_o      => clk_o,
         rst_o      => rst_o
      );

   m2m_keyb_inst : entity work.m2m_keyb
      port map (
         clk_main_i       => sys_clk_i,
         clk_main_speed_i => 100 * 1000 * 1000,
         kio8_o           => kb_io0_o,
         kio9_o           => kb_io1_o,
         kio10_i          => kb_io2_i,
         enable_core_i    => '1',
         key_num_o        => open,
         key_pressed_n_o  => open,
         drive_led_i      => '0',
         qnice_keys_n_o   => open
      ); -- m2m_keyb_inst

   uart_inst : entity work.uart
      port map (
         clk_i      => clk_o,
         rst_i      => rst_o,
         tx_valid_i => uart_tx_valid_i,
         tx_ready_o => uart_tx_ready_o,
         tx_data_i  => uart_tx_data_i,
         rx_valid_o => uart_rx_valid_o,
         rx_ready_i => uart_rx_ready_i,
         rx_data_o  => uart_rx_data_o,
         uart_tx_o  => uart_txd_o,
         uart_rx_i  => uart_rxd_i
      ); -- uart_inst

   xpm_cdc_array_single_inst : component xpm_cdc_array_single
      generic map (
         WIDTH => G_ROWS * G_COLS
      )
      port map (
         src_clk  => clk_o,
         src_in   => board_i,
         dest_clk => vga_clk,
         dest_out => vga_board
      ); -- xpm_cdc_array_single_inst

   video_inst : entity work.video
      generic map (
         G_FONT_FILE  => C_FONT_FILE,
         G_ROWS       => G_ROWS,
         G_COLS       => G_COLS,
         G_VIDEO_MODE => C_VIDEO_MODE
      )
      port map (
         rst_i         => vga_rst,
         clk_i         => vga_clk,
         board_i       => vga_board,
         video_vs_o    => vga_vs_o,
         video_hs_o    => vga_hs_o,
         video_de_o    => open,
         video_red_o   => vga_red_o,
         video_green_o => vga_green_o,
         video_blue_o  => vga_blue_o
      ); -- video_inst

   vdac_clk_o     <= vga_clk;
   vdac_sync_n_o  <= '0';
   vdac_blank_n_o <= '1';

end architecture synthesis;

