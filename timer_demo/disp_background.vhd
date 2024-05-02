--------------------------------------------------------------------------------
-- Company:       Granbo
-- Engineer:      Michael Jørgensen
--
-- Create Date:
-- Design Name:
-- Module Name:     disp_background
-- Project Name:
-- Target Device:
-- Tool versions:
-- Description:      Generates a background VGA image.
--
--------------------------------------------------------------------------------

library ieee;
   use ieee.std_logic_1164.all;

entity disp_background is
   port (
      vga_clk_i : in    std_logic;                     -- Currently not used

      hcount_i  : in    std_logic_vector(10 downto 0); -- Currently not used
      vcount_i  : in    std_logic_vector(10 downto 0);
      blank_i   : in    std_logic;

      vga_o     : out   std_logic_vector(7 downto 0)
   );
end entity disp_background;

architecture behavioral of disp_background is

begin

   background_proc : process (all)
   begin
      vga_o <= (others => '0');

      if blank_i = '0' then -- in the active screen

         case vcount_i(7 downto 6) is

            when "00" =>
               vga_o <= vcount_i(5 downto 3) & "00000";

            when "01" =>
               vga_o <= "000" & vcount_i(5 downto 3) & "00";

            when "10" =>
               vga_o <= "000000" & vcount_i(5 downto 4);

            when others =>
               vga_o <= vcount_i(5 downto 3) & vcount_i(5 downto 3) & vcount_i(5 downto 4);

         end case;

      end if;
   end process background_proc;

end architecture behavioral;

