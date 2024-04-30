library ieee;
   use ieee.std_logic_1164.all;
   use ieee.numeric_std_unsigned.all;

library xpm;
   use xpm.vcomponents.all;

library work;
   use work.video_modes_pkg.all;

entity cards_wrapper is
   generic (
      G_PAIRS : integer := 4
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
end entity cards_wrapper;


architecture synthesis of cards_wrapper is

   constant C_VIDEO_MODE : video_modes_type := C_VIDEO_MODE_1280_720_60;

   signal   cards_board : std_logic_vector(2 * G_PAIRS * G_PAIRS - 1 downto 0);
   signal   cards_valid : std_logic;
   signal   cards_done  : std_logic;

   signal   vga_board : std_logic_vector(2 * G_PAIRS * G_PAIRS - 1 downto 0);

begin

   uart_rx_ready_o <= '1';
   uart_tx_valid_o <= '0';
   uart_tx_data_o  <= (others => '0');

   cards_inst : entity work.cards
      generic map (
         G_PAIRS => G_PAIRS
      )
      port map (
         clk_i      => clk_i,
         rst_i      => rst_i,
         en_i       => '1',
         cards_o    => cards_board,
         cards_or_o => open,
         invalid_o  => open,
         valid_o    => cards_valid,
         done_o     => cards_done
      ); -- cards_inst

   xpm_cdc_array_single_inst : component xpm_cdc_array_single
      generic map (
         WIDTH => 2 * G_PAIRS * G_PAIRS
      )
      port map (
         src_clk  => clk_i,
         src_in   => cards_board,
         dest_clk => vga_clk_i,
         dest_out => vga_board
      ); -- xpm_cdc_array_single_inst


   -- This generates the image
   disp_cards_inst : entity work.disp_cards
      generic map (
         G_PAIRS => G_PAIRS
      )
      port map (
         vga_clk_i    => vga_clk_i,
         vga_hcount_i => vga_hcount_i,
         vga_vcount_i => vga_vcount_i,
         vga_blank_i  => vga_blank_i,
         vga_cards_i  => vga_board,
         vga_rgb_o    => vga_rgb_o
      ); -- disp_cards_inst

end architecture synthesis;

