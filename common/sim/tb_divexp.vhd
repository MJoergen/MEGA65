library ieee;
   use ieee.std_logic_1164.all;
   use ieee.numeric_std_unsigned.all;

-- This is a self-verifying testbench for the integer division module.

entity tb_divexp is
end entity tb_divexp;

architecture simulation of tb_divexp is

   constant C_DATA_SIZE : integer                                    := 32;
   constant C_ZERO      : std_logic_vector(C_DATA_SIZE - 1 downto 0) := (others => '0');

   signal   clk : std_logic                                          := '1';
   signal   rst : std_logic                                          := '1';

   -- Signals conected to DUT
   signal   dut_s_ready : std_logic;
   signal   dut_s_valid : std_logic;
   signal   dut_s_val_n : std_logic_vector(C_DATA_SIZE - 1 downto 0);
   signal   dut_s_val_d : std_logic_vector(C_DATA_SIZE - 1 downto 0);
   signal   dut_m_ready : std_logic;
   signal   dut_m_valid : std_logic;
   signal   dut_m_res   : std_logic_vector(C_DATA_SIZE - 1 downto 0);

   -- Signal to control execution of the testbench.
   signal   test_running : std_logic                                 := '1';

begin

   clk <= test_running and not clk after 5 ns;
   rst <= '1', '0' after 100 ns;


   --------------------------------------------------
   -- Instantiate DUT
   --------------------------------------------------

   divexp_inst : entity work.divexp
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
         m_res_o   => dut_m_res
      ); -- divexp_inst


   --------------------------------------------------
   -- Main test procedure starts here
   --------------------------------------------------

   main_test_proc : process
      -- Verify DIVMOD processing

      procedure verify_divexp (
         val_n : integer;
         val_d : integer
      ) is
         variable exp_v : integer;

         pure function calc_divexp (
            n : integer;
            d : integer
         ) return integer is
            variable res_v : integer;
            variable n_v   : integer;
         begin
            assert n > 1;
            assert d > 1;
            res_v := 0;
            n_v   := n;

            while n_v mod d = 0 loop
               n_v   := n_v / d;
               res_v := res_v + 1;
            end loop;

            return res_v;
         end function calc_divexp;

      begin -- procedure verify_sqrt
         -- Calculate expected response
         exp_v       := calc_divexp(val_n, val_d);

         report "Verify DIVMOD: " & integer'image(val_n) &
                " / " & integer'image(val_d) &
                " -> " & integer'image(exp_v);

         -- Start calculation
         dut_s_val_n <= to_stdlogicvector(val_n, C_DATA_SIZE);
         dut_s_val_d <= to_stdlogicvector(val_d, C_DATA_SIZE);
         dut_s_valid <= '1';
         wait until clk = '1';
         dut_s_valid <= '0';
         wait until clk = '1';
         assert dut_m_valid = '0';

         -- Verify response is received within a given time
         while dut_m_valid /= '1' loop
            wait until clk = '1';
         end loop;

         -- Verify received response is correct
         assert dut_m_res = to_stdlogicvector(exp_v, C_DATA_SIZE);
      end procedure verify_divexp;

   --
   begin
      -- Wait until reset is complete
      dut_s_valid <= '0';
      dut_m_ready <= '1';
      wait until rst = '0';
      wait until clk = '1';

      -- Verify DIVMOD for a lot of small integers
      for n in 2 to 20 loop
         --
         for d in 2 to 10 loop
            verify_divexp(n, d);
         end loop;

      --
      end loop;

      -- Verify DIVEXP for some large integers
      verify_divexp(1234567890, 2);
      verify_divexp(1234567890, 3);
      verify_divexp(1234567890, 5);
      verify_divexp(1234567890, 7);
      verify_divexp(1234567890, 11);

      wait for 20 ns;

      -- Stop test
      wait until clk = '1';
      report "Test completed";
      test_running <= '0';
      wait;
   end process main_test_proc;

end architecture simulation;

