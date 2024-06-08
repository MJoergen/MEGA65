library ieee;
   use ieee.std_logic_1164.all;
   use ieee.numeric_std_unsigned.all;

-- This is a self-verifying testbench for the integer square root module.

entity tb_primes is
end entity tb_primes;

architecture simulation of tb_primes is

   constant C_ADDR_SIZE : integer    := 4;
   constant C_DATA_SIZE : integer    := 8;

   signal   test_running : std_logic := '1';
   signal   clk          : std_logic := '1';
   signal   rst          : std_logic := '1';

   -- Signals conected to DUT
   signal   dut_index : std_logic_vector(C_ADDR_SIZE - 1 downto 0);
   signal   dut_data  : std_logic_vector(C_DATA_SIZE - 1 downto 0);

begin

   clk <= test_running and not clk after 5 ns;
   rst <= '1', '0' after 100 ns;


   --------------------------------------------------
   -- Instantiate DUT
   --------------------------------------------------

   primes_inst : entity work.primes
      generic map (
         G_ADDR_SIZE => C_ADDR_SIZE,
         G_DATA_SIZE => C_DATA_SIZE
      )
      port map (
         clk_i   => clk,
         rst_i   => rst,
         index_i => dut_index,
         data_o  => dut_data
      ); -- primes_inst


   --------------------------------------------------
   -- Main test procedure starts here
   --------------------------------------------------

   main_test_proc : process

      procedure verify_prime (
         val : integer
      ) is
      begin
         for i in 2 to val-1 loop
            assert (val mod i) /= 0;
            if i*i > val then
               exit;
            end if;
         end loop;
      end procedure verify_prime;

   begin
      dut_index <= (others => '0');
      -- Wait until reset is complete
      wait until rst = '0';
      wait until clk = '1';

      -- Verify SQRT for a lot of small integers
      for i in 0 to 2**C_ADDR_SIZE-1 loop
         dut_index <= to_stdlogicvector(i, C_ADDR_SIZE);
         wait until clk = '1';
         verify_prime(to_integer(dut_data));
      end loop;

      wait for 20 ns;

      -- Stop test
      wait until clk = '1';
      report "Test completed";
      test_running <= '0';
      wait;
   end process main_test_proc;

end architecture simulation;

