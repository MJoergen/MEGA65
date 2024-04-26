----------------------------------------------------------------------------------
-- Company:  Granbo
-- Engineer: Michael Jørgensen
--
-- The file contains the top level test bench for the life demo.
----------------------------------------------------------------------------------

library ieee;
   use ieee.std_logic_1164.all;
   use ieee.numeric_std_unsigned.all;

entity tb_life is
end entity tb_life;

architecture simulation of tb_life is

   constant C_ROWS       : integer                   := 7;
   constant C_COLS       : integer                   := 8;
   constant C_CELLS_INIT : std_logic_vector(0 to 55) :=
                                                        "00000000" &
                                                        "00010000" &
                                                        "00001000" &
                                                        "00111000" &
                                                        "00000000" &
                                                        "00000000" &
                                                        "00000000";

   -- Clock, reset, and enable
   signal   running : std_logic                      := '1';
   signal   rst     : std_logic                      := '1';
   signal   clk     : std_logic                      := '1';
   signal   en      : std_logic                      := '1';

   -- The current board status
   signal   board   : std_logic_vector(C_ROWS * C_COLS - 1 downto 0);

   -- Controls the individual cells of the board
   signal   index  : integer range C_ROWS * C_COLS - 1 downto 0;
   signal   value  : std_logic;
   signal   update : std_logic := '0';

begin

   rst <= '1', '0' after 100 ns;
   clk <= running and not clk after 5 ns;

   life_inst : entity work.life
      generic map (
         G_ROWS       => C_ROWS,
         G_COLS       => C_COLS,
         G_CELLS_INIT => C_CELLS_INIT
      )
      port map (
         rst_i    => rst,
         clk_i    => clk,
         en_i     => en,
         board_o  => board,
         index_i  => index,
         value_i  => value,
         update_i => update
      ); -- life_inst

   test_proc : process
      procedure print_board(arg : std_logic_vector) is
      begin
         for i in 0 to C_ROWS-1 loop
            report to_string(arg((i+1)*C_COLS-1 downto i*C_COLS));
         end loop;
      end procedure print_board;

   begin
      wait until rst = '0';
      assert board =
         "00000000" &
         "00010000" &
         "00001000" &
         "00111000" &
         "00000000" &
         "00000000" &
         "00000000";
      print_board(board);
      wait until clk = '1';
      print_board(board);
      wait until clk = '1';
      print_board(board);
      wait until clk = '1';
      print_board(board);
      wait until clk = '1';
      print_board(board);
      assert board =
         "00000000" &
         "00000000" &
         "00001000" &
         "00000100" &
         "00011100" &
         "00000000" &
         "00000000";

      wait until clk = '1';
      running <= '0';
      report "Test finished";
   end process test_proc;

end architecture simulation;

