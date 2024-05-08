library ieee;
   use ieee.std_logic_1164.all;
   use ieee.numeric_std_unsigned.all;

library work;
   use work.video_modes_pkg.all;

entity mega65 is
   generic (
      G_VIDEO_MODE : video_modes_type
   );
   port (
      -- MEGA65 I/O ports
      sys_clk_i       : in    std_logic;
      sys_rstn_i      : in    std_logic;
      uart_rxd_i      : in    std_logic;
      uart_txd_o      : out   std_logic;
      kb_io0_o        : out   std_logic;
      kb_io1_o        : out   std_logic;
      kb_io2_i        : in    std_logic;
      vga_red_o       : out   std_logic_vector(7 downto 0);
      vga_green_o     : out   std_logic_vector(7 downto 0);
      vga_blue_o      : out   std_logic_vector(7 downto 0);
      vga_hs_o        : out   std_logic;
      vga_vs_o        : out   std_logic;
      vdac_clk_o      : out   std_logic;
      vdac_blank_n_o  : out   std_logic;
      vdac_sync_n_o   : out   std_logic;
      -- Connection to design
      vga_clk_o       : out   std_logic;
      vga_hcount_o    : out   std_logic_vector(10 downto 0);
      vga_vcount_o    : out   std_logic_vector(10 downto 0);
      vga_blank_o     : out   std_logic;
      vga_rgb_i       : in    std_logic_vector(7 downto 0);
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

   signal   vga_clk   : std_logic;
   signal   vga_rst   : std_logic;
   signal   vga_vs    : std_logic;
   signal   vga_hs    : std_logic;
   signal   vga_de    : std_logic;
   signal   vga_vs_d1 : std_logic;
   signal   vga_hs_d1 : std_logic;
   signal   vga_de_d1 : std_logic;
   signal   vga_vs_d2 : std_logic;
   signal   vga_hs_d2 : std_logic;
   signal   vga_de_d2 : std_logic;
   signal   vga_vs_d3 : std_logic;
   signal   vga_hs_d3 : std_logic;
   signal   vga_de_d3 : std_logic;

   signal   key_num       : integer range 0 to 79; -- cycles through all keys with G_SCAN_FREQUENCY
   signal   key_pressed_n : std_logic;             -- low active: debounced feedback: is kb_key_num_o pressed right now?

   signal   key_pressed_n_d : std_logic;
   signal   key_valid       : std_logic;
   signal   key_ready       : std_logic;
   signal   key_data        : std_logic_vector(7 downto 0);
   signal   key_data_s      : std_logic_vector(7 downto 0);

   signal   uart_rx_valid : std_logic;
   signal   uart_rx_ready : std_logic;
   signal   uart_rx_data  : std_logic_vector(7 downto 0);

   constant C_KEYCODE_TO_ASCII : string(0 to 79) := "........3W" &
                                                    "A4ZSE.5RD6" &
                                                    "CFTX7YG8BH" &
                                                    "UV9IJ0MKON" &
                                                    "+PL-.:@,.*" &
                                                    ";..=./1..2" &
                                                    " .Q......." &
                                                    "..........";

begin

   clk_inst : entity work.clk
      port map (
         sys_clk_i  => sys_clk_i,
         sys_rstn_i => sys_rstn_i,
         vga_clk_o  => vga_clk,
         vga_rst_o  => vga_rst,
         clk_o      => clk_o,
         rst_o      => rst_o
      );

   m2m_keyb_inst : entity work.m2m_keyb
      port map (
         clk_main_i       => clk_o,
         clk_main_speed_i => 100 * 1000 * 1000,
         kio8_o           => kb_io0_o,
         kio9_o           => kb_io1_o,
         kio10_i          => kb_io2_i,
         enable_core_i    => '1',
         key_num_o        => key_num,
         key_pressed_n_o  => key_pressed_n,
         drive_led_i      => '0',
         qnice_keys_n_o   => open
      ); -- m2m_keyb_inst

   key_data_s  <= to_stdlogicvector(character'pos(C_KEYCODE_TO_ASCII(key_num)), 8);

   key_proc : process (clk_o)
   begin
      if rising_edge(clk_o) then
         key_pressed_n_d <= key_pressed_n;

         if key_ready = '1' then
            key_valid <= '0';
         end if;

         if key_data = key_data_s then
            if key_pressed_n = '1' then
               key_data <= (others => '0');
            end if;
         elsif key_pressed_n_d = '1' and key_pressed_n = '0' then
            key_data  <= key_data_s;
            key_valid <= '1';
         end if;

      end if;
   end process key_proc;

   axi_merger_inst : entity work.axi_merger
      generic map (
         G_DATA_SIZE => 8
      )
      port map (
         clk_i      => clk_o,
         rst_i      => rst_o,
         s1_ready_o => key_ready,
         s1_valid_i => key_valid,
         s1_data_i  => key_data,
         s2_ready_o => uart_rx_ready,
         s2_valid_i => uart_rx_valid,
         s2_data_i  => uart_rx_data,
         m_ready_i  => uart_rx_ready_i,
         m_valid_o  => uart_rx_valid_o,
         m_data_o   => uart_rx_data_o
      );

   uart_inst : entity work.uart
      generic map (
         G_DIVISOR => 100000000 / 115200
      )
      port map (
         clk_i      => clk_o,
         rst_i      => rst_o,
         tx_valid_i => uart_tx_valid_i,
         tx_ready_o => uart_tx_ready_o,
         tx_data_i  => uart_tx_data_i,
         rx_valid_o => uart_rx_valid,
         rx_ready_i => uart_rx_ready,
         rx_data_o  => uart_rx_data,
         uart_tx_o  => uart_txd_o,
         uart_rx_i  => uart_rxd_i
      ); -- uart_inst

   video_sync_inst : entity work.video_sync
      generic map (
         G_VIDEO_MODE => G_VIDEO_MODE
      )
      port map (
         clk_i     => vga_clk,
         rst_i     => vga_rst,
         vs_o      => vga_vs,
         hs_o      => vga_hs,
         de_o      => vga_de,
         pixel_x_o => vga_hcount_o,
         pixel_y_o => vga_vcount_o
      ); -- video_sync_inst

   vga_blank_o <= not vga_de;
   vga_clk_o   <= vga_clk;

   delay_proc : process (vga_clk)
   begin
      if rising_edge(vga_clk) then
         vga_vs_d1 <= vga_vs;
         vga_hs_d1 <= vga_hs;
         vga_de_d1 <= vga_de;

         vga_vs_d2 <= vga_vs_d1;
         vga_hs_d2 <= vga_hs_d1;
         vga_de_d2 <= vga_de_d1;

         vga_vs_d3 <= vga_vs_d2;
         vga_hs_d3 <= vga_hs_d2;
         vga_de_d3 <= vga_de_d2;
      end if;
   end process delay_proc;

   vdac_clk_o  <= vga_clk;

   output_proc : process (vga_clk)
   begin
      if rising_edge(vga_clk) then
         vga_red_o      <= vga_rgb_i;
         vga_green_o    <= vga_rgb_i;
         vga_blue_o     <= vga_rgb_i;
         vga_vs_o       <= vga_vs_d3;
         vga_hs_o       <= vga_hs_d3;
         vdac_sync_n_o  <= '0';
         vdac_blank_n_o <= '1';
      end if;
   end process output_proc;

end architecture synthesis;

