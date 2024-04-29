--------------------------------------------------------------------------------
-- Company:       Granbo
-- Engineer:      Michael Jørgensen
--
-- Create Date:
-- Design Name:
-- Module Name:     disp_queens
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

entity disp_queens is
   generic (
      G_NUM_QUEENS : integer
   );
   port (
      vga_clk_i    : in    std_logic; -- Currently not used

      vga_hcount_i : in    std_logic_vector(10 downto 0);
      vga_vcount_i : in    std_logic_vector(10 downto 0);
      vga_blank_i  : in    std_logic;
      vga_board_i  : in    std_logic_vector(G_NUM_QUEENS * G_NUM_QUEENS - 1 downto 0);

      vga_rgb_o    : out   std_logic_vector(7 downto 0)
   );
end entity disp_queens;

architecture behavioral of disp_queens is

   constant C_OFFSET_X : integer := 50;
   constant C_OFFSET_Y : integer := 150;

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
      vga_rgb_o <= (others => '0');

      if vga_blank_i = '0' then                                                                -- in the active screen
         if hcount_v >= C_OFFSET_X and hcount_v < C_OFFSET_X + 16 * G_NUM_QUEENS
            and vcount_v >= C_OFFSET_Y and vcount_v < C_OFFSET_Y + 16 * G_NUM_QUEENS then
            row_v   := G_NUM_QUEENS - 1 - (vcount_v - C_OFFSET_Y) / 16;
            col_v   := G_NUM_QUEENS - 1 - (hcount_v - C_OFFSET_X) / 16;
            xdiff_v := (hcount_v - C_OFFSET_X) rem 16;
            ydiff_v := (vcount_v - C_OFFSET_Y) rem 16;
            if (row_v rem 2) = (col_v rem 2) then
               vga_rgb_o <= "10110110";                                                        -- light grey
            else
               vga_rgb_o <= "01001001";                                                        -- dark grey
            end if;
            if vga_board_i(row_v * G_NUM_QUEENS + col_v) = '1' then

               case bitmap_queen(ydiff_v * 16 + xdiff_v) is

                  when "01" =>
                     vga_rgb_o <= "11011010";

                  when "00" =>
                     vga_rgb_o <= "00100101";

                  when others =>
                     null;

               end case;

            end if;
         end if;

         if hcount_v >= C_OFFSET_X and hcount_v <= C_OFFSET_X + 16 * G_NUM_QUEENS
            and vcount_v >= C_OFFSET_Y and vcount_v <= C_OFFSET_Y + 16 * G_NUM_QUEENS then
            if (vcount_v - C_OFFSET_Y) rem 16 = 0 then
               vga_rgb_o <= "11111111";                                                        -- white
            end if;

            if (hcount_v - C_OFFSET_X) rem 16 = 0 then
               vga_rgb_o <= "11111111";                                                        -- white
            end if;
         end if;
      end if;
   end process vga_proc;

end architecture behavioral;

