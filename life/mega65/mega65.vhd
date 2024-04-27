library ieee;
   use ieee.std_logic_1164.all;
   use ieee.numeric_std_unsigned.all;

entity mega65 is
   port (
      -- MEGA65 I/O ports
      sys_clk_i       : in    std_logic;
      sys_rstn_i      : in    std_logic;
      uart_rxd_i      : in    std_logic;
      uart_txd_o      : out   std_logic;
      kb_io0_o        : out   std_logic;
      kb_io1_o        : out   std_logic;
      kb_io2_i        : in    std_logic;
      vga_red_o       : out   std_logic_vector(7 downto 0) := X"00";
      vga_green_o     : out   std_logic_vector(7 downto 0) := X"00";
      vga_blue_o      : out   std_logic_vector(7 downto 0) := X"00";
      vga_hs_o        : out   std_logic                    := '0';
      vga_vs_o        : out   std_logic                    := '0';
      vdac_clk_o      : out   std_logic                    := '0';
      vdac_blank_n_o  : out   std_logic                    := '0';
      vdac_sync_n_o   : out   std_logic                    := '0';
      -- Connection to design
      clk_o           : out   std_logic;
      rst_o           : out   std_logic;
      uart_tx_valid_i : in    std_logic;
      uart_tx_ready_o : out   std_logic;
      uart_tx_data_i  : in    std_logic_vector(7 downto 0);
      uart_rx_valid_o : out   std_logic;
      uart_rx_ready_i : in    std_logic;
      uart_rx_data_o  : out   std_logic_vector(7 downto 0)
   );
end entity mega65;

architecture synthesis of mega65 is

begin

   clk_inst : entity work.clk
      port map (
         sys_clk_i  => sys_clk_i,
         sys_rstn_i => sys_rstn_i,
         clk_o      => clk_o,
         rst_o      => rst_o
      );

   m2m_keyb_inst : entity work.m2m_keyb
      port map (
         clk_main_i       => sys_clk_i,
         clk_main_speed_i => 100 * 1000 * 1000,
         kio8_o           => kb_io0_o,
         kio9_o           => kb_io1_o,
         kio10_i          => kb_io2_i,
         enable_core_i    => '1',
         key_num_o        => open,
         key_pressed_n_o  => open,
         drive_led_i      => '0',
         qnice_keys_n_o   => open
      ); -- m2m_keyb_inst

   uart_inst : entity work.uart
      port map (
         clk_i      => clk_o,
         rst_i      => rst_o,
         tx_valid_i => uart_tx_valid_i,
         tx_ready_o => uart_tx_ready_o,
         tx_data_i  => uart_tx_data_i,
         rx_valid_o => uart_rx_valid_o,
         rx_ready_i => uart_rx_ready_i,
         rx_data_o  => uart_rx_data_o,
         uart_tx_o  => uart_txd_o,
         uart_rx_i  => uart_rxd_i
      ); -- uart_inst

end architecture synthesis;

