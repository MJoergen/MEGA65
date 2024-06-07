library ieee;
   use ieee.std_logic_1164.all;
   use ieee.numeric_std_unsigned.all;

-- This is a self-verifying testbench for the multiplication modulo module.

entity tb_amm is
end entity tb_amm;

architecture simulation of tb_amm is

   constant C_DATA_SIZE : integer         := 32;

   signal   test_running : std_logic := '1';
   signal   clk          : std_logic := '1';
   signal   rst          : std_logic := '1';

   -- Signals conected to DUT
   signal   dut_s_ready : std_logic;
   signal   dut_s_valid : std_logic;
   signal   dut_s_val_a : std_logic_vector(C_DATA_SIZE - 1 downto 0);
   signal   dut_s_val_x : std_logic_vector(2 * C_DATA_SIZE - 1 downto 0);
   signal   dut_s_val_b : std_logic_vector(2 * C_DATA_SIZE - 1 downto 0);
   signal   dut_s_val_n : std_logic_vector(2 * C_DATA_SIZE - 1 downto 0);
   signal   dut_m_ready : std_logic;
   signal   dut_m_valid : std_logic;
   signal   dut_m_res   : std_logic_vector(2 * C_DATA_SIZE - 1 downto 0);

begin

   clk <= test_running and not clk after 5 ns;
   rst <= '1', '0' after 100 ns;

   --------------------------------------------------
   -- Instantiate DUT
   --------------------------------------------------

   amm_inst : entity work.amm
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
         s_val_n_i => dut_s_val_n,
         m_ready_i => dut_m_ready,
         m_valid_o => dut_m_valid,
         m_res_o   => dut_m_res
      ); -- i_amm


   --------------------------------------------------
   -- Main test procedure starts here
   --------------------------------------------------

   main_test_proc : process
      -- Verify AMM processing

      procedure verify_amm (
         val_a : integer;
         val_x : integer;
         val_b : integer;
         val_n : integer
      ) is
         variable exp_v : integer;
      begin -- procedure verify_add_mult
         -- Calculate expected response
         exp_v       := (val_a * val_x + val_b) mod val_n;

         report "Verify AMM: " & integer'image(val_a) &
                " * " & integer'image(val_x) &
                " + " & integer'image(val_b) &
                " mod " & integer'image(val_n) &
                " -> " & integer'image(exp_v);

         -- Start calculation
         dut_s_val_a <= to_stdlogicvector(val_a, C_DATA_SIZE);
         dut_s_val_x <= to_stdlogicvector(val_x, 2 * C_DATA_SIZE);
         dut_s_val_b <= to_stdlogicvector(val_b, 2 * C_DATA_SIZE);
         dut_s_val_n <= to_stdlogicvector(val_n, 2 * C_DATA_SIZE);
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
      end procedure verify_amm;

   --
   begin
      -- Wait until reset is complete
      dut_s_valid <= '0';
      dut_m_ready <= '1';
      wait until rst = '0';
      wait until clk = '1';

      -- Verify AMM for a lot of small integers
      for a in 0 to 5 loop
         --
         for x in 0 to 5 loop
            --
            for b in 0 to 5 loop
               --
               for n in 8 to 15 loop
                  verify_amm(a, x, b, n);
               end loop;

            --
            end loop;

         --
         end loop;

      --
      end loop;

      -- Verify AMM for some large integers
      verify_amm(21, 321, 4321, 54321);
      verify_amm(321, 4321, 54321, 654321);
      verify_amm(5321, 54321, 654321, 7654321);
      verify_amm(1, 37487, 39401, 61544);

      wait for 20 ns;

      -- Stop test
      wait until clk = '1';
      report "Test completed";
      test_running <= '0';
      wait;
   end process main_test_proc;

end architecture simulation;

