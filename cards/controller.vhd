library ieee;
   use ieee.std_logic_1164.all;
   use ieee.numeric_std_unsigned.all;

entity controller is
   generic (
      G_PAIRS : integer
   );
   port (
      clk_i           : in    std_logic;
      rst_i           : in    std_logic;
      uart_rx_valid_i : in    std_logic;
      uart_rx_ready_o : out   std_logic;
      uart_rx_data_i  : in    std_logic_vector(7 downto 0);
      uart_tx_valid_o : out   std_logic;
      uart_tx_ready_i : in    std_logic;
      uart_tx_data_o  : out   std_logic_vector(7 downto 0);
      board_i         : in    std_logic_vector(2 * G_PAIRS * G_PAIRS - 1 downto 0);
      valid_i         : in    std_logic;
      done_i          : in    std_logic;
      step_o          : out   std_logic
   );
end entity controller;

architecture synthesis of controller is

   constant C_SIZE : natural   := 2 * G_PAIRS;

   type     state_type is (IDLE_ST, PRINTING_ST);
   signal   state : state_type := IDLE_ST;

   signal   cur_index : natural range 0 to C_SIZE + 1;

begin

   uart_rx_ready_o <= '1' when state = IDLE_ST else
                      '0';

   fsm_proc : process (clk_i)
      pure function get_char (
         board : std_logic_vector;
         index : natural
      ) return std_logic_vector is
      begin
         for row in 0 to G_PAIRS - 1 loop
            if board(row * C_SIZE + C_SIZE-1 - index) = '1' then
               return to_stdlogicvector(row + character'pos('1'), 8);
            end if;
         end loop;

         return to_stdlogicvector(character'pos('.'), 8);
      end function get_char;

   begin
      if rising_edge(clk_i) then
         step_o <= '0';
         if uart_tx_ready_i = '1' then
            uart_tx_valid_o <= '0';
         end if;

         case state is

            when IDLE_ST =>
               if uart_rx_valid_i = '1' then

                  case uart_rx_data_i is

                     when X"53" =>                                                           -- "S"
                        step_o <= '1';

                     when X"50" =>                                                           -- "P"
                        cur_index <= 0;
                        state     <= PRINTING_ST;

                     when others =>
                        null;

                  end case;

               end if;

            when PRINTING_ST =>
               if uart_tx_ready_i = '1' then
                  if cur_index < C_SIZE then
                     cur_index      <= cur_index + 1;
                     uart_tx_data_o <= get_char(board_i, cur_index);
                  else
                     if cur_index = C_SIZE then
                        cur_index      <= cur_index + 1;
                        uart_tx_data_o <= X"0D";
                     else
                        cur_index      <= 0;
                        uart_tx_data_o <= X"0A";
                        state          <= IDLE_ST;
                     end if;
                  end if;
                  uart_tx_valid_o <= '1';
               end if;

         end case;

         if rst_i = '1' then
            state <= IDLE_ST;
         end if;
      end if;
   end process fsm_proc;

end architecture synthesis;

