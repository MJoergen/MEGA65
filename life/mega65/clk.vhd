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
      sys_clk_i  : in    std_logic; -- 100 MHz
      sys_rstn_i : in    std_logic;
      clk_o      : out   std_logic; -- 100 MHz
      rst_o      : out   std_logic
   );
end entity clk;

architecture synthesis of clk is

   signal clk_mega65 : std_logic;
   signal clk_fb     : std_logic;
   signal locked     : std_logic;

begin

   pll_inst : component plle2_base
      generic map (
         BANDWIDTH          => "OPTIMIZED",
         CLKFBOUT_MULT      => 12,   -- 1200 MHz
         CLKFBOUT_PHASE     => 0.000,
         CLKIN1_PERIOD      => 10.0, -- INPUT @ 100 MHz
         CLKOUT0_DIVIDE     => 12,   -- OUTPUT @ 100 MHz
         CLKOUT0_DUTY_CYCLE => 0.500,
         CLKOUT0_PHASE      => 0.000,
         DIVCLK_DIVIDE      => 1,
         REF_JITTER1        => 0.010,
         STARTUP_WAIT       => "FALSE"
      )
      port map (
         clkfbin  => clk_fb,
         clkfbout => clk_fb,
         clkin1   => sys_clk_i,
         clkout0  => clk_mega65,
         locked   => locked,
         pwrdwn   => '0',
         rst      => '0'
      ); -- pll_inst

   bufg_inst : component bufg
      port map (
         i => clk_mega65,
         o => clk_o
      ); -- bufg_inst

   xpm_cdc_sync_rst_inst : component xpm_cdc_sync_rst
      generic map (
         INIT_SYNC_FF => 1
      )
      port map (
         src_rst  => not (sys_rstn_i and locked),
         dest_clk => clk_o,
         dest_rst => rst_o
      ); -- xpm_cdc_sync_rst_inst

end architecture synthesis;

