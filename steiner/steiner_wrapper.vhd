library ieee;
   use ieee.std_logic_1164.all;
   use ieee.numeric_std_unsigned.all;

library xpm;
   use xpm.vcomponents.all;

entity steiner_wrapper is
   generic (
      G_FONT_PATH : string := "";
      G_N         : natural;
      G_K         : natural;
      G_T         : natural;
      G_B         : natural
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
end entity steiner_wrapper;

architecture synthesis of steiner_wrapper is

   signal steiner_clk    : std_logic;
   signal steiner_rst    : std_logic;
   signal steiner_valid  : std_logic;
   signal steiner_ready  : std_logic;
   signal steiner_step   : std_logic;
   signal steiner_result : std_logic_vector(G_N * G_B - 1 downto 0);
   signal steiner_done   : std_logic;
   signal steiner_count  : std_logic_vector(15 downto 0);

   signal steiner_rx_valid : std_logic;
   signal steiner_rx_ready : std_logic;
   signal steiner_rx_data  : std_logic_vector(7 downto 0);

   signal sys_valid  : std_logic;
   signal sys_ready  : std_logic;
   signal sys_result : std_logic_vector(G_N * G_B - 1 downto 0);
   signal sys_done   : std_logic;

   signal vga_count_result : std_logic_vector(G_N * G_B + 15 downto 0);
   signal vga_result       : std_logic_vector(G_N * G_B - 1 downto 0);
   signal vga_count        : std_logic_vector(15 downto 0);

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
         step_i   => steiner_step and steiner_ready,
         result_o => steiner_result,
         valid_o  => steiner_valid,
         done_o   => steiner_done
      ); -- steiner_inst

   result_count_proc : process (steiner_clk)
   begin
      if rising_edge(steiner_clk) then
         if steiner_valid then
            steiner_count <= steiner_count + 1;
         end if;
         if steiner_rst then
            steiner_count <= (others => '0');
         end if;
      end if;
   end process result_count_proc;

   axi_fifo_inst : entity work.axi_fifo
      generic map (
         G_DEPTH     => 16,
         G_DATA_SIZE => G_N * G_B
      )
      port map (
         s_clk_i   => steiner_clk,
         s_rst_i   => steiner_rst,
         s_ready_o => steiner_ready,
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
         uart_rx_valid_i => '0',
         uart_rx_ready_o => open,
         uart_rx_data_i  => (others => '0'),
         uart_tx_valid_o => uart_tx_valid_o,
         uart_tx_ready_i => uart_tx_ready_i,
         uart_tx_data_o  => uart_tx_data_o,
         valid_i         => sys_valid,
         ready_o         => sys_ready,
         result_i        => sys_result,
         done_i          => sys_done
      ); -- uart_wrapper_inst

   axi_fifo_step_inst : entity work.axi_fifo
      generic map (
         G_DEPTH     => 16,
         G_DATA_SIZE => 8
      )
      port map (
         s_clk_i   => clk_i,
         s_rst_i   => rst_i,
         s_ready_o => uart_rx_ready_o,
         s_valid_i => uart_rx_valid_i,
         s_data_i  => uart_rx_data_i,
         m_clk_i   => steiner_clk,
         m_ready_i => steiner_rx_ready,
         m_valid_o => steiner_rx_valid,
         m_data_o  => steiner_rx_data
      ); -- axi_fifo_step_inst

   controller_inst : entity work.controller
      port map (
         clk_i      => steiner_clk,
         rst_i      => steiner_rst,
         rx_valid_i => steiner_rx_valid,
         rx_ready_o => steiner_rx_ready,
         rx_data_i  => steiner_rx_data,
         valid_i    => steiner_valid,
         step_o     => steiner_step
      ); -- controller_inst

   xpm_cdc_array_single_inst : component xpm_cdc_array_single
      generic map (
         DEST_SYNC_FF   => 10,
         INIT_SYNC_FF   => 1,
         SIM_ASSERT_CHK => 1,
         SRC_INPUT_REG  => 1,
         WIDTH          => G_N * G_B + 16
      )
      port map (
         src_clk  => steiner_clk,
         src_in   => steiner_count & steiner_result,
         dest_clk => vga_clk_i,
         dest_out => vga_count_result
      ); -- xpm_cdc_array_single_inst

   (vga_count, vga_result) <= vga_count_result;

   -- VGA Interface
   vga_wrapper_inst : entity work.vga_wrapper
      generic map (
         G_FONT_PATH => G_FONT_PATH,
         G_N         => G_N,
         G_K         => G_K,
         G_T         => G_T,
         G_B         => G_B
      )
      port map (
         vga_clk_i    => vga_clk_i,
         vga_rst_i    => vga_rst_i,
         vga_hcount_i => vga_hcount_i,
         vga_vcount_i => vga_vcount_i,
         vga_blank_i  => vga_blank_i,
         vga_rgb_o    => vga_rgb_o,
         vga_result_i => vga_result,
         vga_count_i  => vga_count
      ); -- vga_wrapper_inst

end architecture synthesis;

