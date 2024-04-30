--------------------------------------------------------------------------------
-- Company:       Granbo
-- Engineer:      Michael Jørgensen
--
-- Create Date:
-- Design Name:
-- Module Name:     disp_cardss
-- Project Name:
-- Target Device:
-- Tool versions:
-- Description:      Generates a background VGA image.
--
--------------------------------------------------------------------------------

library ieee;
   use ieee.std_logic_1164.all;
   use ieee.numeric_std_unsigned.all;
   use work.bitmap_pkg.all;

library work;
   use work.video_modes_pkg.all;


entity disp_cards is
   generic (
      G_VIDEO_MODE : video_modes_type;
      G_PAIRS      : integer
   );
   port (
      vga_clk_i    : in    std_logic; -- Currently not used

      vga_hcount_i : in    std_logic_vector(10 downto 0);
      vga_vcount_i : in    std_logic_vector(10 downto 0);
      vga_blank_i  : in    std_logic;
      vga_cards_i  : in    std_logic_vector(2 * G_PAIRS * G_PAIRS - 1 downto 0);

      vga_rgb_o    : out   std_logic_vector(7 downto 0)
   );
end entity disp_cards;

architecture behavioral of disp_cards is

   constant C_OFFSET_X : integer                    := G_VIDEO_MODE.H_PIXELS / 2 - G_PAIRS * 32;
   constant C_OFFSET_Y : integer                    := G_VIDEO_MODE.V_PIXELS / 2 - G_PAIRS * 16;

   constant C_SIZE : natural                        := 2 * G_PAIRS;

   type     bitmaps_vector_type is array(natural range <>) of bitmap_t;
   constant C_BITMAPS : bitmaps_vector_type(0 to 9) :=
   (
      bitmap_grey,
      bitmap_1,
      bitmap_2,
      bitmap_3,
      bitmap_4,
      bitmap_5,
      bitmap_6,
      bitmap_7,
      bitmap_8,
      bitmap_9
   );

   signal   hcount : integer;
   signal   vcount : integer;
   signal   col    : integer;
   signal   row    : integer;
   signal   xdiff  : integer range 0 to 15;
   signal   ydiff  : integer range 0 to 15;

begin

   hcount <= to_integer(vga_hcount_i);
   vcount <= to_integer(vga_vcount_i);
   col    <= (hcount - C_OFFSET_X) / 32;
   row    <= G_PAIRS - 1 - (vcount - C_OFFSET_Y) / 32;
   xdiff  <= (hcount - C_OFFSET_X - 32 * col) / 2;
   ydiff  <= (vcount - C_OFFSET_Y - 32 * row) / 2;

   vga_proc : process (all)
      variable bitmap_v : bitmap_t;
   begin
      bitmap_v  := bitmap_grey;
      vga_rgb_o <= (others => '0');

      if vga_blank_i = '0' then
         vga_rgb_o <= "10110110";
         if hcount >= C_OFFSET_X and hcount < C_OFFSET_X + 32 * C_SIZE
            and vcount >= C_OFFSET_Y and vcount < C_OFFSET_Y + 32 * G_PAIRS then
            if vga_cards_i(row * C_SIZE + C_SIZE - 1 - col) = '1' then
               bitmap_v := C_BITMAPS(row + 1);
            end if;

            case bitmap_v(ydiff * 16 + xdiff) is

               when "01" =>
                  vga_rgb_o <= "11011010";

               when "00" =>
                  vga_rgb_o <= "00100101";

               when others =>
                  vga_rgb_o <= "01010101";

            end case;

         end if;
      end if;
   end process vga_proc;

end architecture behavioral;

