library ieee;
   use ieee.std_logic_1164.all;
   use ieee.numeric_std_unsigned.all;

entity tb_fact_wrapper is
end entity tb_fact_wrapper;

architecture simulation of tb_fact_wrapper is

   constant C_SIZE     : integer      := 256;
   constant C_VAL_SIZE : integer      := 64;
   constant C_LOG_SIZE : integer      := 8;

   signal   running       : std_logic := '1';
   signal   clk           : std_logic := '1';
   signal   rst           : std_logic := '1';
   signal   uart_rx_valid : std_logic;
   signal   uart_rx_ready : std_logic;
   signal   uart_rx_data  : std_logic_vector(7 downto 0);
   signal   uart_tx_valid : std_logic;
   signal   uart_tx_ready : std_logic;
   signal   uart_tx_data  : std_logic_vector(7 downto 0);

   signal   vga_clk    : std_logic    := '1';
   signal   vga_hcount : std_logic_vector(10 downto 0);
   signal   vga_vcount : std_logic_vector(10 downto 0);
   signal   vga_blank  : std_logic;
   signal   vga_rgb    : std_logic_vector(7 downto 0);

begin

   clk <= running and not clk after 5 ns;
   rst <= '1', '0' after 100 ns;

   fact_wrapper_inst : entity work.fact_wrapper
      generic map (
         G_SIZE     => C_SIZE,
         G_VAL_SIZE => C_VAL_SIZE,
         G_LOG_SIZE => C_LOG_SIZE
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
      ); -- queens_wrapper_inst

   test_proc : process
      --

      procedure uart_rx_byte (
         arg : std_logic_vector(7 downto 0)
      ) is
      begin
         --
         uart_rx_data  <= arg;
         uart_rx_valid <= '1';

         while uart_rx_ready /= '1' loop
            wait until clk = '1';
         end loop;

         wait until clk = '1';

         uart_rx_valid <= '0';

      --
      end procedure uart_rx_byte;

      procedure uart_rx_string (
         arg : string
      ) is
      begin
         --
         for i in arg'range loop
            uart_rx_byte(to_stdlogicvector(character'pos(arg(i)), 8));
         end loop;

         uart_rx_byte(X"0D");
         uart_rx_byte(X"0A");

      --
      end procedure uart_rx_string;

      procedure verify_uart_tx_byte (
         arg : std_logic_vector(7 downto 0)
      ) is
      begin
         uart_tx_ready <= '1';
         while uart_tx_valid /= '1' loop
            wait until clk = '1';
         end loop;
         assert uart_tx_data = arg
            report "Got: 0x" & to_hstring(uart_tx_data) & ", expected 0x" & to_hstring(arg);
         wait until clk = '1';
      end procedure verify_uart_tx_byte;

      procedure verify_uart_tx_string (
         arg : string
      ) is
      begin
         for i in arg'range loop
            verify_uart_tx_byte(to_stdlogicvector(character'pos(arg(i)), 8));
         end loop;
         verify_uart_tx_byte(X"0D");
         verify_uart_tx_byte(X"0A");
      end procedure verify_uart_tx_string;

      procedure verify_fact(arg : integer; res : integer) is
      begin
         uart_rx_string(to_string(arg));
         verify_uart_tx_string(to_string(res));
         report "fact(" & integer'image(arg)
                & ") -> " & integer'image(res);
      end procedure verify_fact;

   --
   begin
      uart_rx_valid <= '0';
      wait until rst = '0';
      wait for 200 ns;
      wait until clk = '1';

      assert uart_rx_ready = '1';

      uart_rx_string("123");
      verify_uart_tx_string("1");

      verify_fact(1, 1);
      verify_fact(2, 1);
      verify_fact(3, 1);
      verify_fact(4, 1);
      verify_fact(5, 1);
      verify_fact(6, 1);
      verify_fact(7, 1);
      verify_fact(8, 1);
      verify_fact(9, 1);
      verify_fact(10, 1);
      verify_fact(11, 1);
      verify_fact(12, 1);
      verify_fact(3 * 5 * 7, 1);
      verify_fact(3 * 3 * 7, 1);
      verify_fact(3 * 3 * 7 * 7, 1);
      verify_fact(3 * 3 * 3 * 7, 1);
      verify_fact(2 * 3 * 3 * 3 * 7, 1);
      verify_fact(2 * 2 * 3 * 3 * 3, 1);
      verify_fact(190, 1);
      verify_fact(191, 1);
      verify_fact(192, 1);
      verify_fact(193, 193);
      verify_fact(194, 1);
      verify_fact(195, 1);
      verify_fact(196, 1);
      verify_fact(197, 197);
      verify_fact(198, 1);
      verify_fact(199, 199);
      verify_fact(200, 1);

      wait for 200 ns;

      running       <= '0';
      report "Test finished";
   end process test_proc;

end architecture simulation;

