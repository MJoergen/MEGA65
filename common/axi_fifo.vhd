library ieee;
   use ieee.std_logic_1164.all;
   use ieee.numeric_std_unsigned.all;

library xpm;
   use xpm.vcomponents.all;

entity axi_fifo is
   generic (
      G_DEPTH     : natural;
      G_DATA_SIZE : natural
   );
   port (
      s_clk_i   : in    std_logic;
      s_rst_i   : in    std_logic;
      s_ready_o : out   std_logic;
      s_valid_i : in    std_logic;
      s_data_i  : in    std_logic_vector(G_DATA_SIZE - 1 downto 0);
      m_clk_i   : in    std_logic;
      m_ready_i : in    std_logic;
      m_valid_o : out   std_logic;
      m_data_o  : out   std_logic_vector(G_DATA_SIZE - 1 downto 0)
   );
end entity axi_fifo;

architecture synthesis of axi_fifo is

   constant C_DATA_SIZE : natural := ((G_DATA_SIZE + 7) / 8) * 8; -- Round up to nearest multiple of 8

   signal   m_data : std_logic_vector(C_DATA_SIZE - 1 downto 0);
   signal   s_data : std_logic_vector(C_DATA_SIZE - 1 downto 0);

begin

   m_data_o                         <= m_data(G_DATA_SIZE - 1 downto 0);

   s_data(G_DATA_SIZE - 1 downto 0) <= s_data_i;

   i_xpm_fifo_axis : component xpm_fifo_axis
      generic map (
         CDC_SYNC_STAGES     => 2,
         CLOCKING_MODE       => "independent_clock",
         ECC_MODE            => "no_ecc",
         FIFO_DEPTH          => G_DEPTH,
         FIFO_MEMORY_TYPE    => "auto",
         PACKET_FIFO         => "false",
         PROG_EMPTY_THRESH   => 10,
         PROG_FULL_THRESH    => 10,
         RD_DATA_COUNT_WIDTH => 1,
         RELATED_CLOCKS      => 0,
         SIM_ASSERT_CHK      => 0,
         TDATA_WIDTH         => C_DATA_SIZE,
         TDEST_WIDTH         => 1,
         TID_WIDTH           => 1,
         TUSER_WIDTH         => 1,
         USE_ADV_FEATURES    => "1404",
         WR_DATA_COUNT_WIDTH => 1
      )
      port map (
         almost_empty_axis  => open,
         almost_full_axis   => open,
         dbiterr_axis       => open,
         injectdbiterr_axis => '0',
         injectsbiterr_axis => '0',
         m_aclk             => m_clk_i,
         m_axis_tdata       => m_data,
         m_axis_tdest       => open,
         m_axis_tid         => open,
         m_axis_tkeep       => open,
         m_axis_tlast       => open,
         m_axis_tready      => m_ready_i,
         m_axis_tstrb       => open,
         m_axis_tuser       => open,
         m_axis_tvalid      => m_valid_o,
         prog_empty_axis    => open,
         prog_full_axis     => open,
         rd_data_count_axis => open,
         s_aclk             => s_clk_i,
         s_aresetn          => not s_rst_i,
         s_axis_tdata       => s_data,
         s_axis_tdest       => (others => '0'),
         s_axis_tid         => (others => '0'),
         s_axis_tkeep       => (others => '1'),
         s_axis_tlast       => '0',
         s_axis_tready      => s_ready_o,
         s_axis_tstrb       => (others => '0'),
         s_axis_tuser       => (others => '0'),
         s_axis_tvalid      => s_valid_i,
         sbiterr_axis       => open,
         wr_data_count_axis => open
      ); -- i_xpm_fifo_axis

end architecture synthesis;

