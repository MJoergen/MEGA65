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
      vga_clk_o  : out   std_logic; -- 25 MHz
      vga_rst_o  : out   std_logic;
      clk_o      : out   std_logic; -- 100 MHz
      rst_o      : out   std_logic
   );
end entity clk;

architecture synthesis of clk is

   signal clk_mega65 : std_logic;
   signal clk_fb     : std_logic;
   signal locked     : std_logic;
   signal vga_clk    : std_logic;
   signal vga_clk_fb : std_logic;
   signal vga_locked : std_logic;

begin

   pll_inst : component plle2_base
      generic map (
         BANDWIDTH          => "OPTIMIZED",
         CLKFBOUT_MULT      => 12,   -- 1200 MHz
         CLKFBOUT_PHASE     => 0.000,
         CLKIN1_PERIOD      => 10.0, -- INPUT @ 100 MHz
         CLKOUT0_DIVIDE     => 10,   -- OUTPUT @ 120 MHz
         CLKOUT0_DUTY_CYCLE => 0.500,
         CLKOUT0_PHASE      => 0.000,
         CLKOUT1_DIVIDE     => 48,   -- OUTPUT @ 25 MHz
         CLKOUT1_DUTY_CYCLE => 0.500,
         CLKOUT1_PHASE      => 0.000,
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

   mmcm_vga_inst : component mmcme2_adv
      generic map (
         BANDWIDTH            => "OPTIMIZED",
         CLKOUT4_CASCADE      => FALSE,
         COMPENSATION         => "ZHOLD",
         STARTUP_WAIT         => FALSE,
         CLKIN1_PERIOD        => 10.0,   -- INPUT @ 100 MHz
         REF_JITTER1          => 0.010,
         DIVCLK_DIVIDE        => 4,
         CLKFBOUT_MULT_F      => 37.125,
         CLKFBOUT_PHASE       => 0.000,
         CLKFBOUT_USE_FINE_PS => FALSE,
         CLKOUT0_DIVIDE_F     => 12.500, -- 74.25 MHz
         CLKOUT0_PHASE        => 0.000,
         CLKOUT0_DUTY_CYCLE   => 0.500,
         CLKOUT0_USE_FINE_PS  => FALSE
      )
      port map (
         -- Output clocks
         clkfbout     => vga_clk_fb,
         clkout0      => vga_clk,
         -- Input clock control
         clkfbin      => vga_clk_fb,
         clkin1       => sys_clk_i,
         clkin2       => '0',
         -- Tied to always select the primary input clock
         clkinsel     => '1',
         -- Ports for dynamic reconfiguration
         daddr        => (others => '0'),
         dclk         => '0',
         den          => '0',
         di           => (others => '0'),
         do           => open,
         drdy         => open,
         dwe          => '0',
         -- Ports for dynamic phase shift
         psclk        => '0',
         psen         => '0',
         psincdec     => '0',
         psdone       => open,
         -- Other control and status signals
         locked       => vga_locked,
         clkinstopped => open,
         clkfbstopped => open,
         pwrdwn       => '0',
         rst          => '0'
      ); -- mmcm_vga_inst

   bufg_inst : component bufg
      port map (
         i => clk_mega65,
         o => clk_o
      ); -- bufg_inst

   bufg_vga_inst : component bufg
      port map (
         i => vga_clk,
         o => vga_clk_o
      ); -- bufg_vga_inst

   xpm_cdc_sync_rst_inst : component xpm_cdc_sync_rst
      generic map (
         INIT_SYNC_FF => 1
      )
      port map (
         src_rst  => not (sys_rstn_i and locked),
         dest_clk => clk_o,
         dest_rst => rst_o
      ); -- xpm_cdc_sync_rst_inst

   xpm_cdc_sync_rst_vga_inst : component xpm_cdc_sync_rst
      generic map (
         INIT_SYNC_FF => 1
      )
      port map (
         src_rst  => not (sys_rstn_i and vga_locked),
         dest_clk => vga_clk_o,
         dest_rst => vga_rst_o
      ); -- xpm_cdc_sync_rst_vga_inst

end architecture synthesis;

