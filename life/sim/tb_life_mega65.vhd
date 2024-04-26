library ieee;
   use ieee.std_logic_1164.all;
   use ieee.numeric_std_unsigned.all;

entity tb_life_mega65 is
end entity tb_life_mega65;

architecture simulation of tb_life_mega65 is

   signal running  : std_logic := '1';
   signal clk      : std_logic := '1';
   signal rst      : std_logic := '1';
   signal uart_rxd : std_logic;
   signal uart_txd : std_logic;

   signal tx_valid : std_logic;
   signal tx_ready : std_logic;
   signal tx_data  : std_logic_vector(7 downto 0);
   signal rx_valid : std_logic;
   signal rx_ready : std_logic;
   signal rx_data  : std_logic_vector(7 downto 0);

begin

   clk <= running and not clk after 5 ns;
   rst <= '1', '0' after 100 ns;

   test_proc : process
   begin
      tx_valid <= '0';
      wait until rst = '0';
      wait for 200 ns;
      wait until clk = '1';

      assert tx_ready = '1';
      tx_data <= X"53";
      tx_valid <= '1';
      wait until clk = '1';
      tx_valid <= '0';
      wait until clk = '1';
      assert tx_ready = '0';

      wait until tx_ready = '1';
      wait for 2000 ns;
      wait until clk = '1';

      running <= '0';
      report "Test finished";
   end process test_proc;

   uart_inst : entity work.uart
      port map (
         clk_i      => clk,
         rst_i      => rst,
         tx_valid_i => tx_valid,
         tx_ready_o => tx_ready,
         tx_data_i  => tx_data,
         rx_valid_o => rx_valid,
         rx_ready_i => '1',
         rx_data_o  => rx_data,
         uart_tx_o  => uart_rxd,
         uart_rx_i  => uart_txd
      ); -- uart_inst

   life_mega65_inst : entity work.life_mega65
      port map (
         clk_i      => clk,
         max10_tx_i => not rst,
         uart_rxd_i => uart_rxd,
         uart_txd_o => uart_txd,
         kb_io2_i   => '0'
      ); -- life_mega65_inst

end architecture simulation;

