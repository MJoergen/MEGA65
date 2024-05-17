library ieee;
   use ieee.std_logic_1164.all;
   use ieee.numeric_std_unsigned.all;

library xpm;
   use xpm.vcomponents.all;

library unisim;
   use unisim.vcomponents.all;

entity steiner_clk is
   port (
      clk_i      : in    std_logic;
      rst_i      : in    std_logic;

      core_clk_o : out   std_logic;
      core_rst_o : out   std_logic
   );
end entity steiner_clk;

architecture synthesis of steiner_clk is

   signal pll_fb       : std_logic;
   signal pll_locked   : std_logic;
   signal pll_core_clk : std_logic;

begin

   plle2_base_inst : component plle2_base
      generic map (
         BANDWIDTH          => "OPTIMIZED",
         CLKFBOUT_MULT      => 12,   -- 1200 MHz
         CLKFBOUT_PHASE     => 0.000,
         CLKIN1_PERIOD      => 10.0, -- INPUT @ 100 MHz
         CLKOUT0_DIVIDE     => 12,   -- CORE @ 100 MHz
         CLKOUT0_DUTY_CYCLE => 0.500,
         CLKOUT0_PHASE      => 0.000,
         DIVCLK_DIVIDE      => 1,
         REF_JITTER1        => 0.010,
         STARTUP_WAIT       => "FALSE"
      )
      port map (
         clkfbin  => pll_fb,
         clkfbout => pll_fb,
         clkin1   => clk_i,
         clkout0  => pll_core_clk,
         locked   => pll_locked,
         pwrdwn   => '0',
         rst      => '0'
      ); -- plle2_base_inst

   bufg_inst : component bufg
      port map (
         i => pll_core_clk,
         o => core_clk_o
      ); -- bufg_inst

   xpm_cdc_async_rst_inst : component xpm_cdc_async_rst
      generic map (
         RST_ACTIVE_HIGH => 1
      )
      port map (
         src_arst  => rst_i or not pll_locked,
         dest_clk  => core_clk_o,
         dest_arst => core_rst_o
      ); -- xpm_cdc_async_rst_inst

end architecture synthesis;

