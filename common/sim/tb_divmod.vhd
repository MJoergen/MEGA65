library ieee;
   use ieee.std_logic_1164.all;
   use ieee.numeric_std_unsigned.all;

-- This is a self-verifying testbench for the integer division module.

entity tb_divmod is
end entity tb_divmod;

architecture simulation of tb_divmod is

   constant C_DATA_SIZE : integer                               := 72;
   constant C_ZERO : std_logic_vector(C_DATA_SIZE - 1 downto 0) := (others => '0');

   signal   clk : std_logic := '1';
   signal   rst : std_logic := '1';

   -- Signals conected to DUT
   signal   dut_s_ready : std_logic;
   signal   dut_s_valid : std_logic;
   signal   dut_s_val_n : std_logic_vector(C_DATA_SIZE - 1 downto 0);
   signal   dut_s_val_d : std_logic_vector(C_DATA_SIZE - 1 downto 0);
   signal   dut_m_ready : std_logic;
   signal   dut_m_valid : std_logic;
   signal   dut_m_res_q : std_logic_vector(C_DATA_SIZE - 1 downto 0);
   signal   dut_m_res_r : std_logic_vector(C_DATA_SIZE - 1 downto 0);

   -- Signal to control execution of the testbench.
   signal   test_running : std_logic                       := '1';

begin

   clk <= test_running and not clk after 5 ns;
   rst <= '1', '0' after 100 ns;


   --------------------------------------------------
   -- Instantiate DUT
   --------------------------------------------------

   divmod_inst : entity work.divmod
      generic map (
         G_DATA_SIZE => C_DATA_SIZE
      )
      port map (
         clk_i     => clk,
         rst_i     => rst,
         s_ready_o => dut_s_ready,
         s_valid_i => dut_s_valid,
         s_val_n_i => dut_s_val_n,
         s_val_d_i => dut_s_val_d,
         m_ready_i => dut_m_ready,
         m_valid_o => dut_m_valid,
         m_res_q_o => dut_m_res_q,
         m_res_r_o => dut_m_res_r
      ); -- divmod_inst


   --------------------------------------------------
   -- Main test procedure starts here
   --------------------------------------------------

   main_test_proc : process
      -- Verify DIVMOD processing

      procedure verify_divmod (
         val_n : integer;
         val_d : integer
      ) is
         variable exp_q_v  : integer;
         variable exp_r_v  : integer;
         variable cycles_v : integer;

         function log2 (
            val : integer
         ) return integer is
            variable res_v : integer;
            variable tmp_v : integer;
         begin
            res_v := 0;
            tmp_v := 1;

            while tmp_v <= val loop
               res_v := res_v + 1;
               tmp_v := tmp_v * 2;
            end loop;

--            report "log2: " & integer'image(val) & " -> " & integer'image(res_v);

            return res_v;
         end function log2;

      --
      begin -- procedure verify_sqrt
         -- Calculate expected response
         exp_q_v   := val_n / val_d;
         exp_r_v   := val_n mod val_d;
         cycles_v  := 2 * log2(exp_q_v) + 2;

         report "Verify DIVMOD: " & integer'image(val_n) &
                " / " & integer'image(val_d) &
                " -> " & integer'image(exp_q_v) & ", " & integer'image(exp_r_v) &
                " in " & integer'image(cycles_v) & " cycles.";

         -- Start calculation
         dut_s_val_n <= to_stdlogicvector(val_n, C_DATA_SIZE);
         dut_s_val_d <= to_stdlogicvector(val_d, C_DATA_SIZE);
         dut_s_valid <= '1';
         dut_m_ready <= '0';
         wait until clk = '1';
         dut_s_valid <= '0';
         wait until clk = '1';
         assert dut_m_valid = '0';

         -- Verify response is received within a given time
         for i in 1 to cycles_v loop
            wait until clk = '1';
         end loop;
         assert dut_m_valid = '1';
         dut_m_ready <= '1';
         wait until clk = '1';

         -- Verify received response is correct
         assert dut_m_res_q = to_stdlogicvector(exp_q_v, C_DATA_SIZE);
         assert dut_m_res_r = to_stdlogicvector(exp_r_v, C_DATA_SIZE);
      end procedure verify_divmod;

   --
   begin
      -- Wait until reset is complete
      dut_s_valid <= '0';
      dut_m_ready <= '1';
      wait until rst = '0';
      wait until clk = '1';

      -- Verify DIVMOD for a lot of small integers
      for n in 0 to 10 loop
         --
         for d in 1 to 10 loop
            verify_divmod(n, d);
         end loop;

      --
      end loop;

      -- Verify DIVMOD for some large integers
      verify_divmod(1000 * 1000 * 1000, 1234567890);
      verify_divmod(1000 * 1000 * 1000, 123456789);
      verify_divmod(1000 * 1000 * 1000, 12345678);
      verify_divmod(1000 * 1000 * 1000, 1234567);
      verify_divmod(1000 * 1000 * 1000, 123456);
      verify_divmod(1000 * 1000 * 1000, 12345);
      verify_divmod(1000 * 1000 * 1000, 1234);
      verify_divmod(1000 * 1000 * 1000, 123);
      verify_divmod(1000 * 1000 * 1000, 12);
      verify_divmod(1000 * 1000 * 1000, 1);

      wait for 20 ns;

      -- Stop test
      wait until clk = '1';
      report "Test completed";
      test_running <= '0';
      wait;
   end process main_test_proc;

end architecture simulation;

