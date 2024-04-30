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

library work;
   use work.video_modes_pkg.all;

entity disp_queens is
   generic (
      G_VIDEO_MODE : video_modes_type;
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

   constant C_OFFSET_X : integer := G_VIDEO_MODE.H_PIXELS/2 - G_NUM_QUEENS * 16;
   constant C_OFFSET_Y : integer := G_VIDEO_MODE.V_PIXELS/2 - G_NUM_QUEENS * 16;

   signal   hcount : integer;
   signal   vcount : integer;
   signal   col    : integer;
   signal   row    : integer;
   signal   xdiff  : integer range 0 to 15;
   signal   ydiff  : integer range 0 to 15;

begin

   hcount <= to_integer(vga_hcount_i);
   vcount <= to_integer(vga_vcount_i);
   col    <= G_NUM_QUEENS - 1 - (hcount - C_OFFSET_X) / 32;
   row    <= G_NUM_QUEENS - 1 - (vcount - C_OFFSET_Y) / 32;
   xdiff  <= ((hcount - C_OFFSET_X) rem 32) / 2;
   ydiff  <= ((vcount - C_OFFSET_Y) rem 32) / 2;

   vga_proc : process (all)
      variable bitmap_v : bitmap_t;
   begin
      bitmap_v  := bitmap_queen;
      vga_rgb_o <= (others => '0');

      if vga_blank_i = '0' then
         vga_rgb_o <= "10110110";
         if hcount >= C_OFFSET_X and hcount < C_OFFSET_X + 32 * G_NUM_QUEENS
            and vcount >= C_OFFSET_Y and vcount < C_OFFSET_Y + 32 * G_NUM_QUEENS then
            if (row rem 2) = (col rem 2) then
               vga_rgb_o <= "10110110";                                                        -- light grey
            else
               vga_rgb_o <= "01001001";                                                        -- dark grey
            end if;
            if vga_board_i(row * G_NUM_QUEENS + col) = '1' then

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

         if hcount >= C_OFFSET_X and hcount <= C_OFFSET_X + 32 * G_NUM_QUEENS
            and vcount >= C_OFFSET_Y and vcount <= C_OFFSET_Y + 32 * G_NUM_QUEENS then
            if (vcount - C_OFFSET_Y) rem 32 = 0 then
               vga_rgb_o <= "11111111";                                                        -- white
            end if;

            if (hcount - C_OFFSET_X) rem 32 = 0 then
               vga_rgb_o <= "11111111";                                                        -- white
            end if;
         end if;
      end if;
   end process vga_proc;

end architecture behavioral;

