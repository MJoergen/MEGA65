----------------------------------------------------------------------------------
-- Company:  Granbo
-- Engineer: Michael Jørgensen
--
-- The file contains the top level test bench for the life demo.
----------------------------------------------------------------------------------

library ieee;
   use ieee.std_logic_1164.all;
   use ieee.numeric_std_unsigned.all;

entity tb_timer is
end entity tb_timer;

architecture simulation of tb_timer is

   -- Clock, reset, and enable
   signal running : std_logic := '1';
   signal rst     : std_logic := '1';
   signal clk     : std_logic := '1';
   signal en      : std_logic := '1';

   signal timer_h10 : std_logic_vector(3 downto 0);
   signal timer_h1  : std_logic_vector(3 downto 0);
   signal timer_m10 : std_logic_vector(3 downto 0);
   signal timer_m1  : std_logic_vector(3 downto 0);
   signal timer_s10 : std_logic_vector(3 downto 0);
   signal timer_s1  : std_logic_vector(3 downto 0);

   signal timer_all : std_logic_vector(23 downto 0);

begin

   rst <= '1', '0' after 97 ns;
   clk <= running and not clk after 5 ns;
   en  <= '1';

   timer_inst : entity work.timer
      port map (
         clk_i       => clk,
         rst_i       => rst,
         step_i      => en,
         timer_h10_o => timer_h10,
         timer_h1_o  => timer_h1,
         timer_m10_o => timer_m10,
         timer_m1_o  => timer_m1,
         timer_s10_o => timer_s10,
         timer_s1_o  => timer_s1
      ); -- timer_inst

   timer_all <= timer_h10 & timer_h1 & timer_m10 & timer_m1 & timer_s10 & timer_s1;

   test_proc : process
   begin
      wait until rst = '0';
      wait until clk = '1';

      assert timer_all = X"000000";
      wait until clk = '1';
      assert timer_all = X"000001";
      wait until clk = '1';
      assert timer_all = X"000002";
      for i in 1 to 7 loop
         wait until clk = '1';
      end loop;
      assert timer_all = X"000009";
      wait until clk = '1';
      assert timer_all = X"000010";

      running <= '0';
      report "Test finished";
   end process test_proc;

end architecture simulation;

