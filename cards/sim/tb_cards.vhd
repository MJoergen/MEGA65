----------------------------------------------------------------------------------
-- Company:  Granbo
-- Engineer: Michael Jørgensen
--
-- The file contains the top level test bench for the life demo.
----------------------------------------------------------------------------------

library ieee;
   use ieee.std_logic_1164.all;
   use ieee.numeric_std_unsigned.all;

entity tb_cards is
   generic (
      G_PAIRS : natural
   );
end entity tb_cards;

architecture simulation of tb_cards is

   constant C_PAIRS : natural     := G_PAIRS;

   -- Clock, reset, and enable
   signal   running : std_logic   := '1';
   signal   rst     : std_logic   := '1';
   signal   clk     : std_logic   := '1';
   signal   en      : std_logic   := '1';

   signal   cards    : std_logic_vector(2 * C_PAIRS * C_PAIRS - 1 downto 0);
   signal   cards_or : std_logic_vector(2 * C_PAIRS * C_PAIRS - 1 downto 0);
   signal   invalid  : std_logic_vector(2 * C_PAIRS * C_PAIRS - 1 downto 0);
   signal   valid    : std_logic;
   signal   done     : std_logic;

   subtype  ROW_TYPE is std_logic_vector(2 * C_PAIRS - 1 downto 0);

   type     row_vector_type is array(natural range <>) of ROW_TYPE;

   signal   cards_rows    : row_vector_type(1 to C_PAIRS);
   signal   cards_or_rows : row_vector_type(1 to C_PAIRS);
   signal   invalid_rows  : row_vector_type(1 to C_PAIRS);

   signal   tb_count : natural    := 0;

   constant C_ROW_ONES : ROW_TYPE := (others => '1');

begin

   rst <= '1', '0' after 100 ns;
   clk <= running and not clk after 5 ns;
   en  <= '1';

   cards_inst : entity work.cards
      generic map (
         G_PAIRS => C_PAIRS
      )
      port map (
         clk_i      => clk,
         rst_i      => rst,
         en_i       => en,
         cards_o    => cards,
         cards_or_o => cards_or,
         invalid_o  => invalid,
         valid_o    => valid,
         done_o     => done
      ); -- cards_inst

   rows_gen : for row in 1 to C_PAIRS generate
      cards_rows(row)    <= cards((row - 1) * 2 * C_PAIRS + 2 * C_PAIRS - 1 downto (row - 1) * 2 * C_PAIRS);
      cards_or_rows(row) <= cards_or((row - 1) * 2 * C_PAIRS + 2 * C_PAIRS - 1 downto (row - 1) * 2 * C_PAIRS);
      invalid_rows(row)  <= invalid((row - 1) * 2 * C_PAIRS + 2 * C_PAIRS - 1 downto (row - 1) * 2 * C_PAIRS);
   end generate rows_gen;

   valid_proc : process (clk)
   begin
      if rising_edge(clk) then
         if rst = '0' then
            if valid = '1' then
               assert cards_or_rows(C_PAIRS) = C_ROW_ONES;
               tb_count <= tb_count + 1;
            end if;

            if done = '1' then
               assert tb_count = 2;
               running <= '0';
               report "Test finished";
            end if;
         end if;
      end if;
   end process valid_proc;

end architecture simulation;

