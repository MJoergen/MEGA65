library ieee;
   use ieee.std_logic_1164.all;
   use ieee.numeric_std.all;

entity tb_uart is
end entity tb_uart;

architecture simulation of tb_uart is

   signal running  : std_logic := '1';
   signal clk      : std_logic := '1';
   signal rst      : std_logic := '1';
   signal tx_valid : std_logic;
   signal tx_ready : std_logic;
   signal tx_data  : std_logic_vector(7 downto 0);
   signal rx_valid : std_logic;
   signal rx_ready : std_logic;
   signal rx_data  : std_logic_vector(7 downto 0);

   signal data     : std_logic;

begin

   clk <= running and not clk after 5 ns;
   rst <= '1', '0' after 100 ns;

   test_proc : process
   begin
      tx_valid <= '0';
      rx_ready <= '0';
      wait until rst = '0';

      wait for 200 ns;
      wait until clk = '0';
      tx_data <= X"53";
      tx_valid <= '1';
      wait until clk = '0';
      tx_valid <= '0';

      wait until rx_valid = '1';
      wait until clk = '0';
      assert rx_data = X"53";
      assert rx_valid = '1';
      wait until clk = '0';
      assert rx_data = X"53";
      assert rx_valid = '1';
      rx_ready <= '1';
      wait until clk = '0';
      assert rx_valid = '0';
      wait until clk = '0';

      running <= '0';
      report "Test finished";
   end process test_proc;

   uart_tx_inst : entity work.uart
      port map (
         clk_i      => clk,
         rst_i      => rst,
         tx_valid_i => tx_valid,
         tx_ready_o => tx_ready,
         tx_data_i  => tx_data,
         rx_valid_o => open,
         rx_ready_i => '1',
         rx_data_o  => open,
         uart_tx_o  => data,
         uart_rx_i  => '1'
      ); -- uart_inst

   uart_rx_inst : entity work.uart
      port map (
         clk_i      => clk,
         rst_i      => rst,
         tx_valid_i => '0',
         tx_ready_o => open,
         tx_data_i  => X"00",
         rx_valid_o => rx_valid,
         rx_ready_i => rx_ready,
         rx_data_o  => rx_data,
         uart_tx_o  => open,
         uart_rx_i  => data
      ); -- uart_inst

end architecture simulation;

