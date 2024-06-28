library ieee;
   use ieee.std_logic_1164.all;
   use ieee.numeric_std_unsigned.all;

entity tb_factor is
   generic (
      G_NUM_WORKERS     : natural;
      G_PRIME_ADDR_SIZE : natural;
      G_DATA_SIZE       : natural;
      G_VECTOR_SIZE     : natural
   );
end entity tb_factor;

architecture simulation of tb_factor is

   signal running : std_logic := '1';
   signal clk     : std_logic := '1';
   signal rst     : std_logic := '1';
   signal cycle   : natural   := 0;

   signal dut_s_ready : std_logic;
   signal dut_s_valid : std_logic;
   signal dut_s_data  : std_logic_vector(G_DATA_SIZE - 1 downto 0);
   signal dut_m_ready : std_logic;
   signal dut_m_valid : std_logic;
   signal dut_m_data  : std_logic_vector(G_DATA_SIZE - 1 downto 0);

   -- Cycles : Number
   --    532 :    2059 =   29 *   71
   --    927 :    4559 =   47 *   97
   --   1109 :   19549 =  113 *  173
   --   2067 :   26329 =  113 *  233
   --    402 :   35119 =  173 *  203
   --   2233 :   40309 =  173 *  233
   --   7725 : 3837523 = 1093 * 3511. (The two only known Wieferich primes)

   pure function is_prime (
      arg : natural
   ) return boolean is
      variable i_v : natural;
   begin
      if arg > 2 and (arg mod 2) = 0 then
         return false;
      end if;
      i_v := 3;

      while i_v * i_v <= arg loop
         if (arg mod i_v) = 0 then
            return false;
         end if;
         i_v := i_v + 2;
      end loop;

      return true;
   end function is_prime;

begin

   rst <= '1', '0' after 100 ns;
   clk <= running and not clk after 5 ns;

   factor_inst : entity work.factor
      generic map (
         G_NUM_WORKERS     => G_NUM_WORKERS,
         G_PRIME_ADDR_SIZE => G_PRIME_ADDR_SIZE,
         G_DATA_SIZE       => G_DATA_SIZE,
         G_VECTOR_SIZE     => G_VECTOR_SIZE
      )
      port map (
         clk_i     => clk,
         rst_i     => rst,
         s_ready_o => dut_s_ready,
         s_valid_i => dut_s_valid,
         s_data_i  => dut_s_data,
         m_ready_i => dut_m_ready,
         m_valid_o => dut_m_valid,
         m_data_o  => dut_m_data
      ); -- factor_inst

   cycle_proc : process (clk)
   begin
      if rising_edge(clk) then
         cycle <= cycle + 1;
      end if;
   end process cycle_proc;

   test_proc : process
      --

      procedure verify (
         n : integer
      ) is
         variable start_v : natural;
      begin
         report "Verify: n=" & to_string(n);
         if is_prime(n) then
            report "PRIME";
         else
            assert dut_s_ready = '1';
            assert dut_m_valid = '0';
            start_v     := cycle;
            dut_s_valid <= '1';
            dut_s_data  <= to_stdlogicvector(n, G_DATA_SIZE);
            wait until clk = '1';
            dut_s_valid <= '0';
            wait until clk = '1';
            assert dut_s_ready = '0';

            while dut_m_valid = '0' loop
               wait until clk = '1';
            end loop;

            start_v := cycle - start_v;
            report " ==> factor=" & to_string(to_integer(dut_m_data)) & " in " &
                   to_string(start_v) & " cycles.";

            if dut_s_data(G_DATA_SIZE - 1 downto 30) = 0 then
               assert (to_integer(dut_s_data) mod to_integer(dut_m_data)) = 0;
               assert to_integer(dut_m_data) /= 1 and to_integer(dut_m_data) /= to_integer(dut_s_data);
            end if;

            wait until clk = '1';
            assert dut_s_ready = '1';
            assert dut_m_valid = '0';
         end if;
      end procedure verify;

   --
   begin
      dut_m_ready <= '1';
      dut_s_valid <= '0';
      wait until rst = '0';
      wait for 1 us;
      wait until clk = '1';
      report "Test started.";

      verify(   2059);         --    819 :   29 *   71
      verify(   4559);         --    904 :   47 *   97
      verify(  19549);         --   1014 :  113 *  173
      verify(  26329);         --   2285 :  113 *  233
      verify(  35119);         --    975 :  173 *  203
      verify(  40309);         --   1805 :  173 *  233
      verify(3837523);         --   3660 : 1093 * 3511. (The two only known Wieferich primes)

      for i in 14 to 30 loop
         verify(2 ** i + 1);
      end loop;

      wait until clk = '1';
      wait until clk = '1';
      running <= '0';
      report "Test finished.";
      wait;
   end process test_proc;

end architecture simulation;

