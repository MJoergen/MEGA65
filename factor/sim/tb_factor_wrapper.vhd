library ieee;
   use ieee.std_logic_1164.all;
   use ieee.numeric_std_unsigned.all;

entity tb_factor_wrapper is
   generic (
      G_NUM_WORKERS     : natural;
      G_PRIME_ADDR_SIZE : natural;
      G_DATA_SIZE       : natural;
      G_VECTOR_SIZE     : natural
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
         G_NUM_WORKERS     => G_NUM_WORKERS,
         G_PRIME_ADDR_SIZE => G_PRIME_ADDR_SIZE,
         G_DATA_SIZE       => G_DATA_SIZE,
         G_VECTOR_SIZE     => G_VECTOR_SIZE
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

      --------------------------
      -- Send data to DUT
      --------------------------

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

      --------------------------
      -- Receive data from DUT
      --------------------------

      procedure get_uart_tx_byte (
         arg : out std_logic_vector(7 downto 0)
      ) is
      begin
         uart_tx_ready <= '1';

         while uart_tx_valid /= '1' loop
            wait until clk = '1';
         end loop;

         arg := uart_tx_data;
         wait until clk = '1';
      end procedure get_uart_tx_byte;

      procedure get_uart_tx_string (
         arg : out string
      ) is
         variable tmp_v : std_logic_vector(7 downto 0);
      begin
         --
         for i in arg'range loop
            get_uart_tx_byte(tmp_v);
            arg(i) := character'val(to_integer(tmp_v));
            if tmp_v = X"0A" then
               exit;
            end if;
         end loop;
      end procedure get_uart_tx_string;

      procedure get_uart_tx_integer (
         arg : out natural
      ) is
         variable s : string(1 to 10);
      begin
         get_uart_tx_string(s);
         arg := 0;

         for i in s'range loop
            if s(i) >= '0' and s(i) <= '9' then
               arg := arg * 10 + character'pos(s(i)) - 48;
            end if;
         end loop;
      end procedure get_uart_tx_integer;

      procedure verify_factor (
         p : integer;
         q : integer
      ) is
         variable f : natural;
      begin
         uart_rx_string(to_string(p * q));
         report "factor(" & integer'image(p * q)
                & ")";
         get_uart_tx_integer(f);
         report "=> " & to_string(f);
         assert f = p or f = q;
      end procedure verify_factor;

      pure function strip (
         arg : string
      ) return string is
      begin
         for i in arg'range loop
            if character'pos(arg(i)) = 13 then
               return arg(1 to i - 1);
            end if;
         end loop;

         return arg;
      end function strip;

      procedure verify_any_factor (
         s : string
      ) is
         variable f : string(s'range);
      begin
         uart_rx_string(s);
         report "factor(" & s & ")";
         get_uart_tx_string(f);
         report "=> " & strip(f);
      end procedure verify_any_factor;

   --
   begin
      uart_rx_valid <= '0';
      uart_tx_ready <= '1';
      wait until rst = '0';
      wait for 200 ns;
      wait until clk = '1';

      assert uart_rx_ready = '1';

      verify_factor(  29,   71);                 --    2059
      verify_factor(  59,   71);                 --    4189
      verify_factor(  59,  101);                 --    5959
      verify_factor(  89,  101);                 --    8989
      verify_factor(  89,  131);                 --   11659
      verify_factor( 149,  191);                 --   28459

      verify_factor(  47,   97);                 --    4559
      verify_factor( 113,  173);                 --   19549
      verify_factor( 113,  233);                 --   26329
      verify_factor( 173,  203);                 --   35119
      verify_factor( 173,  233);                 --   40309

      verify_any_factor("2097153");              -- 2^21 + 1 = 3^2 * 43 * 5419
      verify_any_factor("33554433");             -- 2^25 + 1 = 3 * 11 * 251 * 4051
      verify_any_factor("536870913");            -- 2^29 + 1 = 3 * 59 * 3033169
      verify_any_factor("8589934593");           -- 2^33 + 1 = 3^2 * 67 * 683 * 20857
      verify_any_factor("137438953473");         -- 2^37 + 1 = 3 * 1777 * 25781083

      wait for 20 us;

      running       <= '0';
      report "Test finished";
   end process test_proc;

end architecture simulation;

