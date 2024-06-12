library ieee;
   use ieee.std_logic_1164.all;
   use ieee.numeric_std_unsigned.all;

entity tb_gf2_solver is
end entity tb_gf2_solver;

architecture simulation of tb_gf2_solver is

   constant C_ROW_SIZE  : natural := 4;
   constant C_USER_SIZE : natural := 4;

   signal   running : std_logic   := '1';
   signal   clk     : std_logic   := '1';
   signal   rst     : std_logic   := '1';

   signal   dut_s_ready : std_logic;
   signal   dut_s_valid : std_logic;
   signal   dut_s_row   : std_logic_vector(C_ROW_SIZE - 1 downto 0);
   signal   dut_s_user  : std_logic_vector(C_USER_SIZE - 1 downto 0);
   signal   dut_m_ready : std_logic;
   signal   dut_m_valid : std_logic;
   signal   dut_m_user  : std_logic_vector(C_USER_SIZE - 1 downto 0);
   signal   dut_m_last  : std_logic;

begin

   clk <= running and not clk after 5 ns;
   rst <= '1', '0' after 100 ns;

   test_proc : process
      procedure send_row (
         row  : std_logic_vector;
         user : std_logic_vector
      ) is
      begin
         dut_s_row   <= row;
         dut_s_user  <= user;
         dut_s_valid <= '1';
         wait until clk = '1';

         while dut_s_ready = '0' loop
            wait until clk = '1';
         end loop;

         dut_s_valid <= '0';
         wait until clk = '1';
      end procedure send_row;

      procedure verify_result (
         user : std_logic_vector;
         last : std_logic
      ) is
      begin
         while (dut_m_valid and dut_m_ready) = '0' loop
            wait until clk = '1';
         end loop;

         assert dut_m_user = user
            report "Expected " & to_hstring(user) & ", got " & to_hstring(dut_m_user);
         assert dut_m_last = last
            report "Expected " & to_string(last) & ", got " & to_string(dut_m_last);
         wait until clk = '1';
      end procedure verify_result;

   begin
      dut_s_valid <= '0';
      dut_m_ready <= '1';
      wait until rst = '0';
      wait for 100 ns;
      wait until clk = '1';
      report "Test Started";

      send_row("0101", X"A");
      send_row("0011", X"B");
      send_row("1101", X"C");
      send_row("1010", X"D");
      send_row("0110", X"E");

      verify_result(X"E", '0');
      verify_result(X"A", '0');
      verify_result(X"B", '1');

      wait for 100 ns;
      report "Test Finished";
      running     <= '0';
      wait;
   end process test_proc;

   gf2_solver_inst : entity work.gf2_solver
      generic map (
         G_ROW_SIZE  => C_ROW_SIZE,
         G_USER_SIZE => C_USER_SIZE
      )
      port map (
         clk_i     => clk,
         rst_i     => rst,
         s_ready_o => dut_s_ready,
         s_valid_i => dut_s_valid,
         s_row_i   => dut_s_row,
         s_user_i  => dut_s_user,
         m_ready_i => dut_m_ready,
         m_valid_o => dut_m_valid,
         m_user_o  => dut_m_user,
         m_last_o  => dut_m_last
      ); -- gf2_solver_inst

end architecture simulation;

