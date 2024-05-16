library ieee;
   use ieee.std_logic_1164.all;
   use ieee.numeric_std.all;

entity tb_steiner is
end entity tb_steiner;

architecture simulation of tb_steiner is

   constant C_N : natural           := 7;
   constant C_K : natural           := 3;
   constant C_T : natural           := 2;

   signal   clk     : std_logic     := '1';
   signal   rst     : std_logic     := '1';
   signal   running : std_logic     := '1';

   pure function binom (
      n : natural;
      k : natural
   ) return natural is
      variable res_v : natural := 1;
   begin
      for i in 1 to k loop
         res_v := (res_v * (n + 1 - i)) / i; -- This division will never cause fractions
      end loop;
      return res_v;
   end function binom;

   constant C_RESULT_SIZE : natural := binom(C_N, C_K);

   signal   result : std_logic_vector(C_RESULT_SIZE downto 0);
   signal   valid  : std_logic;
   signal   done   : std_logic;
   signal   step   : std_logic;
   signal   count  : natural;

   -- Each row has length "n".
   type     ram_type is array (natural range <>) of std_logic_vector(C_N - 1 downto 0);

   -- This calculates an array of all possible combinations of N choose K.

   pure function combination_init (
      n : natural;
      k : natural
   ) return ram_type is
      variable res_v : ram_type(C_RESULT_SIZE downto 0) := (others => (others => '0'));
      variable kk_v  : natural                       := k;
      variable ii_v  : natural                       := 0;
   begin
      report "combination_init: n=" & to_string(n) & ", k=" & to_string(k);
      loop_i : for i in 0 to C_RESULT_SIZE - 1 loop
         kk_v := k;
         ii_v := i;
         loop_j : for j in 0 to C_N - 1 loop
            if kk_v = 0 then
               exit loop_j;
            end if;
            if ii_v < binom(n - j - 1, kk_v - 1) then
               res_v(i)(j) := '1';
               kk_v        := kk_v - 1;
            else
               ii_v := ii_v - binom(n - j - 1, kk_v - 1);
            end if;
         end loop loop_j;
      end loop loop_i;
      report "combination_init done.";
      return res_v;
   end function combination_init;

   pure function reverse(arg : std_logic_vector) return std_logic_vector is
      variable res_v : std_logic_vector(arg'range);
   begin
      for i in arg'range loop
         res_v(i) := arg(arg'left-arg'right-i);
      end loop;
      return res_v;
   end function reverse;

   -- Each row contains exactly "k" ones, except the last which is just zero.
   constant C_COMBINATIONS : ram_type(C_RESULT_SIZE downto 0) := combination_init(C_N, C_K);

begin

   clk <= running and not clk after 5 ns;
   rst <= '1', '0' after 100 ns;

   step <= '1';

   steiner_inst : entity work.steiner
      generic map (
         G_N           => C_N,
         G_K           => C_K,
         G_T           => C_T,
         G_RESULT_SIZE => C_RESULT_SIZE
      )
      port map (
         clk_i    => clk,
         rst_i    => rst,
         step_i   => step,
         result_o => result,
         valid_o  => valid,
         done_o   => done
      ); -- steiner_inst

   count_proc : process (clk)
   begin
      if rising_edge(clk) then
         if valid = '1' then
            count <= count + 1;
            for i in 0 to C_RESULT_SIZE loop
               if result(i) then
                  report to_string(reverse(C_COMBINATIONS(i)));
               end if;
            end loop;
            report "";
         end if;
         if done = '1' then
            report to_string(count) & " solutions found.";
            running <= '0';
         end if;
         if rst = '1' then
            count <= 0;
         end if;
      end if;
   end process count_proc;

end architecture simulation;

