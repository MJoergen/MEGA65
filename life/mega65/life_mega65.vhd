library ieee;
   use ieee.std_logic_1164.all;
   use ieee.numeric_std_unsigned.all;

entity life_mega65 is
   generic (
      G_ROWS       : integer          := 8;
      G_COLS       : integer          := 7;
      G_CELLS_INIT : std_logic_vector := (0 to 55 => '0')
   );
   port (
      -- Clock
      clk_i              : in    std_logic; -- 100 MHz
      max10_clkandsync_o : out   std_logic := '1';
      max10_rx_o         : out   std_logic := '1';
      max10_tx_i         : in    std_logic;

      uart_rxd_i         : in    std_logic;
      uart_txd_o         : out   std_logic;

      vga_red_o          : out   std_logic_vector(7 downto 0) := X"00";
      vga_green_o        : out   std_logic_vector(7 downto 0) := X"00";
      vga_blue_o         : out   std_logic_vector(7 downto 0) := X"00";
      vga_hs_o           : out   std_logic := '0';
      vga_vs_o           : out   std_logic := '0';
      vdac_clk_o         : out   std_logic := '0';
      vdac_blank_n_o     : out   std_logic := '0';
      vdac_sync_n_o      : out   std_logic := '0';

      kb_io0_o           : out   std_logic := '1';
      kb_io1_o           : out   std_logic := '1';
      kb_io2_i           : in    std_logic
   );
end entity life_mega65;

architecture structural of life_mega65 is

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

   -- This controls the board.
   life_inst : entity work.life
      generic map (
         G_ROWS       => G_ROWS,
         G_COLS       => G_COLS,
         G_CELLS_INIT => G_CELLS_INIT
      )
      port map (
         clk_i    => clk_i,
         rst_i    => max10_tx_i,
         board_o  => life_board,
         en_i     => life_step,
         index_i  => life_wr_index,
         value_i  => life_wr_value,
         update_i => life_wr_en
      ); -- life_inst

   -- User Interface
   controller_inst : entity work.controller
      generic map (
         G_ROWS => G_ROWS,
         G_COLS => G_COLS
      )
      port map (
         clk_i           => clk_i,
         rst_i           => max10_tx_i,
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

   uart_inst : entity work.uart
      port map (
         clk_i      => clk_i,
         rst_i      => max10_tx_i,
         tx_valid_i => uart_tx_valid,
         tx_ready_o => uart_tx_ready,
         tx_data_i  => uart_tx_data,
         rx_valid_o => uart_rx_valid,
         rx_ready_i => uart_rx_ready,
         rx_data_o  => uart_rx_data,
         uart_tx_o  => uart_txd_o,
         uart_rx_i  => uart_rxd_i
      ); -- uart_inst

end architecture structural;

