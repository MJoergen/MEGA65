library ieee;
   use ieee.std_logic_1164.all;
   use ieee.numeric_std_unsigned.all;

entity stat_wait is
   generic (
      G_COUNTER_SIZE : natural
   );
   port (
      clk_i         : in    std_logic;
      rst_i         : in    std_logic;
      ready_i       : in    std_logic;
      valid_i       : in    std_logic;
      st_count_00_o : out   std_logic_vector(G_COUNTER_SIZE - 1 downto 0);
      st_count_01_o : out   std_logic_vector(G_COUNTER_SIZE - 1 downto 0);
      st_count_10_o : out   std_logic_vector(G_COUNTER_SIZE - 1 downto 0);
      st_count_11_o : out   std_logic_vector(G_COUNTER_SIZE - 1 downto 0);
      st_valid_o    : out   std_logic
   );
end entity stat_wait;

architecture synthesis of stat_wait is

   signal counter_00  : std_logic_vector(G_COUNTER_SIZE - 1 downto 0);
   signal counter_01  : std_logic_vector(G_COUNTER_SIZE - 1 downto 0);
   signal counter_10  : std_logic_vector(G_COUNTER_SIZE - 1 downto 0);
   signal counter_11  : std_logic_vector(G_COUNTER_SIZE - 1 downto 0);
   signal counter_tot : std_logic_vector(G_COUNTER_SIZE - 1 downto 0);

begin

   counter_proc : process (clk_i)
      variable new_counter_00_v : std_logic_vector(G_COUNTER_SIZE - 1 downto 0);
      variable new_counter_01_v : std_logic_vector(G_COUNTER_SIZE - 1 downto 0);
      variable new_counter_10_v : std_logic_vector(G_COUNTER_SIZE - 1 downto 0);
      variable new_counter_11_v : std_logic_vector(G_COUNTER_SIZE - 1 downto 0);
   begin
      if rising_edge(clk_i) then
         st_valid_o       <= '0';

         counter_tot      <= counter_tot + 1;

         new_counter_00_v := counter_00;
         new_counter_01_v := counter_01;
         new_counter_10_v := counter_10;
         new_counter_11_v := counter_11;

         case ready_i & valid_i is

            when "00" =>
               new_counter_00_v := counter_00 + 1;

            when "01" =>
               new_counter_01_v := counter_01 + 1;

            when "10" =>
               new_counter_10_v := counter_10 + 1;

            when "11" =>
               new_counter_11_v := counter_11 + 1;

            when others =>
               null;

         end case;

         counter_00 <= new_counter_00_v;
         counter_01 <= new_counter_01_v;
         counter_10 <= new_counter_10_v;
         counter_11 <= new_counter_11_v;

         if (counter_tot + 2) = 0 then
            st_count_00_o <= new_counter_00_v;
            st_count_01_o <= new_counter_01_v;
            st_count_10_o <= new_counter_10_v;
            st_count_11_o <= new_counter_11_v;
            counter_tot   <= (others => '0');
            counter_00    <= (others => '0');
            counter_01    <= (others => '0');
            counter_10    <= (others => '0');
            counter_11    <= (others => '0');
            st_valid_o    <= '1';
         end if;

         if rst_i = '1' then
            counter_tot <= (others => '0');
            counter_00  <= (others => '0');
            counter_01  <= (others => '0');
            counter_10  <= (others => '0');
            counter_11  <= (others => '0');
         end if;
      end if;
   end process counter_proc;

end architecture synthesis;

