library ieee;
   use ieee.std_logic_1164.all;
   use ieee.numeric_std.all;

entity tb_steiner is
   generic (
      G_N : natural;
      G_K : natural;
      G_T : natural;
      G_B : natural
   );
end entity tb_steiner;

architecture simulation of tb_steiner is

   signal clk     : std_logic := '1';
   signal rst     : std_logic := '1';
   signal running : std_logic := '1';

   signal result : std_logic_vector(G_N * G_B - 1 downto 0);
   signal valid  : std_logic;
   signal done   : std_logic;
   signal step   : std_logic;
   signal count  : natural;

begin

   clk  <= running and not clk after 5 ns;
   rst  <= '1', '0' after 100 ns;

   step <= '1';

   steiner_inst : entity work.steiner
      generic map (
         G_N => G_N,
         G_K => G_K,
         G_T => G_T,
         G_B => G_B
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

            for i in 0 to G_B - 1 loop
               report to_string(result(G_N * (i + 1) - 1 downto G_N * i));
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

