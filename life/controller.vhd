library ieee;
   use ieee.std_logic_1164.all;
   use ieee.numeric_std_unsigned.all;

entity controller is
   generic (
      G_ROWS : integer;
      G_COLS : integer
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
      board_i         : in    std_logic_vector(G_ROWS * G_COLS - 1 downto 0);
      step_o          : out   std_logic;
      wr_index_o      : out   integer range G_ROWS * G_COLS - 1 downto 0;
      wr_value_o      : out   std_logic;
      wr_en_o         : out   std_logic
   );
end entity controller;

architecture synthesis of controller is

   type   state_type is (IDLE_ST, PRINTING_ST);
   signal state : state_type := IDLE_ST;

   signal cur_col : natural range 0 to G_COLS + 1;
   signal cur_row : natural range 0 to G_ROWS;

begin

   wr_index_o      <= 0;
   wr_value_o      <= '0';
   wr_en_o         <= '0';

   uart_rx_ready_o <= '1' when state = IDLE_ST else
                      '0';

   fsm_proc : process (clk_i)
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
                        cur_col <= 0;
                        cur_row <= 0;
                        state   <= PRINTING_ST;

                     when others =>
                        null;

                  end case;

               end if;

            when PRINTING_ST =>
               if uart_tx_ready_i = '1' then
                  if cur_col < G_COLS and cur_row < G_ROWS then
                     if board_i(G_COLS * G_ROWS - 1 - G_COLS * cur_row - cur_col) = '1' then
                        uart_tx_data_o <= X"58";                                             -- "X"
                     else
                        uart_tx_data_o <= X"2E";                                             -- "."
                     end if;
                  else
                     if cur_col = G_COLS then
                        uart_tx_data_o <= X"0D";
                     else
                        uart_tx_data_o <= X"0A";
                     end if;
                  end if;
                  uart_tx_valid_o <= '1';

                  if cur_col < G_COLS + 1 and cur_row < G_ROWS then
                     cur_col <= cur_col + 1;
                  else
                     cur_col <= 0;
                     if cur_row < G_ROWS then
                        cur_row <= cur_row + 1;
                     else
                        state <= IDLE_ST;
                     end if;
                  end if;
               end if;

         end case;

         if rst_i = '1' then
            state <= IDLE_ST;
         end if;
      end if;
   end process fsm_proc;

end architecture synthesis;

