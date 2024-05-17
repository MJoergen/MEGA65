library ieee;
   use ieee.std_logic_1164.all;
   use ieee.numeric_std_unsigned.all;

library xpm;
   use xpm.vcomponents.all;

library work;
   use work.video_modes_pkg.all;

entity steiner_wrapper is
   generic (
      G_N : natural;
      G_K : natural;
      G_T : natural;
      G_B : natural
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
      vga_hcount_i    : in    std_logic_vector(10 downto 0);
      vga_vcount_i    : in    std_logic_vector(10 downto 0);
      vga_blank_i     : in    std_logic;
      vga_rgb_o       : out   std_logic_vector(7 downto 0)
   );
end entity steiner_wrapper;


architecture synthesis of steiner_wrapper is

   constant C_VIDEO_MODE : video_modes_type := C_VIDEO_MODE_1280_720_60;

   signal   steiner_clk    : std_logic;
   signal   steiner_rst    : std_logic;
   signal   steiner_valid  : std_logic;
   signal   steiner_step   : std_logic;
   signal   steiner_result : std_logic_vector(G_N * G_B - 1 downto 0);
   signal   steiner_done   : std_logic;

   signal   sys_valid  : std_logic;
   signal   sys_ready  : std_logic;
   signal   sys_result : std_logic_vector(G_N * G_B - 1 downto 0);
   signal   sys_done   : std_logic;

begin

   steiner_clk_inst : entity work.steiner_clk
      port map (
         clk_i      => clk_i,
         rst_i      => rst_i,
         core_clk_o => steiner_clk,
         core_rst_o => steiner_rst
      ); -- clk_inst

   steiner_inst : entity work.steiner
      generic map (
         G_N => G_N,
         G_K => G_K,
         G_T => G_T,
         G_B => G_B
      )
      port map (
         clk_i    => steiner_clk,
         rst_i    => steiner_rst,
         step_i   => steiner_step,
         result_o => steiner_result,
         valid_o  => steiner_valid,
         done_o   => steiner_done
      ); -- steiner_inst

   axi_fifo_inst : entity work.axi_fifo
      generic map (
         G_DEPTH     => 16,
         G_DATA_SIZE => G_N * G_B
      )
      port map (
         s_clk_i   => steiner_clk,
         s_rst_i   => steiner_rst,
         s_ready_o => steiner_step,
         s_valid_i => steiner_valid,
         s_data_i  => steiner_result,
         m_clk_i   => clk_i,
         m_ready_i => sys_ready,
         m_valid_o => sys_valid,
         m_data_o  => sys_result
      ); -- axi_fifo_inst

   xpm_cdc_single_inst : component xpm_cdc_single
      generic map (
         DEST_SYNC_FF   => 10,
         INIT_SYNC_FF   => 1,
         SIM_ASSERT_CHK => 1,
         SRC_INPUT_REG  => 1
      )
      port map (
         src_clk  => steiner_clk,
         src_in   => steiner_done,
         dest_clk => clk_i,
         dest_out => sys_done
      ); -- xpm_cdc_single_inst

   -- UART Interface
   uart_wrapper_inst : entity work.uart_wrapper
      generic map (
         G_N => G_N,
         G_K => G_K,
         G_T => G_T,
         G_B => G_B
      )
      port map (
         clk_i           => clk_i,
         rst_i           => rst_i,
         uart_rx_valid_i => uart_rx_valid_i,
         uart_rx_ready_o => uart_rx_ready_o,
         uart_rx_data_i  => uart_rx_data_i,
         uart_tx_valid_o => uart_tx_valid_o,
         uart_tx_ready_i => uart_tx_ready_i,
         uart_tx_data_o  => uart_tx_data_o,
         valid_i         => sys_valid,
         ready_o         => sys_ready,
         result_i        => sys_result,
         done_i          => sys_done
      ); -- uart_wrapper_inst

end architecture synthesis;

