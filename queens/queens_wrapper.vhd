library ieee;
   use ieee.std_logic_1164.all;
   use ieee.numeric_std_unsigned.all;

library xpm;
   use xpm.vcomponents.all;

entity queens_wrapper is
   generic (
      G_NUM_QUEENS : integer := 8
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
end entity queens_wrapper;

architecture synthesis of queens_wrapper is

   signal queens_board : std_logic_vector(G_NUM_QUEENS * G_NUM_QUEENS - 1 downto 0);
   signal queens_valid : std_logic;
   signal queens_done  : std_logic;

   signal vga_board : std_logic_vector(G_NUM_QUEENS * G_NUM_QUEENS - 1 downto 0);

begin

   uart_rx_ready_o <= '1';
   uart_tx_valid_o <= '0';
   uart_tx_data_o  <= (others => '0');

   queens_inst : entity work.queens
      generic map (
         G_NUM_QUEENS => G_NUM_QUEENS
      )
      port map (
         clk_i   => clk_i,
         rst_i   => rst_i,
         en_i    => '1',
         board_o => queens_board,
         valid_o => queens_valid,
         done_o  => queens_done
      ); -- queens_inst

   xpm_cdc_array_single_inst : component xpm_cdc_array_single
      generic map (
         WIDTH => G_NUM_QUEENS * G_NUM_QUEENS
      )
      port map (
         src_clk  => clk_i,
         src_in   => queens_board,
         dest_clk => vga_clk_i,
         dest_out => vga_board
      ); -- xpm_cdc_array_single_inst


   -- This generates the image
   disp_queens_inst : entity work.disp_queens
      generic map (
         G_NUM_QUEENS => G_NUM_QUEENS
      )
      port map (
         vga_clk_i    => vga_clk_i,
         vga_hcount_i => vga_hcount_i,
         vga_vcount_i => vga_vcount_i,
         vga_blank_i  => vga_blank_i,
         vga_board_i  => vga_board,
         vga_rgb_o    => vga_rgb_o
      ); -- disp_queens_inst

end architecture synthesis;

