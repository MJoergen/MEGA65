library ieee;
   use ieee.std_logic_1164.all;
   use ieee.numeric_std_unsigned.all;

entity stat_latency is
   generic (
      G_COUNTER_SIZE : natural
   );
   port (
      clk_i      : in    std_logic;
      rst_i      : in    std_logic;
      s_ready_i  : in    std_logic;
      s_valid_i  : in    std_logic;
      m_ready_i  : in    std_logic;
      m_valid_i  : in    std_logic;
      st_count_o : out   std_logic_vector(G_COUNTER_SIZE - 1 downto 0);
      st_valid_o : out   std_logic
   );
end entity stat_latency;

architecture synthesis of stat_latency is

   signal   counter : std_logic_vector(G_COUNTER_SIZE - 1 downto 0);

   constant C_AFS_RAM_WIDTH : natural := G_COUNTER_SIZE;
   constant C_AFS_RAM_DEPTH : natural := 16;

   signal   afs_s_ready : std_logic;
   signal   afs_s_valid : std_logic;
   signal   afs_s_data  : std_logic_vector(C_AFS_RAM_WIDTH - 1 downto 0);
   signal   afs_m_ready : std_logic;
   signal   afs_m_valid : std_logic;
   signal   afs_m_data  : std_logic_vector(C_AFS_RAM_WIDTH - 1 downto 0);

begin

   counter_proc : process (clk_i)
   begin
      if rising_edge(clk_i) then
         counter <= counter + 1;

         if rst_i = '1' then
            counter <= (others => '0');
         end if;
      end if;
   end process counter_proc;

   afs_s_valid <= s_ready_i and s_valid_i;
   afs_s_data  <= counter;

   axi_fifo_small_inst : entity work.axi_fifo_small
      generic map (
         G_RAM_WIDTH => C_AFS_RAM_WIDTH,
         G_RAM_DEPTH => C_AFS_RAM_DEPTH
      )
      port map (
         clk_i     => clk_i,
         rst_i     => rst_i,
         s_ready_o => afs_s_ready, -- ignore
         s_valid_i => afs_s_valid,
         s_data_i  => afs_s_data,
         m_ready_i => afs_m_ready,
         m_valid_o => afs_m_valid,
         m_data_o  => afs_m_data
      ); -- axi_fifo_small_inst

   afs_m_ready <= m_ready_i and m_valid_i;

   afs_proc : process (clk_i)
   begin
      if rising_edge(clk_i) then
         st_valid_o <= '0';
         if m_ready_i = '1' and m_valid_i = '1' then
            assert afs_m_valid = '1';
            st_valid_o <= '1';
            st_count_o <= counter - afs_m_data;
         end if;
      end if;
   end process afs_proc;

end architecture synthesis;

