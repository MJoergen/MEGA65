library ieee;
   use ieee.std_logic_1164.all;
   use ieee.numeric_std_unsigned.all;

library xpm;
   use xpm.vcomponents.all;

entity timer_wrapper is
   generic (
      G_FONT_PATH   : string := "";
      G_CLK_FREQ_HZ : natural
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

      vga_clk_i       : in    std_logic;
      vga_rst_i       : in    std_logic;
      vga_hcount_i    : in    std_logic_vector(10 downto 0);
      vga_vcount_i    : in    std_logic_vector(10 downto 0);
      vga_blank_i     : in    std_logic;
      vga_rgb_o       : out   std_logic_vector(7 downto 0)
   );
end entity timer_wrapper;

architecture structural of timer_wrapper is

   constant C_COUNTER_MAX : natural := G_CLK_FREQ_HZ - 1;
   signal   counter       : natural range 0 to C_COUNTER_MAX;
   signal   step          : std_logic;

   signal   timer_h10 : std_logic_vector(3 downto 0);
   signal   timer_h1  : std_logic_vector(3 downto 0);
   signal   timer_m10 : std_logic_vector(3 downto 0);
   signal   timer_m1  : std_logic_vector(3 downto 0);
   signal   timer_s10 : std_logic_vector(3 downto 0);
   signal   timer_s1  : std_logic_vector(3 downto 0);
   signal   timer_all : std_logic_vector(23 downto 0);

   signal   vga_timer_all : std_logic_vector(23 downto 0);
   signal   vga_timer_h10 : std_logic_vector(3 downto 0);
   signal   vga_timer_h1  : std_logic_vector(3 downto 0);
   signal   vga_timer_m10 : std_logic_vector(3 downto 0);
   signal   vga_timer_m1  : std_logic_vector(3 downto 0);
   signal   vga_timer_s10 : std_logic_vector(3 downto 0);
   signal   vga_timer_s1  : std_logic_vector(3 downto 0);

   signal   uart_tx_data  : std_logic_vector(63 downto 0);
   signal   uart_tx_valid : std_logic;

begin

   uart_rx_ready_o <= '1';

   counter_proc : process (clk_i)
   begin
      if rising_edge(clk_i) then
         if counter = C_COUNTER_MAX then
            step    <= '1';
            counter <= 0;
         else
            counter <= counter + 1;
            step    <= '0';
         end if;
      end if;
   end process counter_proc;

   -- This generates the current time
   timer_inst : entity work.timer
      port map (
         clk_i       => clk_i,
         rst_i       => rst_i,
         step_i      => step,
         timer_h10_o => timer_h10,
         timer_h1_o  => timer_h1,
         timer_m10_o => timer_m10,
         timer_m1_o  => timer_m1,
         timer_s10_o => timer_s10,
         timer_s1_o  => timer_s1
      );

   uart_tx_data    <= to_std_logic_vector(character'pos('0') + to_integer(timer_h10), 8) &
                      to_std_logic_vector(character'pos('0') + to_integer(timer_h1), 8) &
                      to_std_logic_vector(character'pos('0') + to_integer(timer_m10), 8) &
                      to_std_logic_vector(character'pos('0') + to_integer(timer_m1), 8) &
                      to_std_logic_vector(character'pos('0') + to_integer(timer_s10), 8) &
                      to_std_logic_vector(character'pos('0') + to_integer(timer_s1), 8) &
                      X"0D0A";
   uart_tx_valid   <= step;

   serializer_inst : entity work.serializer
      generic map (
         G_DATA_SIZE_IN  => 64,
         G_DATA_SIZE_OUT => 8
      )
      port map (
         clk_i     => clk_i,
         rst_i     => rst_i,
         s_valid_i => uart_tx_valid,
         s_ready_o => open,
         s_data_i  => uart_tx_data,
         m_valid_o => uart_tx_valid_o,
         m_ready_i => uart_tx_ready_i,
         m_data_o  => uart_tx_data_o
      ); -- serializer_inst


   timer_all <= timer_h10 & timer_h1 & timer_m10 & timer_m1 & timer_s10 & timer_s1;

   xpm_cdc_array_single_inst : component xpm_cdc_array_single
      generic map (
         WIDTH => 24
      )
      port map (
         src_clk  => clk_i,
         src_in   => timer_all,
         dest_clk => vga_clk_i,
         dest_out => vga_timer_all
      ); -- xpm_cdc_array_single_inst

   (vga_timer_h10 , vga_timer_h1 , vga_timer_m10 , vga_timer_m1 , vga_timer_s10 , vga_timer_s1) <= vga_timer_all;

   vga_wrapper_inst : entity work.vga_wrapper
      generic map (
         G_FONT_PATH => G_FONT_PATH
      )
      port map (
         vga_clk_i       => vga_clk_i,
         vga_rst_i       => vga_rst_i,
         vga_hcount_i    => vga_hcount_i,
         vga_vcount_i    => vga_vcount_i,
         vga_blank_i     => vga_blank_i,
         vga_timer_h10_i => vga_timer_h10,
         vga_timer_h1_i  => vga_timer_h1,
         vga_timer_m10_i => vga_timer_m10,
         vga_timer_m1_i  => vga_timer_m1,
         vga_timer_s10_i => vga_timer_s10,
         vga_timer_s1_i  => vga_timer_s1,
         vga_rgb_o       => vga_rgb_o
      ); -- vga_wrapper_inst

end architecture structural;

