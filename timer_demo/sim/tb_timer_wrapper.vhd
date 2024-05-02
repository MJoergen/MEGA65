library ieee;
   use ieee.std_logic_1164.all;
   use ieee.numeric_std_unsigned.all;

entity tb_timer_wrapper is
end entity tb_timer_wrapper;

architecture simulation of tb_timer_wrapper is

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

   signal   uart_tx_str : string(1 to 8);

begin

   clk <= running and not clk after 5 ns;
   rst <= '1', '0' after 97 ns;

   timer_wrapper_inst : entity work.timer_wrapper
      generic map (
         G_CLK_FREQ_HZ => 10
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
      ); -- timer_wrapper_inst

   uart_tx_ready <= '1';

   uart_tx_str_proc : process (clk)
   begin
      if rising_edge(clk) then
         if uart_tx_valid = '1' then
            uart_tx_str <= uart_tx_str(2 to uart_tx_str'length) & character'val(to_integer(uart_tx_data));
         end if;
         if uart_tx_str(uart_tx_str'length-1) = character'val(13) and
            uart_tx_str(uart_tx_str'length)   = character'val(10) then
            uart_tx_str <= (others => ' ');
         end if;
      end if;
   end process uart_tx_str_proc;

   test_proc : process
      pure function str_to_integer(arg : string) return integer is
         variable res_v : integer := 0;
      begin
         for i in 1 to 6 loop
            res_v := res_v * 10 + character'pos(arg(i)) - character'pos('0');
         end loop;
         return res_v;
      end function str_to_integer;
   begin
      uart_rx_valid <= '0';
      wait until rst = '0';
      wait until clk = '1';
      for i in 1 to 110 loop
         wait until clk = '1';
         if uart_tx_str(uart_tx_str'length-1) = character'val(13) and
            uart_tx_str(uart_tx_str'length)   = character'val(10) then
            assert str_to_integer(uart_tx_str) + 1 = i/10;
         end if;
      end loop;
      running       <= '0';
      report "Test finished";
   end process test_proc;

end architecture simulation;

