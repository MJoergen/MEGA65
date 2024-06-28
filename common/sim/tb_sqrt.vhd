library ieee;
   use ieee.std_logic_1164.all;
   use ieee.numeric_std_unsigned.all;

-- This is a self-verifying testbench for the integer square root module.

entity tb_sqrt is
end entity tb_sqrt;

architecture simulation of tb_sqrt is

   constant C_DATA_SIZE : integer                                    := 8;
   constant C_ZERO      : std_logic_vector(C_DATA_SIZE - 1 downto 0) := (others => '0');

   signal   clk : std_logic                                          := '1';
   signal   rst : std_logic                                          := '1';

   -- Signals conected to DUT
   signal   dut_s_ready : std_logic;
   signal   dut_s_valid : std_logic;
   signal   dut_s_data  : std_logic_vector(2 * C_DATA_SIZE - 1 downto 0);
   signal   dut_m_ready : std_logic;
   signal   dut_m_valid : std_logic;
   signal   dut_m_res   : std_logic_vector(C_DATA_SIZE - 1 downto 0);
   signal   dut_m_diff  : std_logic_vector(C_DATA_SIZE     downto 0);

   -- Signal to control execution of the testbench.
   signal   test_running : std_logic                                 := '1';

begin

   clk <= test_running and not clk after 5 ns;
   rst <= '1', '0' after 100 ns;


   --------------------------------------------------
   -- Instantiate DUT
   --------------------------------------------------

   sqrt_inst : entity work.sqrt
      generic map (
         G_DATA_SIZE => C_DATA_SIZE*2
      )
      port map (
         clk_i     => clk,
         rst_i     => rst,
         s_ready_o => dut_s_ready,
         s_valid_i => dut_s_valid,
         s_data_i  => dut_s_data,
         m_ready_i => dut_m_ready,
         m_valid_o => dut_m_valid,
         m_res_o   => dut_m_res,
         m_diff_o  => dut_m_diff
      ); -- sqrt_inst


   --------------------------------------------------
   -- Main test procedure starts here
   --------------------------------------------------

   main_test_proc : process
      -- Verify SQRT processing

      procedure verify_sqrt (
         val : integer
      ) is
         -- Calculate the integer square root.

         variable exp_sqrt_v : integer;
         variable exp_diff_v : integer;

         function sqrt (
            v : integer
         ) return integer is
            variable r_v : integer;
         begin
            r_v := 0;

            while r_v * r_v <= v loop
               r_v := r_v + 1;
            end loop;

            return r_v - 1;
         end function sqrt;

      --
      begin -- procedure verify_sqrt
         -- Calculate expected response
         exp_sqrt_v  := sqrt(val);
         exp_diff_v  := val - exp_sqrt_v * exp_sqrt_v;

         report "Verify SQRT: " & integer'image(val) &
                " -> " & integer'image(exp_sqrt_v) & ", " & integer'image(exp_diff_v);

         -- Start calculation
         dut_s_data  <= to_stdlogicvector(val, 2 * C_DATA_SIZE);
         dut_s_valid <= '1';
         wait until clk = '1';
         dut_s_valid <= '0';
         wait until clk = '1';
         assert dut_m_valid = '0';

         -- Verify received response is correct
         while dut_m_valid /= '1' loop
            wait until clk = '1';
         end loop;

         assert dut_m_res  = to_stdlogicvector(exp_sqrt_v, C_DATA_SIZE);
         assert dut_m_diff = to_stdlogicvector(exp_diff_v, C_DATA_SIZE + 1);
      end procedure verify_sqrt;

   --
   begin
      -- Wait until reset is complete
      dut_s_valid <= '0';
      dut_m_ready <= '1';
      wait until rst = '0';
      wait until clk = '1';

      -- Verify SQRT for a lot of small integers
      for i in 0 to 100 loop
         verify_sqrt(i);
      end loop;

      -- Verify SQRT for some large integers
      verify_sqrt(1000);
      verify_sqrt(10000);
      verify_sqrt(20000);
      verify_sqrt(30000);
      verify_sqrt(40000);
      verify_sqrt(50000);
      verify_sqrt(60000);
      verify_sqrt(65535);

      wait for 20 ns;

      -- Stop test
      wait until clk = '1';
      report "Test completed";
      test_running <= '0';
      wait;
   end process main_test_proc;

end architecture simulation;

