library ieee;
   use ieee.std_logic_1164.all;
   use ieee.numeric_std_unsigned.all;

-- This factors a number. Given a number N (which is not prime)
-- it will return a factor D, i.e. N/D is a whole number.

entity factor is
   generic (
      G_DATA_SIZE       : natural;
      G_NUM_WORKERS     : natural;
      G_PRIME_ADDR_SIZE : natural;
      G_VECTOR_SIZE     : natural
   );
   port (
      clk_i     : in    std_logic;
      rst_i     : in    std_logic;
      s_ready_o : out   std_logic;
      s_valid_i : in    std_logic;
      s_data_i  : in    std_logic_vector(G_DATA_SIZE - 1 downto 0);
      m_ready_i : in    std_logic;
      m_valid_o : out   std_logic;
      m_data_o  : out   std_logic_vector(G_DATA_SIZE - 1 downto 0)
   );
end entity factor;

architecture synthesis of factor is

   constant C_DEBUG : boolean         := false;

   signal s_data : std_logic_vector(G_DATA_SIZE - 1 downto 0);

   signal meth_s_ready : std_logic;
   signal meth_s_valid : std_logic;
   signal meth_s_data  : std_logic_vector(8 + G_DATA_SIZE - 1 downto 0);
   signal meth_m_ready : std_logic;
   signal meth_m_valid : std_logic;
   signal meth_m_data  : std_logic_vector(8 + G_DATA_SIZE - 1 downto 0);
   signal meth_m_fail  : std_logic;

   type   state_type is (IDLE_ST, BUSY_ST, GCD_ST);
   signal state : state_type := IDLE_ST;

   signal counter : natural range 0 to 255;

   signal gcd_s_valid : std_logic;
   signal gcd_s_ready : std_logic;
   signal gcd_s_data1 : std_logic_vector(8 + G_DATA_SIZE - 1 downto 0);
   signal gcd_s_data2 : std_logic_vector(8 + G_DATA_SIZE - 1 downto 0);
   signal gcd_m_valid : std_logic;
   signal gcd_m_ready : std_logic;
   signal gcd_m_data  : std_logic_vector(8 + G_DATA_SIZE - 1 downto 0);

begin

   s_ready_o    <= '1' when state = IDLE_ST and (m_valid_o = '0' or m_ready_i = '1') else
                   '0';

   state_proc : process (clk_i)
   begin
      if rising_edge(clk_i) then
         meth_s_valid <= '0';
         if m_ready_i = '1' then
            m_valid_o <= '0';
         end if;
         if gcd_s_ready = '1' then
            gcd_s_valid <= '0';
         end if;

         case state is

            when IDLE_ST =>
               if s_valid_i = '1' and s_ready_o = '1' then
                  if C_DEBUG then
                     report "iteration 1";
                  end if;
                  s_data       <= s_data_i;
                  counter      <= 1;
                  meth_s_valid <= '1';
                  meth_s_data  <= "00000000" & s_data_i;
                  state        <= BUSY_ST;
               end if;

            when BUSY_ST =>
               if meth_m_valid = '1' then
                  if meth_m_fail = '0' then
                     gcd_s_valid <= '1';
                     gcd_s_data1 <= meth_m_data;
                     state       <= GCD_ST;
                  else
                     if C_DEBUG then
                        report "iteration " & to_string(counter + 1);
                     end if;
                     counter      <= counter + 1;
                     meth_s_valid <= '1';
                     meth_s_data  <= meth_s_data + ("00000000" & s_data);
                  end if;
               end if;

            when GCD_ST =>
               if gcd_m_valid = '1' then
                  if gcd_m_data > to_stdlogicvector(counter, 8 + G_DATA_SIZE) and
                     gcd_m_data < "00000000" & s_data then
                     m_data_o  <= gcd_m_data(G_DATA_SIZE - 1 downto 0);
                     m_valid_o <= '1';
                     state     <= IDLE_ST;
                  else
                     if C_DEBUG then
                        report "ignore this value";
                     end if;
                     state <= BUSY_ST;
                  end if;
               end if;

         end case;

         if rst_i = '1' then
            state       <= IDLE_ST;
            gcd_s_valid <= '0';
            m_valid_o   <= '0';
         end if;
      end if;
   end process state_proc;

   meth_m_ready <= gcd_s_ready and m_ready_i;

   method_inst : entity work.method
      generic map (
         G_DATA_SIZE       => 8 + G_DATA_SIZE,
         G_NUM_WORKERS     => G_NUM_WORKERS,
         G_PRIME_ADDR_SIZE => G_PRIME_ADDR_SIZE,
         G_VECTOR_SIZE     => G_VECTOR_SIZE
      )
      port map (
         clk_i     => clk_i,
         rst_i     => rst_i,
         s_ready_o => meth_s_ready,
         s_valid_i => meth_s_valid,
         s_data_i  => meth_s_data,
         m_ready_i => meth_m_ready,
         m_valid_o => meth_m_valid,
         m_data_o  => meth_m_data,
         m_fail_o  => meth_m_fail
      ); -- method_inst

   gcd_s_data2 <= "00000000" & s_data;
   gcd_m_ready <= '1' when state = GCD_ST else
                  '0';

   gcd_inst : entity work.gcd
      generic map (
         G_DATA_SIZE => 8 + G_DATA_SIZE
      )
      port map (
         clk_i     => clk_i,
         rst_i     => rst_i,
         s_valid_i => gcd_s_valid,
         s_ready_o => gcd_s_ready,
         s_data1_i => gcd_s_data1,
         s_data2_i => gcd_s_data2,
         m_valid_o => gcd_m_valid,
         m_ready_i => gcd_m_ready,
         m_data_o  => gcd_m_data
      ); -- gcd_inst

end architecture synthesis;

