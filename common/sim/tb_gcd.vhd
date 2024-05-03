
library ieee;
   use ieee.std_logic_1164.all;
   use ieee.numeric_std_unsigned.all;

entity tb_gcd is
end entity tb_gcd;

architecture simulation of tb_gcd is

   constant C_SIZE  : integer   := 8;

   -- Clock, reset, and enable
   signal   running : std_logic := '1';
   signal   rst     : std_logic := '1';
   signal   clk     : std_logic := '1';
   signal   val1    : std_logic_vector(C_SIZE - 1 downto 0);
   signal   val2    : std_logic_vector(C_SIZE - 1 downto 0);
   signal   start   : std_logic;
   signal   res     : std_logic_vector(C_SIZE - 1 downto 0);
   signal   valid   : std_logic;

begin

   rst <= '1', '0' after 100 ns;
   clk <= running and not clk after 5 ns;

   gcd_inst : entity work.gcd
      generic map (
         G_SIZE => C_SIZE
      )
      port map (
         clk_i   => clk,
         rst_i   => rst,
         val1_i  => val1,
         val2_i  => val2,
         start_i => start,
         res_o   => res,
         valid_o => valid
      );

   test_proc : process
      --

      procedure verify_gcd (
         val1_v : integer;
         val2_v : integer;
         res_v  : integer
      ) is
      begin
         val1  <= to_stdlogicvector(val1_v, C_SIZE);
         val2  <= to_stdlogicvector(val2_v, C_SIZE);
         start <= '1';
         wait until clk = '1';
         start <= '0';

         while valid /= '1' loop
            wait until clk = '1';
         end loop;

         report "gcd(" & integer'image(val1_v)
                & "," & integer'image(val2_v)
                & ") -> " & integer'image(to_integer(res));
         assert res = to_stdlogicvector(res_v, C_SIZE);

         while valid = '1' loop
            wait until clk = '1';
         end loop;

      --
      end procedure verify_gcd;

   --
   begin
      start   <= '0';
      wait until rst = '0';
      wait for 100 ns;
      wait until clk = '1';

      verify_gcd(0, 0, 0);
      verify_gcd(1, 0, 0);
      verify_gcd(0, 1, 0);
      verify_gcd(1, 1, 1);
      verify_gcd(1, 2, 1);
      verify_gcd(1, 3, 1);
      verify_gcd(1, 4, 1);
      verify_gcd(2, 1, 1);
      verify_gcd(2, 2, 2);
      verify_gcd(2, 3, 1);
      verify_gcd(2, 4, 2);
      verify_gcd(3, 1, 1);
      verify_gcd(3, 2, 1);
      verify_gcd(3, 3, 3);
      verify_gcd(3, 4, 1);
      verify_gcd(4, 1, 1);
      verify_gcd(4, 2, 2);
      verify_gcd(4, 3, 1);
      verify_gcd(4, 4, 4);
      verify_gcd(30, 35, 5);
      verify_gcd(35, 30, 5);
      verify_gcd(36, 30, 6);
      verify_gcd(36, 32, 4);
      verify_gcd(37, 30, 1);
      verify_gcd(70, 30, 10);
      verify_gcd(150, 30, 30);
      verify_gcd(250, 30, 10);
      verify_gcd(253, 30, 1);
      verify_gcd(252, 30, 6);

      running <= '0';
      report "End of test";
      wait;
   end process test_proc;

end architecture simulation;

