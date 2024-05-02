------------------------------------------------------------------------
-- bitmap.vhd
------------------------------------------------------------------------
-- Behavioral description
------------------------------------------------------------------------
-- This file contains the implementation of a sprite animation
-- It receives a bitmap and a position, and modifies the VGA accordingly.
-- The bitmap is 16x16 pixels and uses 2 colours; white and black.
-- For the colurs encoding, 2 bits are used to be able to support transparency.
-- If the current pixel of the bitmap is "00" then output colour is black,
-- if "01" then white, and if "10" or "11" then the pixel is perfectly transparent
-- and the input colours are used.
-- If blank input from the vga_module is active, this means that current
-- pixel is not inside visible screen and color outputs are set to black
-- Memory address is composed from the difference of the vga counters
-- and bitmap position. xdiff is the difference on 4 bits (because cursor
-- is 16 pixels width) between the horizontal vga counter and the xpos
-- of the bitmap. ydiff is the difference on 4 bits (because cursor
-- has 16 pixels in height) between the vertical vga counter and the
-- ypos of the bitmap. By concatenating ydiff and xidff (in this order)
-- the memory address of the current pixel is obtained.
------------------------------------------------------------------------
-- Port definitions
------------------------------------------------------------------------
-- vga_clk_i      - The VGA clock signal (25 MHz for 640x480)
-- xpos_i         - input pin, 10 bits,
--                - the x position of the bitmap relative to the upper
--                - left corner
-- ypos_i         - input pin, 10 bits,
--                - the y position of the bitmap relative to the upper
--                - left corner
-- hcount_i       - input pin, 11 bits,
--                - the horizontal counter
--                - tells the horizontal position of the current pixel
--                - on the screen from left to right.
-- vcount_i       - input pin, 11 bits,
--                - the vertical counter
--                - tells the vertical position of the currentl pixel
--                - on the screen from top to bottom.
-- blank_i        - input pin,
--                - if active, current pixel is not in visible area,
--                - and color outputs should be set on 0.
-- bitmap_i       - input pin, 512 bits
--                - the image to be displayed at the indicated position.
-- vga_i          - input pin, 8 bits,
--                - the colour of the background view
-- vga_o          - output pin, 8 bits,
--                - the colour modified with the sprite.
------------------------------------------------------------------------

library ieee;
   use ieee.std_logic_1164.all;
   use ieee.numeric_std_unsigned.all;
   use work.bitmap_pkg.bitmap_type;

entity bitmap is
   port (
      vga_clk_i : in    std_logic;
      xpos_i    : in    std_logic_vector(9 downto 0);
      ypos_i    : in    std_logic_vector(9 downto 0);
      hcount_i  : in    std_logic_vector(10 downto 0);
      vcount_i  : in    std_logic_vector(10 downto 0);
      blank_i   : in    std_logic;
      bitmap_i  : in    bitmap_type;
      vga_i     : in    std_logic_vector(7 downto 0);
      vga_o     : out   std_logic_vector(7 downto 0)
   );
end entity bitmap;

architecture structural of bitmap is

   ------------------------------------------------------------------------
   -- CONSTANTS
   ------------------------------------------------------------------------

   -- width and height of cursor.
   constant C_OFFSET : std_logic_vector(4 downto 0)              := "10000";   -- 16

   ------------------------------------------------------------------------
   -- SIGNALS
   ------------------------------------------------------------------------

   -- pixel from the display memory, representing currently displayed
   -- pixel of the cursor, if the cursor is being display at this point
   signal   bitmap_pixel          : std_logic_vector(1 downto 0) := (others => '0');
   -- when high, enables displaying of the cursor, and reading the
   -- cursor memory.
   signal   enable_bitmap_display : std_logic                    := '0';

   -- difference in range 0-15 between the vga counters and bitmap position
   signal   xdiff : std_logic_vector(3 downto 0)                 := (others => '0');
   signal   ydiff : std_logic_vector(3 downto 0)                 := (others => '0');

begin

   -- compute xdiff
   x_diff_proc : process (vga_clk_i)
      variable temp_diff_v : std_logic_vector(10 downto 0) := (others => '0');
   begin
      if rising_edge(vga_clk_i) then
         temp_diff_v := hcount_i - ('0' & xpos_i);
         xdiff       <= temp_diff_v(3 downto 0);
      end if;
   end process x_diff_proc;

   -- compute ydiff
   y_diff_proc : process (vga_clk_i)
      variable temp_diff_v : std_logic_vector(10 downto 0) := (others => '0');
   begin
      if rising_edge(vga_clk_i) then
         temp_diff_v := vcount_i - ('0' & ypos_i);
         ydiff       <= temp_diff_v(3 downto 0);
      end if;
   end process y_diff_proc;

   -- read pixel from memory at address obtained by concatenation of
   -- ydiff and xdiff
   bitmap_pixel <= bitmap_i(to_integer(ydiff & xdiff))
                   when rising_edge(vga_clk_i);

   -- set enable_bitmap_display high if vga counters inside cursor block
   enable_bitmap_proc : process (vga_clk_i)
   begin
      if rising_edge(vga_clk_i) then
         if hcount_i >= xpos_i and hcount_i < (xpos_i + C_OFFSET) and
            vcount_i >= ypos_i and vcount_i < (ypos_i + C_OFFSET) then
            enable_bitmap_display <= '1';
         else
            enable_bitmap_display <= '0';
         end if;
      end if;
   end process enable_bitmap_proc;

   -- if cursor display is enabled, then, according to pixel
   -- value, set the output color channels.
   vga_proc : process (vga_clk_i)
   begin
      if rising_edge(vga_clk_i) then
         -- if in visible screen
         if blank_i = '0' then
            -- in display is enabled
            if enable_bitmap_display = '1' then
               -- white pixel of cursor
               if bitmap_pixel = "01" then
                  vga_o <= (others => '1');
               -- black pixel of cursor
               elsif bitmap_pixel = "00" then
                  vga_o <= (others => '0');
               -- transparent pixel of cursor
               -- let input pass to output
               else
                  vga_o <= vga_i;
               end if;
            -- cursor display is not enabled
            -- let input pass to output.
            else
               vga_o <= vga_i;
            end if;
         -- not in visible screen, black outputs.
         else
            vga_o <= (others => '0');
         end if;
      end if;
   end process vga_proc;

end architecture structural;

