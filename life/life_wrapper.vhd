library ieee;
   use ieee.std_logic_1164.all;
   use ieee.numeric_std_unsigned.all;

library xpm;
   use xpm.vcomponents.all;

library work;
   use work.video_modes_pkg.all;

entity life_wrapper is
   generic (
      G_FONT_PATH  : string := "";
      G_ROWS       : integer;
      G_COLS       : integer;
      G_CELLS_INIT : std_logic_vector
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
      vga_rst_i       : in    std_logic;
      vga_hcount_i    : in    std_logic_vector(10 downto 0);
      vga_vcount_i    : in    std_logic_vector(10 downto 0);
      vga_blank_i     : in    std_logic;
      vga_rgb_o       : out   std_logic_vector(7 downto 0)
   );
end entity life_wrapper;

architecture synthesis of life_wrapper is

   signal life_board    : std_logic_vector(G_ROWS * G_COLS - 1 downto 0);
   signal life_count    : std_logic_vector(15 downto 0);
   signal life_step     : std_logic;
   signal life_wr_index : integer range G_ROWS * G_COLS - 1 downto 0;
   signal life_wr_value : std_logic;
   signal life_wr_en    : std_logic;

   signal vga_count       : std_logic_vector(15 downto 0);
   signal vga_board       : std_logic_vector(G_ROWS * G_COLS - 1 downto 0);
   signal vga_count_board : std_logic_vector(G_ROWS * G_COLS + 15  downto 0);

begin

   -- User Interface
   controller_inst : entity work.controller
      generic map (
         G_ROWS => G_ROWS,
         G_COLS => G_COLS
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
         clk_i    => clk_i,
         rst_i    => rst_i,
         en_i     => life_step,
         board_o  => life_board,
         index_i  => life_wr_index,
         value_i  => life_wr_value,
         update_i => life_wr_en
      ); -- life_inst

   life_count_proc : process (clk_i)
   begin
      if rising_edge(clk_i) then
         if life_step then
            life_count <= life_count + 1;
         end if;
         if rst_i then
            life_count <= (others => '0');
         end if;
      end if;
   end process life_count_proc;

   xpm_cdc_array_single_inst : component xpm_cdc_array_single
      generic map (
         WIDTH => G_ROWS * G_COLS + 16
      )
      port map (
         src_clk  => clk_i,
         src_in   => life_count & life_board,
         dest_clk => vga_clk_i,
         dest_out => vga_count_board
      ); -- xpm_cdc_array_single_inst

   (vga_count, vga_board) <= vga_count_board;

   vga_wrapper_inst : entity work.vga_wrapper
      generic map (
         G_FONT_PATH => G_FONT_PATH,
         G_ROWS      => G_ROWS,
         G_COLS      => G_COLS
      )
      port map (
         vga_clk_i    => vga_clk_i,
         vga_rst_i    => vga_rst_i,
         vga_hcount_i => vga_hcount_i,
         vga_vcount_i => vga_vcount_i,
         vga_blank_i  => vga_blank_i,
         vga_board_i  => vga_board,
         vga_count_i  => vga_count,
         vga_rgb_o    => vga_rgb_o
      ); -- vga_wrapper_inst

end architecture synthesis;

