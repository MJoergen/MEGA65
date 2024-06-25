library ieee;
   use ieee.std_logic_1164.all;
   use ieee.numeric_std_unsigned.all;

entity stat is
   generic (
      G_DATA_SIZE     : natural;
      G_FRACTION_SIZE : natural
   );
   port (
      clk_i     : in    std_logic;
      rst_i     : in    std_logic;
      s_data_i  : in    std_logic_vector(G_DATA_SIZE - 1 downto 0);
      s_valid_i : in    std_logic;
      m_count_o : out   std_logic_vector(G_DATA_SIZE - 1 downto 0);
      m_min_o   : out   std_logic_vector(G_DATA_SIZE - 1 downto 0);
      m_max_o   : out   std_logic_vector(G_DATA_SIZE - 1 downto 0);
      m_mean_o  : out   std_logic_vector(G_DATA_SIZE - 1 downto 0)
   );
end entity stat;

architecture synthesis of stat is

   signal   stat_count : std_logic_vector(G_DATA_SIZE - 1 downto 0);
   signal   stat_min   : std_logic_vector(G_DATA_SIZE - 1 downto 0);
   signal   stat_max   : std_logic_vector(G_DATA_SIZE - 1 downto 0);
   signal   stat_mean  : std_logic_vector(G_DATA_SIZE + G_FRACTION_SIZE - 1 downto 0);
   signal   first      : std_logic;

   signal   diff   : std_logic_vector(G_DATA_SIZE + G_FRACTION_SIZE - 1 downto 0);
   constant C_ZERO : std_logic_vector(G_FRACTION_SIZE - 1 downto 0) := (others => '0');

   pure function sign_extend (
      arg : std_logic_vector;
      bits : natural
   ) return std_logic_vector is
      variable res_v : std_logic_vector(arg'length + bits - 1 downto 0);
   begin
      res_v                          := (others => arg(arg'left));
      res_v(arg'length - 1 downto 0) := arg;
      return res_v;
   end function sign_extend;

begin

   m_count_o <= stat_count;
   m_min_o   <= stat_min;
   m_max_o   <= stat_max;
   m_mean_o  <= stat_mean(G_DATA_SIZE + G_FRACTION_SIZE - 1 downto G_FRACTION_SIZE);

   diff      <= (s_data_i & C_ZERO) - stat_mean;

   stat_proc : process (clk_i)
   begin
      if rising_edge(clk_i) then
         if s_valid_i = '1' then
            if first = '1' then
               stat_count <= (others => '0');
               stat_min   <= s_data_i;
               stat_max   <= s_data_i;
               stat_mean  <= s_data_i & C_ZERO;
               first      <= '0';
            else
               stat_count <= stat_count + 1;
               if s_data_i < stat_min then
                  stat_min <= s_data_i;
               end if;
               if s_data_i > stat_max then
                  stat_max <= s_data_i;
               end if;
               stat_mean <= stat_mean + sign_extend(diff(G_DATA_SIZE + G_FRACTION_SIZE - 1 downto G_FRACTION_SIZE), G_FRACTION_SIZE);
            end if;
         end if;

         if rst_i = '1' then
            stat_count <= (others => '0');
            stat_min   <= (others => '0');
            stat_max   <= (others => '0');
            stat_mean  <= (others => '0');
            first      <= '1';
         end if;
      end if;
   end process stat_proc;

end architecture synthesis;

