-- This performs exhaustive brute-force search for Steiner Systems.
-- https://en.wikipedia.org/wiki/Steiner_system
--
-- This is inspired by this video: https://www.youtube.com/watch?v=4xnRZqD7rAo
--
-- The task is as follows:
-- Given numbers n > k > t.
-- Generate all maximal sets of rows where in each set:
-- * Each row has length "n".
-- * Each row contains exactly "k" ones.
-- * Each pair of rows and'ed together contain less than "t" ones.
-- The maximum number of such rows is "b", where
-- b = B(n,t)/B(k,t).
-- r = B(n-1,t-1)/B(k-1,t-1).
-- Combs = B(n,k).
--
-- Possible parameter combinations:
--
--  N | K | T ||   B |   R |  Combs | Solutions
-- ---+---+---++-----+-----+--------+-----------
--  7 | 3 | 2 ||   7 |   3 |     35 |        30
--  9 | 3 | 2 ||  12 |   4 |     84 |       840
-- 15 | 3 | 2 ||  35 |   7 |    455 |
-- 21 | 5 | 2 ||  21 |   5 |  20349 |
--  8 | 4 | 3 ||  14 |   7 |     70 |
-- 10 | 4 | 3 ||  30 |  12 |    210 |
-- 22 | 6 | 3 ||  77 |  21 |  74613 |
-- 11 | 5 | 4 ||  66 |  30 |    462 |
-- 23 | 7 | 4 || 253 |  77 | 245157 |
-- 12 | 6 | 5 || 132 |  66 |    924 |
-- 24 | 8 | 5 || 759 | 253 | 735471 |
--
-- For the parameters (7, 3, 2) we get 30 solutions.
--
-- For the parameters (9, 3, 2) we get 840 solutions, one of which is the following.
-- The number on the left marks which of the C_NUM_COMBS = 84 is chosen.
--
--  6 **......*
-- 11 *.*....*.
-- 15 *..*..*..
-- 18 *...**...
-- 31 .**...*..
-- 35 .*.*.*...
-- 41 .*..*..*.
-- 49 ..***....
-- 60 ..*..*..*
-- 73 ...*...**
-- 78 ....*.*.*
-- 80 .....***.
--
-- Another solution is:
--  0 ***......
-- 13 *..**....
-- 22 *....**..
-- 27 *......**
-- 35 .*.*.*...
-- 41 .*..*..*.
-- 47 .*....*.*
-- 53 ..**....*
-- 55 ..*.*.*..
-- 59 ..*..*.*.
-- 71 ...*..**.
-- 76 ....**..*
--
-- Here we see that b = 12 is the number of rows selected.
-- And r = 4 is the sum of each column.
--
-- For (8,4,3) we have a solution (B=14, R=7):
--  0 ****....
--  9 **..**..
-- 14 **....**
-- 20 *.*.*.*.
-- 23 *.*..*.*
-- 27 *..**..*
-- 28 *..*.**.
-- 41 .**.*..*
-- 42 .**..**.
-- 46 .*.**.*.
-- 49 .*.*.*.*
-- 55 ..****..
-- 60 ..**..**
-- 69 ....****

library ieee;
   use ieee.std_logic_1164.all;
   use ieee.numeric_std.all;

library std;
   use std.textio.all;

entity steiner is
   generic (
      G_N           : natural;
      G_K           : natural;
      G_T           : natural;
      G_RESULT_SIZE : natural
   );
   port (
      clk_i    : in    std_logic;
      rst_i    : in    std_logic;
      step_i   : in    std_logic;
      valid_o  : out   std_logic;
      result_o : out   std_logic_vector(G_RESULT_SIZE downto 0);
      done_o   : out   std_logic
   );
end entity steiner;

architecture synthesis of steiner is

   -- Calculate the binomial coefficient B(n,k)

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

   constant C_NUM_COMBS : natural               := binom(G_N, G_K);
   constant C_B         : natural               := binom(G_N, G_T) / binom(G_K, G_T);
   constant C_R         : natural               := binom(G_N - 1, G_T - 1) / binom(G_K - 1, G_T - 1);

   signal   cur_index : natural range 0 to C_NUM_COMBS;

   signal   valid : std_logic_vector(C_NUM_COMBS - 1 downto 0);

   type     pos_type is array (natural range <>) of natural range 0 to C_NUM_COMBS;
   signal   positions  : pos_type(0 to C_B - 1) := (others => C_NUM_COMBS);
   signal   num_placed : natural range 0 to C_B;

   type     valid_type is array (natural range <>) of std_logic_vector(C_NUM_COMBS - 1 downto 0);
   signal   valid_vec : valid_type(C_B - 1 downto 0);

   signal   remove : std_logic;

begin

   assert G_RESULT_SIZE = C_NUM_COMBS;

   valid_vec_gen : for i in 0 to C_B - 1 generate

      valid_inst : entity work.valid
         generic map (
            G_N        => G_N,
            G_K        => G_K,
            G_T        => G_T,
            G_NUM_ROWS => C_NUM_COMBS
         )
         port map (
            pos_i   => positions(i),
            valid_o => valid_vec(i)
         );

   end generate valid_vec_gen;

   valid_proc : process (all)
      variable tmp_v : std_logic_vector(C_NUM_COMBS - 1 downto 0);
   begin
      tmp_v := (others => '1');
      for i in 0 to C_B - 1 loop
         tmp_v := tmp_v and valid_vec(i);

         -- The following is an optimization that saves a lot of work by doing an "early
         -- pruning" of the search tree.
         if positions(i) < C_NUM_COMBS then
            -- The first C_R rows must have the left-most column set
            if i < C_R then
               if positions(i) >= binom(G_N - 1, G_K - 1) then
                  tmp_v := (others => '0');
               end if;
            -- The next C_R-1 rows must have the second column set
            elsif i < 2 * C_R - 1 then
               if positions(i) >= binom(G_N - 1, G_K - 1) + binom(G_N - 2, G_K - 1) then
                  tmp_v := (others => '0');
               end if;
            end if;
         end if;
      end loop;
      valid <= tmp_v;
   end process valid_proc;

   main_proc : process (clk_i)
   begin
      if rising_edge(clk_i) then
         valid_o <= '0';
         if remove = '1' then
            cur_index             <= positions(num_placed) + 1;
            positions(num_placed) <= C_NUM_COMBS;
            remove                <= '0';
         else
            if num_placed = C_B then
               result_o <= (others => '0');
               res_loop : for i in 0 to C_B - 1 loop
                  result_o(positions(i)) <= '1';
               end loop res_loop;
               valid_o    <= '1';

               -- We remove the previous piece
               num_placed <= num_placed - 1;
               remove     <= '1';
            end if;

            if cur_index < C_NUM_COMBS and valid(cur_index) = '1' then
               -- We place the next piece
               num_placed            <= num_placed + 1;
               positions(num_placed) <= cur_index;
            else
               if cur_index < C_NUM_COMBS - 1 and unsigned(valid) /= 0 then
                  -- Go to next potential position
                  cur_index <= cur_index + 1;
               else
                  if num_placed > 0 then
                     -- We remove the previous piece
                     num_placed <= num_placed - 1;
                     remove     <= '1';
                  else
                     done_o <= '1';
                  end if;
               end if;
            end if;
         end if;

         if rst_i = '1' then
            positions  <= (others => C_NUM_COMBS);
            num_placed <= 0;
            cur_index  <= 0;
            done_o     <= '0';
            remove     <= '0';
            valid_o    <= '0';
         end if;
      end if;
   end process main_proc;

end architecture synthesis;

