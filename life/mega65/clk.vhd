library ieee;
   use ieee.std_logic_1164.all;
   use ieee.numeric_std_unsigned.all;

library unisim;
use unisim.vcomponents.all;

library xpm;
use xpm.vcomponents.all;

entity clk is
   port (
      -- Clock
      clk_i : in    std_logic; -- 100 MHz
      rst_i : in    std_logic;
      clk_o : out   std_logic; -- 100 MHz
      rst_o : out   std_logic
   );
end entity clk;

architecture synthesis of clk is

   signal clk_mega65    : std_logic;
   signal clk_fb : std_logic;
   signal locked : std_logic;

begin

   pll_inst : component PLLE2_BASE
      generic map (
         BANDWIDTH            => "OPTIMIZED",
         CLKFBOUT_MULT        => 12,         -- 1200 MHz
         CLKFBOUT_PHASE       => 0.000,
         CLKIN1_PERIOD        => 10.0,       -- INPUT @ 100 MHz
         CLKOUT0_DIVIDE       => 12,         -- OUTPUT @ 100 MHz
         CLKOUT0_DUTY_CYCLE   => 0.500,
         CLKOUT0_PHASE        => 0.000,
         DIVCLK_DIVIDE        => 1,
         REF_JITTER1          => 0.010,
         STARTUP_WAIT         => "FALSE"
      )
      port map (
         CLKFBIN             => clk_fb,
         CLKFBOUT            => clk_fb,
         CLKIN1              => clk_i,
         CLKOUT0             => clk_mega65,
         LOCKED              => locked,
         PWRDWN              => '0',
         RST                 => rst_i
      ); -- pll_inst

   clk_bufg : component BUFG
      port map (
         I => clk_mega65,
         O => clk_o
      );

   xpm_cdc_async_rst_inst : component xpm_cdc_async_rst
      generic map (
         RST_ACTIVE_HIGH => 1,
         DEST_SYNC_FF    => 6
      )
      port map (
         src_arst  => not locked,
         dest_clk  => clk_o,
         dest_arst => rst_o
      );

end architecture synthesis;

