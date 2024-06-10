library ieee;
   use ieee.std_logic_1164.all;
   use ieee.numeric_std_unsigned.all;

entity tb_factor_wrapper is
   generic (
      G_DATA_SIZE   : natural;
      G_VECTOR_SIZE : natural
   );
end entity tb_factor_wrapper;

architecture simulation of tb_factor_wrapper is

   signal running       : std_logic := '1';
   signal clk           : std_logic := '1';
   signal rst           : std_logic := '1';
   signal uart_rx_valid : std_logic;
   signal uart_rx_ready : std_logic;
   signal uart_rx_data  : std_logic_vector(7 downto 0);
   signal uart_tx_valid : std_logic;
   signal uart_tx_ready : std_logic;
   signal uart_tx_data  : std_logic_vector(7 downto 0);

   signal vga_clk    : std_logic    := '1';
   signal vga_hcount : std_logic_vector(10 downto 0);
   signal vga_vcount : std_logic_vector(10 downto 0);
   signal vga_blank  : std_logic;
   signal vga_rgb    : std_logic_vector(7 downto 0);

begin

   clk <= running and not clk after 5 ns;
   rst <= '1', '0' after 100 ns;

   factor_wrapper_inst : entity work.factor_wrapper
      generic map (
         G_DATA_SIZE   => G_DATA_SIZE,
         G_VECTOR_SIZE => G_VECTOR_SIZE
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
      ); -- factor_wrapper_inst

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
         --
         for i in arg'range loop
            verify_uart_tx_byte(to_stdlogicvector(character'pos(arg(i)), 8));
         end loop;

         verify_uart_tx_byte(X"0D");
         verify_uart_tx_byte(X"0A");
      end procedure verify_uart_tx_string;

      procedure verify_cf (
         arg : integer
      ) is
      begin
         uart_rx_string(to_string(arg));
         report "cf(" & integer'image(arg)
                & ")";
         verify_uart_tx_string("1");
         verify_uart_tx_string("3");
         verify_uart_tx_string("1");
         verify_uart_tx_string("3");
      end procedure verify_cf;

   --
   begin
      uart_rx_valid <= '0';
      uart_tx_ready <= '1';
      wait until rst = '0';
      wait for 200 ns;
      wait until clk = '1';

      assert uart_rx_ready = '1';

      verify_cf(2059);

      wait for 20 us;

      running       <= '0';
      report "Test finished";
   end process test_proc;

end architecture simulation;

