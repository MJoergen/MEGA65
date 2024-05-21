library ieee;
   use ieee.std_logic_1164.all;
   use ieee.numeric_std_unsigned.all;

library xpm;
   use xpm.vcomponents.all;

library work;
   use work.video_modes_pkg.all;

entity queens_wrapper is
   generic (
      G_FONT_PATH  : string := "";
      G_NUM_QUEENS : integer
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
end entity queens_wrapper;

architecture synthesis of queens_wrapper is

   constant C_VIDEO_MODE : video_modes_type := C_VIDEO_MODE_1280_720_60;

   signal   queens_step  : std_logic;
   signal   queens_board : std_logic_vector(G_NUM_QUEENS * G_NUM_QUEENS - 1 downto 0);
   signal   queens_count : std_logic_vector(15 downto 0);
   signal   queens_valid : std_logic;
   signal   queens_ready : std_logic;
   signal   queens_done  : std_logic;

   signal   vga_count       : std_logic_vector(15 downto 0);
   signal   vga_board       : std_logic_vector(G_NUM_QUEENS * G_NUM_QUEENS - 1 downto 0);
   signal   vga_count_board : std_logic_vector(G_NUM_QUEENS * G_NUM_QUEENS + 15  downto 0);

begin

   queens_inst : entity work.queens
      generic map (
         G_NUM_QUEENS => G_NUM_QUEENS
      )
      port map (
         clk_i   => clk_i,
         rst_i   => rst_i,
         en_i    => queens_step and queens_ready,
         board_o => queens_board,
         valid_o => queens_valid,
         done_o  => queens_done
      ); -- queens_inst

   queens_count_proc : process (clk_i)
   begin
      if rising_edge(clk_i) then
         if queens_step and queens_valid then
            queens_count <= queens_count + 1;
         end if;
         if rst_i then
            queens_count <= (others => '0');
         end if;
      end if;
   end process queens_count_proc;


   -- UART Interface
   uart_wrapper_inst : entity work.uart_wrapper
      generic map (
         G_NUM_QUEENS => G_NUM_QUEENS
      )
      port map (
         clk_i           => clk_i,
         rst_i           => rst_i,
         uart_rx_valid_i => '0',
         uart_rx_ready_o => open,
         uart_rx_data_i  => (others => '0'),
         uart_tx_valid_o => uart_tx_valid_o,
         uart_tx_ready_i => uart_tx_ready_i,
         uart_tx_data_o  => uart_tx_data_o,
         valid_i         => queens_valid,
         ready_o         => queens_ready,
         result_i        => queens_board,
         done_i          => queens_done
      ); -- uart_wrapper_inst

   -- User Interface
   controller_inst : entity work.controller
      port map (
         clk_i      => clk_i,
         rst_i      => rst_i,
         rx_valid_i => uart_rx_valid_i,
         rx_ready_o => uart_rx_ready_o,
         rx_data_i  => uart_rx_data_i,
         valid_i    => queens_valid,
         step_o     => queens_step
      ); -- controller_inst

   xpm_cdc_array_single_inst : component xpm_cdc_array_single
      generic map (
         WIDTH => G_NUM_QUEENS * G_NUM_QUEENS + 16
      )
      port map (
         src_clk  => clk_i,
         src_in   => queens_count & queens_board,
         dest_clk => vga_clk_i,
         dest_out => vga_count_board
      ); -- xpm_cdc_array_single_inst

   (vga_count, vga_board) <= vga_count_board;

   vga_wrapper_inst : entity work.vga_wrapper
      generic map (
         G_FONT_PATH  => G_FONT_PATH,
         G_NUM_QUEENS => G_NUM_QUEENS
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

