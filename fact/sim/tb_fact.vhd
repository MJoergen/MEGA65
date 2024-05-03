----------------------------------------------------------------------------------
-- Company:  Granbo
-- Engineer: Michael Jørgensen
--
-- The file contains the top level test bench for the life demo.
----------------------------------------------------------------------------------

library ieee;
   use ieee.std_logic_1164.all;
   use ieee.numeric_std_unsigned.all;

entity tb_fact is
end entity tb_fact;

architecture simulation of tb_fact is

   constant C_SIZE     : integer       := 256;
   constant C_VAL_SIZE : integer       := 64;
   constant C_LOG_SIZE : integer       := 8;

   -- Clock, reset, and enable
   signal   running        : std_logic := '1';
   signal   rst            : std_logic := '1';
   signal   clk            : std_logic := '1';
   signal   epp_val2       : std_logic_vector(C_VAL_SIZE - 1 downto 0);
   signal   epp_start      : std_logic;
   signal   ctrl_val2      : std_logic_vector(C_SIZE - 1 downto 0);
   signal   ctrl_valid     : std_logic;
   signal   ctrl_ready     : std_logic := '1';
   signal   ctrl_state_log : std_logic_vector(C_LOG_SIZE - 1 downto 0);

begin

   rst <= '1', '0' after 100 ns;
   clk <= running and not clk after 5 ns;

   fact_inst : entity work.fact
      generic map (
         G_SIZE     => C_SIZE,
         G_VAL_SIZE => C_VAL_SIZE,
         G_LOG_SIZE => C_LOG_SIZE
      )
      port map (
         clk_i            => clk,
         rst_i            => rst,
         epp_val2_i       => epp_val2,
         epp_start_i      => epp_start,
         ctrl_val2_o      => ctrl_val2,
         ctrl_valid_o     => ctrl_valid,
         ctrl_ready_i     => ctrl_ready,
         ctrl_state_log_o => ctrl_state_log
      );

   test_proc : process
      --

      procedure verify_fact (
         arg : integer;
         res : integer
      ) is
      begin
         epp_val2  <= to_stdlogicvector(arg, C_VAL_SIZE);
         epp_start <= '1';
         wait until clk = '1';
         epp_start <= '0';

         while ctrl_valid /= '1' loop
            wait until clk = '1';
         end loop;

         report "fact(" & integer'image(arg)
                & ") -> " & integer'image(to_integer(ctrl_val2));
         assert ctrl_val2 = to_stdlogicvector(res, C_SIZE);
      end procedure verify_fact;

      procedure verify_fact_slv (
         arg : std_logic_vector(C_VAL_SIZE - 1 downto 0);
         res : std_logic_vector(C_VAL_SIZE - 1 downto 0)
      ) is
      begin
         epp_val2  <= arg;
         epp_start <= '1';
         wait until clk = '1';
         epp_start <= '0';

         while ctrl_valid /= '1' loop
            wait until clk = '1';
         end loop;

         report "fact(" & to_hstring(arg)
                & ") -> " & to_hstring(ctrl_val2);
         assert ctrl_val2(C_VAL_SIZE - 1 downto 0) = res;
      end procedure verify_fact_slv;

   --
   begin
      epp_start <= '0';
      wait until rst = '0';
      wait for 100 ns;
      wait until clk = '1';

      verify_fact(1, 1);
      verify_fact(2, 1);
      verify_fact(3, 1);
      verify_fact(4, 1);
      verify_fact(5, 1);
      verify_fact(6, 1);
      verify_fact(7, 1);
      verify_fact(8, 1);
      verify_fact(9, 1);
      verify_fact(10, 1);
      verify_fact(11, 1);
      verify_fact(12, 1);
      verify_fact(3 * 5 * 7, 1);
      verify_fact(3 * 3 * 7, 1);
      verify_fact(3 * 3 * 7 * 7, 1);
      verify_fact(3 * 3 * 3 * 7, 1);
      verify_fact(2 * 3 * 3 * 3 * 7, 1);
      verify_fact(2 * 2 * 3 * 3 * 3, 1);
      verify_fact(190, 1);
      verify_fact(191, 1);
      verify_fact(192, 1);
      verify_fact(193, 193);
      verify_fact(194, 1);
      verify_fact(195, 1);
      verify_fact(196, 1);
      verify_fact(197, 197);
      verify_fact(198, 1);
      verify_fact(199, 199);
      verify_fact(200, 1);

      verify_fact_slv(X"0000000000000001", X"0000000000000001"); -- 2^0+1  -> 1
      verify_fact_slv(X"0000000000000011", X"0000000000000001"); -- 2^4+1  -> 1
      verify_fact_slv(X"0000000000000101", X"0000000000000101"); -- 2^8+1  -> 257
      verify_fact_slv(X"0000000000001001", X"00000000000000F1"); -- 2^12+1 -> 241
      verify_fact_slv(X"0000000000010001", X"0000000000010001"); -- 2^16+1 -> 65537
      verify_fact_slv(X"0000000000100001", X"000000000000F0F1"); -- 2^20+1 -> 61681
      verify_fact_slv(X"0000000001000001", X"000000000002A3A1"); -- 2^24+1 -> 257*673
      verify_fact_slv(X"0000000010000001", X"0000000000F0F0F1"); -- 2^28+1 -> 15790321
      verify_fact_slv(X"0000000100000001", X"0000000100000001"); -- 2^32+1 -> 641*6700417
      verify_fact_slv(X"0000001000000001", X"00000000F0F0F0F1"); -- 2^36+1 -> 241*433*38737
      verify_fact_slv(X"0000010000000001", X"0000010000000001"); -- 2^40+1 -> 257*4278255361
      verify_fact_slv(X"0000100000000001", X"000000F0F0F0F0F1"); -- 2^44+1 -> 353*2931542417
      verify_fact_slv(X"0001000000000001", X"0001000000000001"); -- 2^48+1 -> 193*65537*22253377
      verify_fact_slv(X"0010000000000001", X"0000F0F0F0F0F0F1"); -- 2^52+1 -> 858001*308761441
      verify_fact_slv(X"0100000000000001", X"0100000000000001"); -- 2^56+1 -> 257*5153*54410972897
      verify_fact_slv(X"1000000000000001", X"00F0F0F0F0F0F0F1"); -- 2^60+1 -> 241*61681*4562284561

      verify_fact_slv(X"000000000000000F", X"0000000000000001"); -- 2^4-1   -> 1
      verify_fact_slv(X"00000000000000FF", X"0000000000000001"); -- 2^8-1   -> 1
      verify_fact_slv(X"0000000000000FFF", X"0000000000000001"); -- 2^12-1  -> 1
      verify_fact_slv(X"000000000000FFFF", X"0000000000000101"); -- 2^16-1  -> 257
      verify_fact_slv(X"00000000000FFFFF", X"0000000000000001"); -- 2^20-1  -> 1
      verify_fact_slv(X"0000000000FFFFFF", X"00000000000000F1"); -- 2^24-1  -> 241
      verify_fact_slv(X"000000000FFFFFFF", X"0000000000000001"); -- 2^28-1  -> 1
      verify_fact_slv(X"00000000FFFFFFFF", X"0000000001010101"); -- 2^32-1  -> 257*65537
      verify_fact_slv(X"0000000FFFFFFFFF", X"0000000000000001"); -- 2^36-1  -> 1
      verify_fact_slv(X"000000FFFFFFFFFF", X"000000000000F0F1"); -- 2^40-1  -> 61681
      verify_fact_slv(X"00000FFFFFFFFFFF", X"00000000222666EF"); -- 2^44-1  -> 397*683*2113
      verify_fact_slv(X"0000FFFFFFFFFFFF", X"00000000027C0A91"); -- 2^48-1  -> 241*257*673
      verify_fact_slv(X"000FFFFFFFFFFFFF", X"0000000866AAA891"); -- 2^52-1  -> 1613*2731*8191
      verify_fact_slv(X"00FFFFFFFFFFFFFF", X"0000000000F0F0F1"); -- 2^56-1  -> 15790321
      verify_fact_slv(X"0FFFFFFFFFFFFFFF", X"000000000006AC03"); -- 2^60-1  -> 331*1321
      verify_fact_slv(X"FFFFFFFFFFFFFFFF", X"0101010101010101"); -- 2^64-1  -> 257*641*65537*6700417

      -- This is supposedly the longest computation time. Simulation shows around 120 us.
      verify_fact_slv(X"a8b8b452291fe821", X"0000000000000001"); -- 3^40    -> 1


      running   <= '0';
      report "End of test";
      wait;
   end process test_proc;

end architecture simulation;

