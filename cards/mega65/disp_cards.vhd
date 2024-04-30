--------------------------------------------------------------------------------
-- Company:       Granbo
-- Engineer:      Michael Jørgensen
--
-- Create Date:
-- Design Name:
-- Module Name:     disp_cells
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

entity disp_cards is
   generic (
      G_PAIRS : integer
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

   constant C_OFFSET_X : integer                    := 50;
   constant C_OFFSET_Y : integer                    := 150;

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

begin

   vga_proc : process (all)
      variable hcount_v : integer;
      variable vcount_v : integer;
      variable col_v    : integer;
      variable row_v    : integer;
      variable xdiff_v  : integer range 0 to 15;
      variable ydiff_v  : integer range 0 to 15;
      variable bitmap_v : bitmap_t;
   begin
      hcount_v  := to_integer(vga_hcount_i);
      vcount_v  := to_integer(vga_vcount_i);
      col_v     := 0;
      row_v     := 0;
      xdiff_v   := 0;
      ydiff_v   := 0;
      bitmap_v  := bitmap_grey;
      vga_rgb_o <= (others => '0');

      if vga_blank_i = '0' then
         vga_rgb_o <= "10110110";
         if (hcount_v >= C_OFFSET_X) and (hcount_v < C_OFFSET_X + 16 * 2 * G_PAIRS)
            and (vcount_v >= C_OFFSET_Y) and (vcount_v < C_OFFSET_Y + 16 * G_PAIRS) then
            col_v   := (hcount_v - C_OFFSET_X) / 16;
            row_v   := G_PAIRS - 1 - (vcount_v - C_OFFSET_Y) / 16;
            xdiff_v := hcount_v - C_OFFSET_X - 16 * col_v;
            ydiff_v := vcount_v - C_OFFSET_Y - 16 * row_v;

            if vga_cards_i(row_v * 2 * G_PAIRS + (2 * G_PAIRS - 1 - col_v)) = '1' then
               bitmap_v := C_BITMAPS(row_v + 1);
            end if;

            case bitmap_v(ydiff_v * 16 + xdiff_v) is

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

