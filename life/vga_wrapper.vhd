library ieee;
   use ieee.std_logic_1164.all;
   use ieee.numeric_std_unsigned.all;

library work;
   use work.video_modes_pkg.all;

entity vga_wrapper is
   generic (
      G_FONT_PATH : string := "";
      G_ROWS      : integer;
      G_COLS      : integer
   );
   port (
      vga_clk_i    : in    std_logic;
      vga_rst_i    : in    std_logic;
      vga_hcount_i : in    std_logic_vector(10 downto 0);
      vga_vcount_i : in    std_logic_vector(10 downto 0);
      vga_blank_i  : in    std_logic;
      vga_rgb_o    : out   std_logic_vector(7 downto 0);
      vga_board_i  : in    std_logic_vector(G_ROWS * G_COLS - 1 downto 0);
      vga_count_i  : in    std_logic_vector(15 downto 0)
   );
end entity vga_wrapper;


architecture synthesis of vga_wrapper is

   constant C_VIDEO_MODE : video_modes_type              := C_VIDEO_MODE_1280_720_60;
   constant C_FONT_FILE  : string                        := G_FONT_PATH & "font8x8.txt";

   -- Define colours
   constant C_PIXEL_DARK  : std_logic_vector(7 downto 0) := B"001_001_01";
   constant C_PIXEL_GREY  : std_logic_vector(7 downto 0) := B"010_010_01";
   constant C_PIXEL_LIGHT : std_logic_vector(7 downto 0) := B"100_100_10";

   constant C_START_X : std_logic_vector(7 downto 0)     := to_stdlogicvector(C_VIDEO_MODE.H_PIXELS / 64 - G_COLS / 2, 8);
   constant C_START_Y : std_logic_vector(7 downto 0)     := to_stdlogicvector(C_VIDEO_MODE.V_PIXELS / 64 - G_ROWS / 2, 8);

   signal   vga_x      : std_logic_vector(7 downto 0);
   signal   vga_y      : std_logic_vector(7 downto 0);
   signal   vga_char   : std_logic_vector(7 downto 0);
   signal   vga_colors : std_logic_vector(15 downto 0);

   signal   vga_dec_valid : std_logic;
   signal   vga_dec_ready : std_logic;
   signal   vga_dec_data  : std_logic_vector(3 downto 0);
   signal   vga_dec_last  : std_logic;
   signal   vga_dec_str   : std_logic_vector(39 downto 0);

begin

   char_proc : process (vga_clk_i)
      variable vga_index_v     : natural range 0 to G_ROWS * G_COLS - 1;
      variable vga_dec_index_v : natural range 0 to 4;
   begin
      if rising_edge(vga_clk_i) then
         vga_colors <= C_PIXEL_GREY & C_PIXEL_GREY;
         vga_char <= X"20";

         if vga_x >= C_START_X and vga_x < C_START_X + G_COLS and
            vga_y >= C_START_Y and vga_y < C_START_Y + G_ROWS then
            vga_index_v := to_integer((G_ROWS - 1 - (vga_y - C_START_Y)) * G_COLS + (G_COLS - 1 - (vga_x - C_START_X)));
            if vga_board_i(vga_index_v) = '1' then
               vga_char <= X"58";                                                                                        -- 'X'
            else
               vga_char <= X"2E";                                                                                        -- '.'
            end if;
            vga_colors <= C_PIXEL_DARK & C_PIXEL_LIGHT;
         end if;
         if vga_x >= C_START_X and vga_x < C_START_X + 5 and
            vga_y = C_START_Y + G_ROWS then
            vga_dec_index_v := to_integer(vga_x - C_START_X);
            vga_char        <= vga_dec_str(8 * vga_dec_index_v + 7 downto 8 * vga_dec_index_v);
            vga_colors      <= C_PIXEL_DARK & C_PIXEL_LIGHT;
         end if;
         if vga_x >= C_START_X + 5 and vga_x < C_START_X + G_COLS and
            vga_y = C_START_Y + G_ROWS then
            vga_colors <= C_PIXEL_DARK & C_PIXEL_LIGHT;
         end if;
      end if;
   end process char_proc;

   vga_chars_inst : entity work.vga_chars
      generic map (
         G_FONT_FILE  => C_FONT_FILE,
         G_VIDEO_MODE => C_VIDEO_MODE
      )
      port map (
         vga_clk_i    => vga_clk_i,
         vga_hcount_i => vga_hcount_i,
         vga_vcount_i => vga_vcount_i,
         vga_blank_i  => vga_blank_i,
         vga_rgb_o    => vga_rgb_o,
         vga_x_o      => vga_x,
         vga_y_o      => vga_y,
         vga_char_i   => vga_char,
         vga_colors_i => vga_colors
      ); -- vga_chars_inst

   slv_to_dec_inst : entity work.slv_to_dec
      generic map (
         G_DATA_SIZE => 16
      )
      port map (
         clk_i     => vga_clk_i,
         rst_i     => vga_rst_i,
         s_valid_i => '1',
         s_ready_o => open,
         s_data_i  => vga_count_i,
         m_valid_o => vga_dec_valid,
         m_ready_i => vga_dec_ready,
         m_data_o  => vga_dec_data,
         m_last_o  => vga_dec_last
      ); -- slv_to_dec_inst

   vga_dec_ready <= '1';

   vga_dec_proc : process (vga_clk_i)
      variable tmp_v : std_logic_vector(39 downto 0);
   begin
      if rising_edge(vga_clk_i) then
         if vga_dec_valid then
            tmp_v := "0011" & vga_dec_data & tmp_v(39 downto 8);
            if vga_dec_last then
               vga_dec_str <= tmp_v;
               tmp_v       := X"2020202020";
            end if;
         end if;
      end if;
   end process vga_dec_proc;

end architecture synthesis;

