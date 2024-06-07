library ieee;
   use ieee.std_logic_1164.all;
   use ieee.numeric_std_unsigned.all;

-- This is a self-verifying testbench for the multiplication module.

entity tb_add_mult is
end entity tb_add_mult;

architecture simulation of tb_add_mult is

   constant C_DATA_SIZE : integer    := 72;

   signal   clk : std_logic;
   signal   rst : std_logic;

   -- Signals conected to DUT
   signal   dut_s_ready : std_logic;
   signal   dut_s_valid : std_logic;
   signal   dut_s_val_a : std_logic_vector(C_DATA_SIZE - 1 downto 0);
   signal   dut_s_val_x : std_logic_vector(C_DATA_SIZE - 1 downto 0);
   signal   dut_s_val_b : std_logic_vector(2 * C_DATA_SIZE - 1 downto 0);
   signal   dut_m_ready : std_logic;
   signal   dut_m_valid : std_logic;
   signal   dut_m_res   : std_logic_vector(2 * C_DATA_SIZE - 1 downto 0);

   -- Signal to control execution of the testbench.
   signal   test_running : std_logic := '1';

begin

   --------------------------------------------------
   -- Generate clock and reset
   --------------------------------------------------

   clk_proc : process
   begin
      clk <= '1', '0' after 1 ns;
      wait for 2 ns; -- 50 MHz
      if test_running = '0' then
         wait;
      end if;
   end process clk_proc;

   rst_proc : process
   begin
      rst <= '1', '0' after 20 ns;
      wait;
   end process rst_proc;


   --------------------------------------------------
   -- Instantiate DUT
   --------------------------------------------------

   add_mult_inst : entity work.add_mult
      generic map (
         G_DATA_SIZE => C_DATA_SIZE
      )
      port map (
         clk_i     => clk,
         rst_i     => rst,
         s_ready_o => dut_s_ready,
         s_valid_i => dut_s_valid,
         s_val_a_i => dut_s_val_a,
         s_val_x_i => dut_s_val_x,
         s_val_b_i => dut_s_val_b,
         m_ready_i => dut_m_ready,
         m_valid_o => dut_m_valid,
         m_res_o   => dut_m_res
      ); -- add_mult_inst


   --------------------------------------------------
   -- Main test procedure starts here
   --------------------------------------------------

   main_test_proc : process
      -- Verify ADD_MULT processing

      procedure verify_add_mult (
         val_a : integer;
         val_x : integer;
         val_b : integer
      ) is
         variable exp_v : integer;
      begin -- procedure verify_add_mult
         -- Calculate expected response
         exp_v       := val_a * val_x + val_b;

         report "Verify ADD_MULT: " & integer'image(val_a) &
                " * " & integer'image(val_x) &
                " + " & integer'image(val_b) &
                " -> " & integer'image(exp_v);

         -- Start calculation
         dut_s_val_a <= to_stdlogicvector(val_a, C_DATA_SIZE);
         dut_s_val_x <= to_stdlogicvector(val_x, C_DATA_SIZE);
         dut_s_val_b <= to_stdlogicvector(val_b, 2 * C_DATA_SIZE);
         dut_s_valid <= '1';
         wait until clk = '1';
         dut_s_valid <= '0';
         wait until clk = '1';
         assert dut_m_valid = '0';

         -- Verify received response is correct
         while dut_m_valid /= '1' loop
            wait until clk = '1';
         end loop;

         assert dut_m_res = to_stdlogicvector(exp_v, 2 * C_DATA_SIZE);
      end procedure verify_add_mult;

   --
   begin
      -- Wait until reset is complete
      dut_s_valid <= '0';
      dut_m_ready <= '1';
      wait until clk = '1' and rst = '0';

      -- Verify ADD_MULT for a lot of small integers
      for a in 0 to 5 loop
         --
         for x in 0 to 5 loop
            --
            for b in 0 to 5 loop
               verify_add_mult(a, x, b);
            end loop;

         --
         end loop;

      --
      end loop;

      -- Verify ADD_MULT for some large integers
      verify_add_mult(21, 321, 4321);
      verify_add_mult(321, 4321, 54321);
      verify_add_mult(5321, 54321, 654321);

      wait for 20 ns;

      -- Stop test
      wait until clk = '1';
      report "Test completed";
      test_running <= '0';
      wait;
   end process main_test_proc;

end architecture simulation;

