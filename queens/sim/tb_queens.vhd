----------------------------------------------------------------------------------
-- Company:  Granbo
-- Engineer: Michael Jørgensen
--
-- The file contains the top level test bench for the life demo.
----------------------------------------------------------------------------------

library ieee;
   use ieee.std_logic_1164.all;
   use ieee.numeric_std_unsigned.all;

entity tb_queens is
end entity tb_queens;

architecture simulation of tb_queens is

   constant C_NUM_QUEENS : natural := 4;

   -- Clock, reset, and enable
   signal   running : std_logic    := '1';
   signal   rst     : std_logic    := '1';
   signal   clk     : std_logic    := '1';
   signal   en      : std_logic;
   signal   board   : std_logic_vector(C_NUM_QUEENS * C_NUM_QUEENS - 1 downto 0);
   signal   valid   : std_logic;
   signal   done    : std_logic;

   signal   tb_count : natural     := 0;

   subtype  ROW_T is std_logic_vector(C_NUM_QUEENS - 1 downto 0);

   type     row_vector_type is array(natural range <>) of ROW_T;
   signal   board_rows : row_vector_type(C_NUM_QUEENS - 1 downto 0);

begin

   rst <= '1', '0' after 100 ns;
   clk <= running and not clk after 5 ns;
   en  <= '1';

   queens_inst : entity work.queens
      generic map (
         G_NUM_QUEENS => C_NUM_QUEENS
      )
      port map (
         clk_i   => clk,
         rst_i   => rst,
         en_i    => en,
         board_o => board,
         valid_o => valid,
         done_o  => done
      ); -- queens_inst

   test_proc : process
   begin
      wait until rst = '0';
      wait until clk = '1';

      wait until done = '1';
      wait until clk = '1';
      assert tb_count = 2;
      wait for 100 ns;
      running <= '0';
      report "Test finished";
   end process test_proc;

   rows_gen : for row in 0 to C_NUM_QUEENS - 1 generate
      board_rows(row) <= board(row * C_NUM_QUEENS + C_NUM_QUEENS - 1 downto row * C_NUM_QUEENS);
   end generate rows_gen;

   verify_proc : process (clk)
      variable rows_or_v  : std_logic_vector(C_NUM_QUEENS - 1 downto 0);
      constant C_ROW_ONES : std_logic_vector(C_NUM_QUEENS - 1 downto 0) := (others => '1');
   begin
      if rising_edge(clk) then
         rows_or_v := (others => '0');
         for row in 0 to C_NUM_QUEENS - 1 loop
            rows_or_v := rows_or_v or board_rows(row);
         end loop;

         if valid = '1' then
            assert rows_or_v = C_ROW_ONES;
            tb_count <= tb_count + 1;
         end if;
      end if;
   end process verify_proc;

end architecture simulation;

