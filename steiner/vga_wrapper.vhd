library ieee;
   use ieee.std_logic_1164.all;
   use ieee.numeric_std_unsigned.all;

library work;
   use work.video_modes_pkg.all;

entity vga_wrapper is
   generic (
      G_FONT_PATH : string := "";
      G_N         : natural;
      G_K         : natural;
      G_T         : natural;
      G_B         : natural
   );
   port (
      vga_clk_i    : in    std_logic;
      vga_hcount_i : in    std_logic_vector(10 downto 0);
      vga_vcount_i : in    std_logic_vector(10 downto 0);
      vga_blank_i  : in    std_logic;
      vga_rgb_o    : out   std_logic_vector(7 downto 0);
      vga_result_i : in    std_logic_vector(G_N * G_B - 1 downto 0)
   );
end entity vga_wrapper;


architecture synthesis of vga_wrapper is

   constant C_VIDEO_MODE : video_modes_type          := C_VIDEO_MODE_1280_720_60;
   constant C_FONT_FILE  : string                    := G_FONT_PATH & "font8x8.txt";

   constant C_START_X : std_logic_vector(7 downto 0) := to_stdlogicvector(1280 / 64 - G_N / 2, 8);
   constant C_START_Y : std_logic_vector(7 downto 0) := to_stdlogicvector(720 / 64 - G_B / 2, 8);

   signal   vga_x    : std_logic_vector(7 downto 0);
   signal   vga_y    : std_logic_vector(7 downto 0);
   signal   vga_char : std_logic_vector(7 downto 0);

begin


   char_proc : process (vga_clk_i)
      variable vga_index_v : natural range 0 to G_N * G_B - 1;
   begin
      if rising_edge(vga_clk_i) then
         vga_char <= X"20";

         if vga_x >= C_START_X and vga_x < C_START_X + G_N and
            vga_y >= C_START_Y and vga_y < C_START_Y + G_B then
            vga_index_v := to_integer((vga_y - C_START_Y) * G_N + (G_N - 1 - (vga_x - C_START_X)));
            if vga_result_i(vga_index_v) = '1' then
               vga_char <= X"58";                                                                   -- 'X'
            else
               vga_char <= X"2E";                                                                   -- '.'
            end if;
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
         vga_char_i   => vga_char
      ); -- vga_chars_inst

end architecture synthesis;

