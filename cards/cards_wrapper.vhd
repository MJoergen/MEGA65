library ieee;
   use ieee.std_logic_1164.all;
   use ieee.numeric_std_unsigned.all;

library xpm;
   use xpm.vcomponents.all;

library work;
   use work.video_modes_pkg.all;

entity cards_wrapper is
   generic (
      G_FONT_PATH : string  := "";
      G_PAIRS     : integer := 4
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
end entity cards_wrapper;


architecture synthesis of cards_wrapper is

   signal cards_step  : std_logic;
   signal cards_board : std_logic_vector(2 * G_PAIRS * G_PAIRS - 1 downto 0);
   signal cards_count : std_logic_vector(15 downto 0);
   signal cards_valid : std_logic;
   signal cards_done  : std_logic;

   signal vga_count       : std_logic_vector(15 downto 0);
   signal vga_board       : std_logic_vector(2 * G_PAIRS * G_PAIRS - 1 downto 0);
   signal vga_count_board : std_logic_vector(2 * G_PAIRS * G_PAIRS + 15  downto 0);


begin

   -- User Interface
   controller_inst : entity work.controller
      generic map (
         G_PAIRS => G_PAIRS
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
         board_i         => cards_board,
         valid_i         => cards_valid,
         done_i          => cards_done,
         step_o          => cards_step
      ); -- controller_inst

   cards_inst : entity work.cards
      generic map (
         G_PAIRS => G_PAIRS
      )
      port map (
         clk_i      => clk_i,
         rst_i      => rst_i,
         en_i       => cards_step,
         cards_o    => cards_board,
         cards_or_o => open,
         invalid_o  => open,
         valid_o    => cards_valid,
         done_o     => cards_done
      ); -- cards_inst

   cards_count_proc : process (clk_i)
   begin
      if rising_edge(clk_i) then
         if cards_step and cards_valid then
            cards_count <= cards_count + 1;
         end if;
         if rst_i then
            cards_count <= (others => '0');
         end if;
      end if;
   end process cards_count_proc;

   xpm_cdc_array_single_inst : component xpm_cdc_array_single
      generic map (
         WIDTH => 2 * G_PAIRS * G_PAIRS + 16
      )
      port map (
         src_clk  => clk_i,
         src_in   => cards_count & cards_board,
         dest_clk => vga_clk_i,
         dest_out => vga_count_board
      ); -- xpm_cdc_array_single_inst

   (vga_count, vga_board) <= vga_count_board;

   vga_wrapper_inst : entity work.vga_wrapper
      generic map (
         G_FONT_PATH => G_FONT_PATH,
         G_PAIRS     => G_PAIRS
      )
      port map (
         vga_clk_i    => vga_clk_i,
         vga_rst_i    => vga_rst_i,
         vga_hcount_i => vga_hcount_i,
         vga_vcount_i => vga_vcount_i,
         vga_blank_i  => vga_blank_i,
         vga_cards_i  => vga_board,
         vga_count_i  => vga_count,
         vga_rgb_o    => vga_rgb_o
      ); -- disp_cards_inst

end architecture synthesis;

