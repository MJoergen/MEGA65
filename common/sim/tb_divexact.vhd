-- This computes the exact quotient of q = val1 / val2.
-- It is required that the division is exact, i.e. that there is no remainder.
-- In other words, the algorithm assumes that val1 = q * val2.
--
-- The algorithm

library ieee;
   use ieee.std_logic_1164.all;
   use ieee.numeric_std_unsigned.all;

entity tb_divexact is
end entity tb_divexact;

architecture behavioral of tb_divexact is

   constant C_DATA_SIZE : integer := 8;

   signal   running : std_logic   := '1';
   signal   rst     : std_logic   := '1';
   signal   clk     : std_logic   := '1';
   signal   s_valid : std_logic;
   signal   s_ready : std_logic;
   signal   s_val1  : std_logic_vector(C_DATA_SIZE - 1 downto 0);
   signal   s_val2  : std_logic_vector(C_DATA_SIZE - 1 downto 0);
   signal   m_valid : std_logic;
   signal   m_ready : std_logic;
   signal   m_res   : std_logic_vector(C_DATA_SIZE - 1 downto 0);

begin

   rst <= '1', '0' after 100 ns;
   clk <= running and not clk after 5 ns;

   divexact_inst : entity work.divexact
      generic map (
         G_DATA_SIZE => C_DATA_SIZE
      )
      port map (
         clk_i     => clk,
         rst_i     => rst,
         s_valid_i => s_valid,
         s_ready_o => s_ready,
         s_data1_i => s_val1,
         s_data2_i => s_val2,
         m_valid_o => m_valid,
         m_ready_i => m_ready,
         m_data_o  => m_res
      );

   m_ready <= '1';

   test_proc : process
      --

      procedure verify_divexact (
         val1_v    : integer;
         val2_v    : integer;
         exp_res_v : integer
      ) is
      begin
         s_val1  <= to_stdlogicvector(val1_v, C_DATA_SIZE);
         s_val2  <= to_stdlogicvector(val2_v, C_DATA_SIZE);
         s_valid <= '1';
         wait until clk = '1';

         while s_ready = '0' loop
            wait until clk = '1';
         end loop;

         s_valid <= '0';

         while m_valid /= '1' loop
            wait until clk = '1';
         end loop;

         report "divexact(" & integer'image(val1_v)
                & "," & integer'image(val2_v)
                & ") -> " & integer'image(to_integer(m_res));
         assert m_res = to_stdlogicvector(exp_res_v, C_DATA_SIZE);

         while m_valid = '1' loop
            wait until clk = '1';
         end loop;

      --
      end procedure verify_divexact;

   --
   begin
      s_valid <= '0';
      wait until rst = '0';
      wait for 100 ns;
      wait until clk = '1';

      verify_divexact(0, 1, 0);
      verify_divexact(1, 1, 1);
      verify_divexact(2, 1, 2);
      verify_divexact(4, 1, 4);
      verify_divexact(4, 2, 2);
      verify_divexact(4, 4, 1);
      verify_divexact(3 * 4, 4, 3);
      verify_divexact(4 * 4, 4, 4);
      verify_divexact(5 * 4, 4, 5);
      verify_divexact(3 * 3, 3, 3);
      verify_divexact(4 * 3, 3, 4);
      verify_divexact(5 * 3, 3, 5);
      verify_divexact(7 * 5, 5, 7);
      verify_divexact(7 * 15, 15, 7);
      verify_divexact(17 * 15, 15, 17);

      running <= '0';
      report "End of test";
      wait;
   end process test_proc;

end architecture behavioral;

