----------------------------------------------------------------------------------
-- Company:  Granbo
-- Engineer: Michael Jørgensen
--
-- The file contains the top level test bench for the timer_demo
----------------------------------------------------------------------------------

library ieee;
   use ieee.std_logic_1164.all;
-- use IEEE.STD_LOGIC_ARITH.ALL;
-- use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity timer_demo_tb is
end entity timer_demo_tb;

architecture structural of timer_demo_tb is

   -- Clock
   signal clk     : std_logic; -- 50 MHz
   signal vga_clk : std_logic; -- 25 MHz

   -- LED, buttom, and switches
   signal led : std_logic_vector(7 downto 0);
   signal sw  : std_logic_vector(7 downto 0);

   -- VGA port
   signal vga_hs    : std_logic;
   signal vga_vs    : std_logic;
   signal vga_red   : std_logic_vector(2 downto 0);
   signal vga_green : std_logic_vector(2 downto 0);
   signal vga_blue  : std_logic_vector(2 downto 1);

begin

   -- Generate clock and reset
   clk_proc : process
   begin
      clk <= '1', '0' after 10 ns;
      wait for 20 ns;
   end process clk_proc;

   vga_clk_proc : process
   begin
      vga_clk <= '1', '0' after 20 ns;
      wait for 40 ns;
   end process vga_clk_proc;

   rst_proc : process
   begin
      sw(0) <= '1', '0' after 100 ns;
      wait;
   end process rst_proc;

   -- Instantiate DUT
   timer_demo_inst : entity work.timer_demo
      port map (
         clk_i       => clk,
         vga_clk_i   => vga_clk,
         sw_i        => sw,
         led_o       => led,
         vga_hs_o    => vga_hs,
         vga_vs_o    => vga_vs,
         vga_red_o   => vga_red,
         vga_green_o => vga_green,
         vga_blue_o  => vga_blue
      );

end architecture structural;

