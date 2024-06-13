library ieee;
   use ieee.std_logic_1164.all;
   use ieee.numeric_std_unsigned.all;

entity tb_factor is
   generic (
      G_PRIME_ADDR_SIZE : natural;
      G_DATA_SIZE       : natural;
      G_VECTOR_SIZE     : natural
   );
end entity tb_factor;

architecture simulation of tb_factor is

   signal   running     : std_logic := '1';
   signal   clk         : std_logic := '1';
   signal   rst         : std_logic := '1';
   signal   dut_s_start : std_logic;
   signal   dut_s_val   : std_logic_vector(2 * G_DATA_SIZE - 1 downto 0);
   signal   dut_m_ready : std_logic;
   signal   dut_m_valid : std_logic;
   signal   dut_m_x     : std_logic_vector(2 * G_DATA_SIZE - 1 downto 0);
   signal   dut_m_y     : std_logic_vector(2 * G_DATA_SIZE - 1 downto 0);

   constant C_N : natural           := 4559;

-- Other numbers to try:
--    2059 =   29 *   71
--    4559 =   47 *   97
--   19549 =  113 *  173
--   26329 =  113 *  233
--   35119 =  173 *  203
--   40309 =  173 *  233
-- 3837523 = 1093 * 3511. The two only known Wieferich primes.

begin

   rst <= '1', '0' after 100 ns;
   clk <= running and not clk after 5 ns;

   factor_inst : entity work.factor
      generic map (
         G_PRIME_ADDR_SIZE => G_PRIME_ADDR_SIZE,
         G_DATA_SIZE       => G_DATA_SIZE,
         G_VECTOR_SIZE     => G_VECTOR_SIZE
      )
      port map (
         clk_i     => clk,
         rst_i     => rst,
         s_start_i => dut_s_start,
         s_val_i   => dut_s_val,
         m_ready_i => dut_m_ready,
         m_valid_o => dut_m_valid,
         m_x_o     => dut_m_x,
         m_y_o     => dut_m_y
      ); -- factor_inst

   test_proc : process
      --

      procedure verify (
         x : integer;
         y : integer;
         n : integer
      ) is
      begin
         report "Verify: x=" & to_string(x) &
                ", y=" & to_string(y) &
                ", n=" & to_string(n);
         assert ((x * x - y * y) mod n) = 0;
      end procedure verify;

   --
   begin
      dut_m_ready <= '1';
      dut_s_start <= '0';
      wait until rst = '0';
      wait for 1 us;
      wait until clk = '1';

      report "Test started, N = " & to_string(C_N);
      dut_s_start <= '1';
      dut_s_val   <= to_stdlogicvector(C_N, 2 * G_DATA_SIZE);
      wait until clk = '1';
      dut_s_start <= '0';

      while dut_m_valid = '0' loop
         wait until clk = '1';
      end loop;

      verify(to_integer(dut_m_x), to_integer(dut_m_y), C_N);

      wait for 100 ns;
      running <= '0';
      report "Test finished";
      wait;
   end process test_proc;

end architecture simulation;

