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

   signal   running     : std_logic  := '1';
   signal   clk         : std_logic  := '1';
   signal   rst         : std_logic  := '1';
   signal   dut_s_start : std_logic;
   signal   dut_s_val   : std_logic_vector(2 * G_DATA_SIZE - 1 downto 0);
   signal   dut_m_ready : std_logic;
   signal   dut_m_valid : std_logic;
   signal   dut_m_data  : std_logic_vector(2 * G_DATA_SIZE - 1 downto 0);
   signal   dut_m_fail  : std_logic;

   constant C_N : string            := "4559";
--   -- 2^37 + 1 = 3 * 1777 * 25781083
--   constant C_N : string             := "137438953473";

   -- Statistics with G_DATA_SIZE=12 and G_VECTOR_SIZE=8:
   --
   -- Cycles : Number
   --    532 :    2059 =   29 *   71
   --    927 :    4559 =   47 *   97
   --   1109 :   19549 =  113 *  173
   --   2067 :   26329 =  113 *  233
   --    402 :   35119 =  173 *  203
   --   2233 :   40309 =  173 *  233
   --   7725 : 3837523 = 1093 * 3511. (The two only known Wieferich primes)

   constant C_COUNTER_SIZE : natural := 16;
   signal   st_count       : std_logic_vector(C_COUNTER_SIZE - 1 downto 0);
   signal   st_valid       : std_logic;

   pure function to_stdlogicvector (
      arg : string;
      size : natural
   ) return std_logic_vector is
      variable res_v : std_logic_vector(size - 1 downto 0);
   begin
      res_v := (others => '0');
      for i in arg'range loop
         res_v := (res_v(size - 4 downto 0) & "000") + (res_v(size - 2 downto 0) & "0");
         res_v := res_v + to_stdlogicvector(character'pos(arg(i)) - 48, size);
      end loop;
      return res_v;
   end function to_stdlogicvector;

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
         m_data_o  => dut_m_data,
         m_fail_o  => dut_m_fail
      ); -- factor_inst

   test_proc : process
      --

      procedure verify (
         x : integer;
         n : integer
      ) is
      begin
         report "Verify: x=" & to_string(x) &
                ", n=" & to_string(n);
         assert (n mod x) = 0;
      end procedure verify;

   --
   begin
      dut_m_ready <= '1';
      dut_s_start <= '0';
      wait until rst = '0';
      wait for 1 us;
      wait until clk = '1';

      report "Test started, N = " & C_N;
      dut_s_start <= '1';
      dut_s_val   <= to_stdlogicvector(C_N, 2 * G_DATA_SIZE);
      wait until clk = '1';
      dut_s_start <= '0';

      while dut_m_valid = '0' loop
         if dut_m_fail = '1' then
            report "Failed";
            exit;
         end if;
         wait until clk = '1';
      end loop;

      if dut_m_fail = '0' then
         report "Verify: x=" & to_string(to_integer(dut_m_data)) &
                ", n=" & C_N;

         if dut_s_val(2 * G_DATA_SIZE-1 downto 30) = 0 then
            assert (to_integer(dut_s_val) mod to_integer(dut_m_data)) = 0;
            assert to_integer(dut_m_data) /= 1 and to_integer(dut_m_data) /= to_integer(dut_s_val);
         end if;
      end if;

      wait until clk = '1';
      wait until clk = '1';
      running <= '0';
      report "Test finished";
      wait;
   end process test_proc;

   stat_latency_inst : entity work.stat_latency
      generic map (
         G_COUNTER_SIZE => C_COUNTER_SIZE
      )
      port map (
         clk_i      => clk,
         rst_i      => rst,
         s_ready_i  => '1',
         s_valid_i  => dut_s_start,
         m_ready_i  => dut_m_ready,
         m_valid_i  => dut_m_valid,
         st_count_o => st_count,
         st_valid_o => st_valid
      ); -- stat_latency_inst

   stat_proc : process (clk)
   begin
      if rising_edge(clk) then
         if st_valid = '1' then
            report "st_count=" & to_string(to_integer(st_count));
         end if;
      end if;
   end process stat_proc;

end architecture simulation;

