library ieee;
   use ieee.std_logic_1164.all;
   use ieee.numeric_std_unsigned.all;

library work;
   use work.video_modes_pkg.all;

-- Latency 3 clock cycles.

entity digits is
   generic (
      G_FONT_FILE  : string;
      G_ROWS       : integer;
      G_COLS       : integer;
      G_VIDEO_MODE : video_modes_type
   );
   port (
      vga_clk_i    : in    std_logic;
      vga_hcount_i : in    std_logic_vector(G_VIDEO_MODE.PIX_SIZE - 1 downto 0);
      vga_vcount_i : in    std_logic_vector(G_VIDEO_MODE.PIX_SIZE - 1 downto 0);
      vga_blank_i  : in    std_logic;
      vga_board_i  : in    std_logic_vector(G_ROWS * G_COLS - 1 downto 0);
      vga_rgb_o    : out   std_logic_vector(7 downto 0)
   );
   -- 'vga_rgb_o' is valid this many clock cycles after 'vga_board_i'.
   attribute latency : positive;
   attribute latency of digits : entity is 3;
end entity digits;

architecture synthesis of digits is

   -- Define positioning of text on screen
   constant C_TEXT_CHAR_X : integer                      := G_VIDEO_MODE.H_PIXELS / 64 - G_COLS / 2;
   constant C_TEXT_CHAR_Y : integer                      := G_VIDEO_MODE.V_PIXELS / 64 - G_ROWS / 2;

   -- A single character bitmap is defined by 8x8 = 64 bits.
   subtype  BITMAP_TYPE is std_logic_vector(63 downto 0);

   -- Define colours
   constant C_PIXEL_BLACK : std_logic_vector(7 downto 0) := B"000_000_00";
   constant C_PIXEL_DARK  : std_logic_vector(7 downto 0) := B"001_001_01";
   constant C_PIXEL_GREY  : std_logic_vector(7 downto 0) := B"010_010_01";
   constant C_PIXEL_LIGHT : std_logic_vector(7 downto 0) := B"100_100_10";
   constant C_PIXEL_WHITE : std_logic_vector(7 downto 0) := B"111_111_11";

   -- Stage 0
   signal   black_0    : std_logic;
   signal   char_col_0 : integer range 0 to G_VIDEO_MODE.H_MAX / 16 - 1;
   signal   char_row_0 : integer range 0 to G_VIDEO_MODE.V_MAX / 16 - 1;
   signal   pix_col_0  : integer range 0 to 7;
   signal   pix_row_0  : integer range 0 to 7;
   signal   index_0    : integer;

   -- Stage 1
   signal   black_1       : std_logic;
   signal   char_col_1    : integer range 0 to G_VIDEO_MODE.H_MAX / 16 - 1;
   signal   char_row_1    : integer range 0 to G_VIDEO_MODE.V_MAX / 16 - 1;
   signal   pix_col_1     : integer range 0 to 7;
   signal   pix_row_1     : integer range 0 to 7;
   signal   nibble_1      : std_logic_vector(3 downto 0);
   signal   char_nibble_1 : std_logic_vector(7 downto 0);
   signal   char_txt_1    : std_logic_vector(7 downto 0);
   signal   char_1        : std_logic_vector(7 downto 0);

   -- Stage 2
   signal   black_2        : std_logic;
   signal   bitmap_2       : BITMAP_TYPE;
   signal   char_col_2     : integer range 0 to G_VIDEO_MODE.H_MAX / 16 - 1;
   signal   char_row_2     : integer range 0 to G_VIDEO_MODE.V_MAX / 16 - 1;
   signal   pix_col_2      : integer range 0 to 7;
   signal   pix_row_2      : integer range 0 to 7;
   signal   bitmap_index_2 : integer range 0 to 63;
   signal   pix_2          : std_logic;

   -- Stage 3
   signal   pixel_3 : std_logic_vector(7 downto 0);

begin

   --------------------------------------------------
   -- Stage 0
   --------------------------------------------------

   -- Calculate character coordinates, within 40x30
   black_0    <= '1' when vga_hcount_i >= G_VIDEO_MODE.H_PIXELS or vga_vcount_i >= G_VIDEO_MODE.V_PIXELS else
                 '0';
   char_col_0 <= to_integer(vga_hcount_i(10 downto 5));
   char_row_0 <= to_integer(vga_vcount_i(10 downto 5));
   pix_col_0  <= to_integer(vga_hcount_i(4 downto 2));
   pix_row_0  <= 7 - to_integer(vga_vcount_i(4 downto 2));

   index_0    <= (char_row_0 - C_TEXT_CHAR_Y) * G_COLS + (char_col_0 - C_TEXT_CHAR_X);


   --------------------------------------------------
   -- Stage 1
   --------------------------------------------------

   stage1_proc : process (vga_clk_i)
   begin
      if rising_edge(vga_clk_i) then
         if vga_board_i(G_ROWS * G_COLS - 1 - index_0) = '1' then
            char_txt_1 <= X"58";
         else
            char_txt_1 <= X"2E";
         end if;
         black_1    <= black_0;
         char_col_1 <= char_col_0;
         char_row_1 <= char_row_0;
         pix_col_1  <= pix_col_0;
         pix_row_1  <= pix_row_0;
      end if;
   end process stage1_proc;

   -- Calculate character to display at current position
   char_1     <= char_txt_1 when char_row_1 >= C_TEXT_CHAR_Y   and char_row_1 < C_TEXT_CHAR_Y + G_ROWS and
                                 char_col_1 >= C_TEXT_CHAR_X   and char_col_1 < C_TEXT_CHAR_X + G_COLS else
                 X"20"; -- Fill the rest of the screen with spaces.


   --------------------------------------------------
   -- Stage 2
   --------------------------------------------------

   -- Calculate bitmap (64 bits) of digit at current position
   font_inst : entity work.font
      generic map (
         G_FONT_FILE => G_FONT_FILE
      )
      port map (
         clk_i    => vga_clk_i,
         char_i   => char_1,
         bitmap_o => bitmap_2
      ); -- font_inst

   stage2_proc : process (vga_clk_i)
   begin
      if rising_edge(vga_clk_i) then
         black_2    <= black_1;
         char_col_2 <= char_col_1;
         char_row_2 <= char_row_1;
         pix_col_2  <= pix_col_1;
         pix_row_2  <= pix_row_1;
      end if;
   end process stage2_proc;

   -- Calculate pixel at current position ('0' or '1')
   bitmap_index_2 <= pix_row_2 * 8 + pix_col_2;
   pix_2          <= bitmap_2(bitmap_index_2);


   --------------------------------------------------
   -- Stage 3
   --------------------------------------------------

   -- Generate pixel colour
   stage3_proc : process (vga_clk_i)
   begin
      if rising_edge(vga_clk_i) then
         -- Set the default screen background colour
         pixel_3 <= C_PIXEL_GREY;

         -- Are we within the borders of the text?
         if char_row_2 >= C_TEXT_CHAR_Y and char_row_2 < C_TEXT_CHAR_Y + G_ROWS and
            char_col_2 >= C_TEXT_CHAR_X and char_col_2 < C_TEXT_CHAR_X + G_COLS then
            if pix_2 = '1' then
               pixel_3 <= C_PIXEL_LIGHT;                                             -- Text foreground colour.
            else
               pixel_3 <= C_PIXEL_DARK;                                              -- Text background colour.
            end if;
         end if;

         -- Make sure colour is black outside visible screen
         if black_2 = '1' then
            pixel_3 <= C_PIXEL_BLACK;
         end if;
      end if;
   end process stage3_proc;

   vga_rgb_o      <= pixel_3;

end architecture synthesis;

