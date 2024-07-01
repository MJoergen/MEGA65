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

   pure function has_small_divisors (
      arg    : natural;
      divmax : natural
   ) return boolean is
   begin
      for i in 2 to divmax loop
         if (arg mod i) = 0 then
            return true;
         end if;
      end loop;

      return false;
   end function has_small_divisors;

   signal stat_count : natural;
   signal stat_min   : natural;
   signal stat_max   : natural;
   signal stat_sum   : natural;

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
      variable val_v : natural;

      procedure update_stat(arg : natural) is
      begin
         if stat_count = 0 then
            stat_count <= 1;
            stat_min   <= arg;
            stat_max   <= arg;
            stat_sum   <= arg;
         else
            stat_count <= stat_count + 1;
            if arg < stat_min then
               stat_min <= arg;
            end if;
            if arg > stat_max then
               stat_max <= arg;
            end if;
            stat_sum <= stat_sum + arg;
         end if;
      end procedure update_stat;

      procedure verify (
         n : natural
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

            update_stat(start_v);

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
      stat_count <= 0;
      dut_m_ready <= '1';
      dut_s_valid <= '0';
      wait until rst = '0';
      wait for 1 us;
      wait until clk = '1';
      report "Test started.";

      --      verify(   2059);         --   1055 :   29 *   71
      --      verify(   4559);         --    956 :   47 *   97
      --      verify(  19549);         --   1341 :  113 *  173
      --      verify(  26329);         --   2457 :  113 *  233
      --      verify(  35119);         --   1003 :  173 *  203
      --      verify(  40309);         --   2366 :  173 *  233
      --      verify(3837523);         --   4135 : 1093 * 3511. (The two only known Wieferich primes)
      --
      --      for i in 14 to 30 loop
      --         verify(2 ** i + 1);
      --      end loop;

      for i in 1 to 500 loop
         val_v := 2 ** 30 + i;
         if not is_prime(val_v) and not has_small_divisors(val_v, 100) then
            verify(val_v);
         end if;
      end loop;

      report "stat_count=" & to_string(stat_count );
      report "stat_min  =" & to_string(stat_min   );
      report "stat_max  =" & to_string(stat_max   );
      report "stat_sum  =" & to_string(stat_sum   );
      report "stat_mean =" & to_string(stat_sum/stat_count);
      if stat_count > 2 then
         report "stat_smooth =" & to_string((stat_sum-stat_min-stat_max)/(stat_count-2));
      end if;

      wait until clk = '1';
      wait until clk = '1';
      running <= '0';
      report "Test finished.";
      wait;
   end process test_proc;

end architecture simulation;

