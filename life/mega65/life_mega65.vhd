library ieee;
   use ieee.std_logic_1164.all;
   use ieee.numeric_std_unsigned.all;

entity life_mega65 is
   generic (
      G_ROWS       : integer          := 8;
      G_COLS       : integer          := 7;
      G_CELLS_INIT : std_logic_vector := "00000000" &
                                         "00010000" &
                                         "00001000" &
                                         "00111000" &
                                         "00000000" &
                                         "00000000" &
                                         "00000000"
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
end entity life_mega65;

architecture structural of life_mega65 is

   signal clk           : std_logic;
   signal rst           : std_logic;
   signal uart_rx_valid : std_logic;
   signal uart_rx_ready : std_logic;
   signal uart_rx_data  : std_logic_vector(7 downto 0);
   signal uart_tx_valid : std_logic;
   signal uart_tx_ready : std_logic;
   signal uart_tx_data  : std_logic_vector(7 downto 0);
   signal life_board    : std_logic_vector(G_ROWS * G_COLS - 1 downto 0);
   signal life_step     : std_logic;
   signal life_wr_index : integer range G_ROWS * G_COLS - 1 downto 0;
   signal life_wr_value : std_logic;
   signal life_wr_en    : std_logic;

begin

   mega65_inst : entity work.mega65
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
         clk_o           => clk,
         rst_o           => rst,
         uart_tx_valid_i => uart_tx_valid,
         uart_tx_ready_o => uart_tx_ready,
         uart_tx_data_i  => uart_tx_data,
         uart_rx_valid_o => uart_rx_valid,
         uart_rx_ready_i => uart_rx_ready,
         uart_rx_data_o  => uart_rx_data
      ); -- mega65_inst

   -- User Interface
   controller_inst : entity work.controller
      generic map (
         G_ROWS => G_ROWS,
         G_COLS => G_COLS
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
         board_i         => life_board,
         step_o          => life_step,
         wr_index_o      => life_wr_index,
         wr_value_o      => life_wr_value,
         wr_en_o         => life_wr_en
      ); -- controller_inst

   -- This controls the board.
   life_inst : entity work.life
      generic map (
         G_ROWS       => G_ROWS,
         G_COLS       => G_COLS,
         G_CELLS_INIT => G_CELLS_INIT
      )
      port map (
         clk_i    => clk,
         rst_i    => rst,
         board_o  => life_board,
         en_i     => life_step,
         index_i  => life_wr_index,
         value_i  => life_wr_value,
         update_i => life_wr_en
      ); -- life_inst

end architecture structural;

