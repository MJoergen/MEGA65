library ieee;
   use ieee.std_logic_1164.all;
   use ieee.numeric_std_unsigned.all;

entity tb_steiner_wrapper is
   generic (
      G_N : natural;
      G_K : natural;
      G_T : natural;
      G_B : natural
   );
end entity tb_steiner_wrapper;

architecture simulation of tb_steiner_wrapper is

   signal running       : std_logic     := '1';
   signal clk           : std_logic     := '1';
   signal rst           : std_logic     := '1';
   signal uart_rx_valid : std_logic;
   signal uart_rx_ready : std_logic;
   signal uart_rx_data  : std_logic_vector(7 downto 0);
   signal uart_tx_valid : std_logic;
   signal uart_tx_ready : std_logic;
   signal uart_tx_data  : std_logic_vector(7 downto 0);

   signal vga_clk    : std_logic        := '1';
   signal vga_rst    : std_logic        := '1';
   signal vga_hcount : std_logic_vector(10 downto 0);
   signal vga_vcount : std_logic_vector(10 downto 0);
   signal vga_blank  : std_logic;
   signal vga_rgb    : std_logic_vector(7 downto 0);

   signal uart_tx_str : string(1 to 40) := (others => ' ');

begin

   clk <= running and not clk after 5 ns;
   rst <= '1', '0' after 100 ns;

   steiner_wrapper_inst : entity work.steiner_wrapper
      generic map (
         G_FONT_PATH  => "../../common/",
         G_N => G_N,
         G_K => G_K,
         G_T => G_T,
         G_B => G_B
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
         vga_rst_i       => vga_rst,
         vga_hcount_i    => vga_hcount,
         vga_vcount_i    => vga_vcount,
         vga_blank_i     => vga_blank,
         vga_rgb_o       => vga_rgb
      ); -- steiner_wrapper_inst

   uart_tx_ready <= '1';

   uart_tx_str_proc : process (clk)
   begin
      if rising_edge(clk) then
         if uart_tx_valid = '1' then
            uart_tx_str <= uart_tx_str(2 to uart_tx_str'right) & character'val(to_integer(uart_tx_data));
         end if;
         if uart_tx_str(uart_tx_str'right) = character'val(10) then
            report uart_tx_str;
            uart_tx_str <= (others => ' ');
         end if;
         if rst = '1' then
            uart_tx_str <= (others => ' ');
         end if;
      end if;
   end process uart_tx_str_proc;

   test_proc : process
   begin
      uart_rx_valid <= '1';
      uart_rx_data <= X"45";
      wait until rst = '0';
      wait for 2000 ns;
      wait until clk = '1';

      assert uart_rx_ready = '1';

      wait for 100 us;

      running       <= '0';
      report "Test finished";
      wait;
   end process test_proc;

end architecture simulation;

