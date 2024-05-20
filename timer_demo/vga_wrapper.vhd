library ieee;
   use ieee.std_logic_1164.all;
   use ieee.numeric_std_unsigned.all;

library work;
   use work.video_modes_pkg.all;

entity vga_wrapper is
   generic (
      G_FONT_PATH  : string := ""
   );
   port (
      vga_clk_i       : in    std_logic;
      vga_rst_i       : in    std_logic;
      vga_hcount_i    : in    std_logic_vector(10 downto 0);
      vga_vcount_i    : in    std_logic_vector(10 downto 0);
      vga_blank_i     : in    std_logic;
      vga_timer_h10_i : in    std_logic_vector(3 downto 0);
      vga_timer_h1_i  : in    std_logic_vector(3 downto 0);
      vga_timer_m10_i : in    std_logic_vector(3 downto 0);
      vga_timer_m1_i  : in    std_logic_vector(3 downto 0);
      vga_timer_s10_i : in    std_logic_vector(3 downto 0);
      vga_timer_s1_i  : in    std_logic_vector(3 downto 0);
      vga_rgb_o       : out   std_logic_vector(7 downto 0)
   );
end entity vga_wrapper;


architecture synthesis of vga_wrapper is

   constant C_VIDEO_MODE : video_modes_type              := C_VIDEO_MODE_1280_720_60;
   constant C_FONT_FILE  : string                        := G_FONT_PATH & "font8x8.txt";

   -- Define colours
   constant C_PIXEL_DARK  : std_logic_vector(7 downto 0) := B"001_001_01";
   constant C_PIXEL_GREY  : std_logic_vector(7 downto 0) := B"010_010_01";
   constant C_PIXEL_LIGHT : std_logic_vector(7 downto 0) := B"100_100_10";

   constant C_START_X : std_logic_vector(7 downto 0)     := to_stdlogicvector(C_VIDEO_MODE.H_PIXELS / 64 - 4, 8);
   constant C_START_Y : std_logic_vector(7 downto 0)     := to_stdlogicvector(C_VIDEO_MODE.V_PIXELS / 64, 8);

   signal   vga_x      : std_logic_vector(7 downto 0);
   signal   vga_y      : std_logic_vector(7 downto 0);
   signal   vga_char   : std_logic_vector(7 downto 0);
   signal   vga_colors : std_logic_vector(15 downto 0);

begin

   char_proc : process (vga_clk_i)
      variable vga_index_v     : natural range 0 to 7;
   begin
      if rising_edge(vga_clk_i) then
         vga_colors <= "10110110" & "10110110";
         vga_char   <= X"20";

         if vga_x >= C_START_X and vga_x < C_START_X + 8 and
            vga_y = C_START_Y then
            vga_index_v := to_integer(vga_x - C_START_X);
            case vga_index_v is
               when 0 => vga_char <= "0011" & vga_timer_h10_i;
               when 1 => vga_char <= "0011" & vga_timer_h1_i;
               when 2 => vga_char <= X"3A";
               when 3 => vga_char <= "0011" & vga_timer_m10_i;
               when 4 => vga_char <= "0011" & vga_timer_m1_i;
               when 5 => vga_char <= X"3A";
               when 6 => vga_char <= "0011" & vga_timer_s10_i;
               when 7 => vga_char <= "0011" & vga_timer_s1_i;
            end case;
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

end architecture synthesis;

