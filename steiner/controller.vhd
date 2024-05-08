library ieee;
   use ieee.std_logic_1164.all;
   use ieee.numeric_std_unsigned.all;

entity controller is
   generic (
      G_RESULT_SIZE : integer
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
      result_i         : in    std_logic_vector(G_RESULT_SIZE downto 0);
      valid_i         : in    std_logic;
      done_i          : in    std_logic;
      step_o          : out   std_logic
   );
end entity controller;

architecture synthesis of controller is

begin

   uart_rx_ready_o <= '1';
   uart_tx_valid_o <= '0';

   step_o <= '1';

end architecture synthesis;

