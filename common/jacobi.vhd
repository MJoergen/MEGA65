library ieee;
   use ieee.std_logic_1164.all;
   use ieee.numeric_std_unsigned.all;

-- This module calculates the Jacobi Symbol using the algorithm described in
-- https://en.wikipedia.org/wiki/Jacobi_symbol#Calculating_the_Jacobi_symbol
--
-- function Jacobi(n,k)
--    assert(k > 0 and k % 2 == 1)
--    n = n % k
--    t = 1
--    while n ~= 0 do
--       while n % 2 == 0 do
--          n = n / 2
--          r = k % 8
--          if r == 3 or r == 5 then
--             t = -t
--          end
--       end
--       n, k = k, n
--       if n % 4 == k % 4 == 3 then
--          t = -t
--       end
--       n = n % k
--    end
--    if k == 1 then
--       return t
--    else
--       return 0
--    end
-- end
--
-- Examples:
-- (19/45)     =  1,
-- (8/21)      = -1,
-- (5/21)      =  1,
-- (1001/9907) = -1,
-- (30/7)      =  1,
-- (30/11)     = -1,
-- (30/13)     =  1

entity jacobi is
   generic (
      G_DATA_SIZE : integer
   );
   port (
      clk_i     : in    std_logic;
      rst_i     : in    std_logic;
      s_ready_o : out   std_logic;
      s_valid_i : in    std_logic;
      s_val_n_i : in    std_logic_vector(G_DATA_SIZE - 1 downto 0);
      s_val_k_i : in    std_logic_vector(G_DATA_SIZE - 1 downto 0);
      m_ready_i : in    std_logic;
      m_valid_o : out   std_logic;
      m_res_o   : out   std_logic_vector(1 downto 0)
   );
end entity jacobi;

architecture synthesis of jacobi is

   constant C_ZERO : std_logic_vector(G_DATA_SIZE - 1 downto 0) := (others => '0');
   constant C_ONE  : std_logic_vector(G_DATA_SIZE - 1 downto 0) := to_stdlogicvector(1, G_DATA_SIZE);

   type     state_type is (IDLE_ST, DIVMOD_ST, REDUCE_ST, DONE_ST);
   signal   state : state_type;

   signal   dm_s_ready : std_logic;
   signal   dm_s_valid : std_logic;
   signal   dm_s_val_n : std_logic_vector(G_DATA_SIZE - 1 downto 0);
   signal   dm_s_val_d : std_logic_vector(G_DATA_SIZE - 1 downto 0);
   signal   dm_m_ready : std_logic;
   signal   dm_m_valid : std_logic;
   signal   dm_m_res_r : std_logic_vector(G_DATA_SIZE - 1 downto 0);

   signal   val_n : std_logic_vector(G_DATA_SIZE - 1 downto 0);
   signal   val_k : std_logic_vector(G_DATA_SIZE - 1 downto 0);

   signal   res : std_logic_vector(1 downto 0);

begin

   -- Connect output signals
   m_res_o    <= res;
   s_ready_o  <= '1' when state = IDLE_ST and (m_valid_o = '0' or m_ready_i = '1') else
                 '0';

   dm_m_ready <= '1';
   dm_s_val_n <= val_n;
   dm_s_val_d <= val_k;

   divmod_inst : entity work.divmod
      generic map (
         G_DATA_SIZE => G_DATA_SIZE
      )
      port map (
         clk_i     => clk_i,
         rst_i     => rst_i,
         s_ready_o => dm_s_ready,
         s_valid_i => dm_s_valid,
         s_val_n_i => dm_s_val_n,
         s_val_d_i => dm_s_val_d,
         m_ready_i => dm_m_ready,
         m_valid_o => dm_m_valid,
         m_res_q_o => open,  -- Not used
         m_res_r_o => dm_m_res_r
      ); -- divmod_inst

   fsm_proc : process (clk_i)
   begin
      if rising_edge(clk_i) then
         if m_ready_i = '1' then
            m_valid_o <= '0';
         end if;

         -- Set default values
         dm_s_valid <= '0';

         case state is

            when IDLE_ST =>
               if s_valid_i = '1' and s_ready_o = '1' then
                  val_n      <= s_val_n_i;
                  val_k      <= s_val_k_i;
                  res        <= "01";
                  m_valid_o  <= '0';

                  dm_s_valid <= '1';
                  state      <= DIVMOD_ST;
               end if;

            when DIVMOD_ST =>
               if dm_s_valid = '0' and dm_m_valid = '1' then
                  val_n <= dm_m_res_r;
                  state <= REDUCE_ST;

                  if dm_m_res_r = 0 then
                     if dm_s_val_d /= 1 then
                        res <= "00";
                     end if;
                     state <= DONE_ST;
                  end if;
               end if;

            when REDUCE_ST =>
               if val_n(0) = '0' then
                  val_n <= '0' & val_n(G_DATA_SIZE - 1 downto 1);

                  if val_k(2 downto 0) = 3 or val_k(2 downto 0) = 5 then
                     res(1) <= not res(1);
                  end if;
               else
                  if val_n(1 downto 0) = 3 and val_k(1 downto 0) = 3 then
                     res(1) <= not res(1);
                  end if;
                  val_n      <= val_k;
                  val_k      <= val_n;
                  dm_s_valid <= '1';
                  state      <= DIVMOD_ST;
               end if;

            when DONE_ST =>
               m_valid_o <= '1';
               state     <= IDLE_ST;

         end case;

         if rst_i = '1' then
            m_valid_o  <= '0';
            dm_s_valid <= '0';
            state      <= IDLE_ST;
         end if;
      end if;
   end process fsm_proc;

end architecture synthesis;

