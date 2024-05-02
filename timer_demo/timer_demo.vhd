library ieee;
   use ieee.std_logic_1164.all;
   use ieee.numeric_std_unsigned.all;
   use work.bitmap_pkg.all;

entity timer_demo is
   port (
      -- Clock
      clk_i       : in    std_logic; -- 50 MHz
      vga_clk_i   : in    std_logic; -- 25 MHz for VGA 640x480

      -- Input switches
      sw_i        : in    std_logic_vector(7 downto 0);

      -- Output LEDs
      led_o       : out   std_logic_vector(7 downto 0);

      -- VGA port
      vga_hs_o    : out   std_logic;
      vga_vs_o    : out   std_logic;
      vga_red_o   : out   std_logic_vector(2 downto 0);
      vga_green_o : out   std_logic_vector(2 downto 0);
      vga_blue_o  : out   std_logic_vector(2 downto 1)
   );
end entity timer_demo;

architecture structural of timer_demo is

   signal   hcount : std_logic_vector(10 downto 0);
   signal   vcount : std_logic_vector(10 downto 0);
   signal   blank  : std_logic;

   signal   vga_bg : std_logic_vector(7 downto 0);

   signal   bitmap_s1  : bitmap_t;
   signal   bitmap_s10 : bitmap_t;
   signal   bitmap_m1  : bitmap_t;
   signal   bitmap_m10 : bitmap_t;
   signal   bitmap_h1  : bitmap_t;
   signal   bitmap_h10 : bitmap_t;

   -- force synthesizer to extract distributed ram for the
   -- bitmaps, and not a block ram, because the block ram
   -- is entirely used to store the image.
   attribute rom_extract : string;
   attribute rom_style : string;
   attribute rom_extract of bitmap_s1  : signal is "yes";
   attribute rom_style of bitmap_s1    : signal is "distributed";
   attribute rom_extract of bitmap_s10 : signal is "yes";
   attribute rom_style of bitmap_s10   : signal is "distributed";
   attribute rom_extract of bitmap_m1  : signal is "yes";
   attribute rom_style of bitmap_m1    : signal is "distributed";
   attribute rom_extract of bitmap_m10 : signal is "yes";
   attribute rom_style of bitmap_m10   : signal is "distributed";
   attribute rom_extract of bitmap_h1  : signal is "yes";
   attribute rom_style of bitmap_h1    : signal is "distributed";
   attribute rom_extract of bitmap_h10 : signal is "yes";
   attribute rom_style of bitmap_h10   : signal is "distributed";

   signal   vga_s1  : std_logic_vector(7 downto 0);
   signal   vga_s10 : std_logic_vector(7 downto 0);
   signal   vga_m1  : std_logic_vector(7 downto 0);
   signal   vga_m10 : std_logic_vector(7 downto 0);
   signal   vga_h1  : std_logic_vector(7 downto 0);
   signal   vga_h10 : std_logic_vector(7 downto 0);

   signal   timer_h10 : std_logic_vector(3 downto 0);
   signal   timer_h1  : std_logic_vector(3 downto 0);
   signal   timer_m10 : std_logic_vector(3 downto 0);
   signal   timer_m1  : std_logic_vector(3 downto 0);
   signal   timer_s10 : std_logic_vector(3 downto 0);
   signal   timer_s1  : std_logic_vector(3 downto 0);

   subtype  DIGIT_TYPE is integer range 0 to 9;

   signal   digit_h10 : DIGIT_TYPE;
   signal   digit_h1  : DIGIT_TYPE;
   signal   digit_m10 : DIGIT_TYPE;
   signal   digit_m1  : DIGIT_TYPE;
   signal   digit_s10 : DIGIT_TYPE;
   signal   digit_s1  : DIGIT_TYPE;

   type     digits_vector_type is array(natural range <>) of bitmap_t;

   constant C_DIGITS : digits_vector_type(0 to 9) := (
                                                        bitmap_0, bitmap_1, bitmap_2, bitmap_3, bitmap_4,
                                                        bitmap_5, bitmap_6, bitmap_7, bitmap_8, bitmap_9);

begin

   led_o       <= timer_s10 & timer_s1;

   -- This generates the VGA timing signals
   vga_controller_640_60_inst : entity work.vga_controller_640_60
      port map (
         rst_i     => sw_i(0),
         vga_clk_i => vga_clk_i,
         hs_o      => vga_hs_o,
         vs_o      => vga_vs_o,
         hcount_o  => hcount,
         vcount_o  => vcount,
         blank_o   => blank
      );

   -- This generates the background image
   disp_background_inst : entity work.disp_background
      port map (
         vga_clk_i => vga_clk_i,
         hcount_i  => hcount,
         vcount_i  => vcount,
         blank_i   => blank,
         vga_o     => vga_bg
      );

   -- The generates the sprite for the unit's seconds.
   bitmap_s1_inst : entity work.bitmap
      port map (
         vga_clk_i => vga_clk_i,
         xpos_i    => "0011001100",
         ypos_i    => "0011001100",
         bitmap_i  => bitmap_s1,
         hcount_i  => hcount,
         vcount_i  => vcount,
         blank_i   => blank,
         vga_i     => vga_bg,
         vga_o     => vga_s1
      );

   -- The generates the sprite for the ten's seconds.
   bitmap_s10_inst : entity work.bitmap
      port map (
         vga_clk_i => vga_clk_i,
         xpos_i    => "0010101100",
         ypos_i    => "0011001100",
         bitmap_i  => bitmap_s10,
         hcount_i  => hcount,
         vcount_i  => vcount,
         blank_i   => blank,
         vga_i     => vga_s1,
         vga_o     => vga_s10
      );

   -- The generates the sprite for the unit's minutes.
   bitmap_m1_inst : entity work.bitmap
      port map (
         vga_clk_i => vga_clk_i,
         xpos_i    => "0010001100",
         ypos_i    => "0011001100",
         bitmap_i  => bitmap_m1,
         hcount_i  => hcount,
         vcount_i  => vcount,
         blank_i   => blank,
         vga_i     => vga_s10,
         vga_o     => vga_m1
      );

   -- The generates the sprite for the ten's minutes.
   bitmap_m10_inst : entity work.bitmap
      port map (
         vga_clk_i => vga_clk_i,
         xpos_i    => "0001101100",
         ypos_i    => "0011001100",
         bitmap_i  => bitmap_m10,
         hcount_i  => hcount,
         vcount_i  => vcount,
         blank_i   => blank,
         vga_i     => vga_m1,
         vga_o     => vga_m10
      );

   -- The generates the sprite for the unit's hours.
   bitmap_h1_inst : entity work.bitmap
      port map (
         vga_clk_i => vga_clk_i,
         xpos_i    => "0001001100",
         ypos_i    => "0011001100",
         bitmap_i  => bitmap_h1,
         hcount_i  => hcount,
         vcount_i  => vcount,
         blank_i   => blank,
         vga_i     => vga_m10,
         vga_o     => vga_h1
      );

   -- The generates the sprite for the ten's hours.
   bitmap_h10_inst : entity work.bitmap
      port map (
         vga_clk_i => vga_clk_i,
         xpos_i    => "0000101100",
         ypos_i    => "0011001100",
         bitmap_i  => bitmap_h10,
         hcount_i  => hcount,
         vcount_i  => vcount,
         blank_i   => blank,
         vga_i     => vga_h1,
         vga_o     => vga_h10
      );

   vga_red_o   <= vga_h10(7 downto 5);
   vga_green_o <= vga_h10(4 downto 2);
   vga_blue_o  <= vga_h10(1 downto 0);

   digit_s1    <= to_integer(timer_s1);
   digit_s10   <= to_integer(timer_s10);
   digit_m1    <= to_integer(timer_m1);
   digit_m10   <= to_integer(timer_m10);
   digit_h1    <= to_integer(timer_h1);
   digit_h10   <= to_integer(timer_h10);

   bitmap_s1   <= C_DIGITS(digit_s1);
   bitmap_s10  <= C_DIGITS(digit_s10);
   bitmap_m1   <= C_DIGITS(digit_m1);
   bitmap_m10  <= C_DIGITS(digit_m10);
   bitmap_h1   <= C_DIGITS(digit_h1);
   bitmap_h10  <= C_DIGITS(digit_h10);

   -- This generates the current time
   timer_inst : entity work.timer
      port map (
         clk_i       => clk_i,
         rst_i       => sw_i(0),
         timer_h10_o => timer_h10,
         timer_h1_o  => timer_h1,
         timer_m10_o => timer_m10,
         timer_m1_o  => timer_m1,
         timer_s10_o => timer_s10,
         timer_s1_o  => timer_s1
      );

end architecture structural;

