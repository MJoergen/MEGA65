library ieee;
   use ieee.std_logic_1164.all;
   use ieee.numeric_std_unsigned.all;

entity tb_cards_wrapper is
end entity tb_cards_wrapper;

architecture simulation of tb_cards_wrapper is

   constant C_PAIRS : integer                                        := 4;

   signal   running       : std_logic                                     := '1';
   signal   clk           : std_logic                                     := '1';
   signal   rst           : std_logic                                     := '1';
   signal   uart_rx_valid : std_logic;
   signal   uart_rx_ready : std_logic;
   signal   uart_rx_data  : std_logic_vector(7 downto 0);
   signal   uart_tx_valid : std_logic;
   signal   uart_tx_ready : std_logic;
   signal   uart_tx_data  : std_logic_vector(7 downto 0);

   signal   vga_clk    : std_logic                                        := '1';
   signal   vga_hcount : std_logic_vector(10 downto 0);
   signal   vga_vcount : std_logic_vector(10 downto 0);
   signal   vga_blank  : std_logic;
   signal   vga_rgb    : std_logic_vector(7 downto 0);

   signal   uart_tx_str : string(1 to 10);

begin

   clk <= running and not clk after 5 ns;
   rst <= '1', '0' after 100 ns;

   cards_wrapper_inst : entity work.cards_wrapper
      generic map (
         G_PAIRS => C_PAIRS
      )
      port map (
         clk_i           => clk,
         rst_i           => rst,
         uart_rx_valid_i => uart_rx_valid,
         uart_rx_ready_o => uart_rx_ready,
         uart_rx_data_i  => uart_rx_data,
         uart_tx_valid_o => uart_tx_valid,
         uart_tx_ready_i => uart_tx_ready,
         uart_tx_data_o  => uart_tx_data,
         vga_clk_i       => vga_clk,
         vga_hcount_i    => vga_hcount,
         vga_vcount_i    => vga_vcount,
         vga_blank_i     => vga_blank,
         vga_rgb_o       => vga_rgb
      ); -- cards_wrapper_inst

   uart_tx_ready <= '1';

   uart_tx_str_proc : process (clk)
   begin
      if rising_edge(clk) then
         if uart_tx_valid = '1' then
            uart_tx_str <= uart_tx_str(2 to 10) & character'val(to_integer(uart_tx_data));
         end if;
         if uart_rx_valid = '1' then
            uart_tx_str <= "          ";
         end if;
      end if;
   end process uart_tx_str_proc;

   test_proc : process
   begin
      uart_rx_valid <= '0';
      wait until rst = '0';
      wait for 200 ns;
      wait until clk = '1';

      assert uart_rx_ready = '1';
      uart_rx_data  <= X"50";
      uart_rx_valid <= '1';
      wait until clk = '1';
      uart_rx_valid <= '0';
      wait until clk = '1';

      wait for 200 ns;
      wait until clk = '1';

      assert uart_tx_str(1 to 8) = "1.1234.."
         report "Got : " & uart_tx_str(1 to 8);

      uart_rx_data  <= X"53";
      uart_rx_valid <= '1';
      wait until clk = '1';
      uart_rx_valid <= '0';
      wait until clk = '1';

      wait for 200 ns;
      wait until clk = '1';

      assert uart_tx_str(1 to 8) = "        "
         report "Got : " & uart_tx_str(1 to 8);

      for i in 1 to 30 loop
         uart_rx_data  <= X"53";
         uart_rx_valid <= '1';
         wait until clk = '1';
         uart_rx_valid <= '0';
         wait until clk = '1';
      end loop;

      assert uart_tx_str(1 to 8) = "        "
         report "Got : " & uart_tx_str(1 to 8);

      uart_rx_data  <= X"50";
      uart_rx_valid <= '1';
      wait until clk = '1';
      uart_rx_valid <= '0';
      wait until clk = '1';

      wait for 200 ns;
      wait until clk = '1';

      assert uart_tx_str(1 to 8) = "41312432"
         report "Got : " & uart_tx_str(1 to 8);

      running       <= '0';
      report "Test finished";
   end process test_proc;

end architecture simulation;

