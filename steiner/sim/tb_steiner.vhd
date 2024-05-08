library ieee;
   use ieee.std_logic_1164.all;
   use ieee.numeric_std.all;

entity tb_steiner is
end entity tb_steiner;

architecture simulation of tb_steiner is

   constant C_N : natural           := 9;
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
            report to_string(result);
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

