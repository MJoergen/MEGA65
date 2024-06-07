library ieee;
   use ieee.std_logic_1164.all;
   use ieee.numeric_std_unsigned.all;

-- This calculates the largest power "res" of "d" that divides "n".
-- In other words, on return, n mod d^res = 0 and n mod d^(res+1) /= 0.

entity divexp is
   generic (
      G_DATA_SIZE : integer
   );
   port (
      clk_i     : in    std_logic;
      rst_i     : in    std_logic;
      s_ready_o : out   std_logic;
      s_valid_i : in    std_logic;
      s_val_n_i : in    std_logic_vector(G_DATA_SIZE - 1 downto 0);
      s_val_d_i : in    std_logic_vector(G_DATA_SIZE - 1 downto 0);
      m_ready_i : in    std_logic;
      m_valid_o : out   std_logic;
      m_res_o   : out   std_logic_vector(G_DATA_SIZE - 1 downto 0)
   );
end entity divexp;

architecture synthesis of divexp is

   constant C_ZERO : std_logic_vector(G_DATA_SIZE - 1 downto 0) := (others => '0');

   signal   dm_s_ready : std_logic;
   signal   dm_s_valid : std_logic;
   signal   dm_s_val_n : std_logic_vector(G_DATA_SIZE - 1 downto 0);
   signal   dm_s_val_d : std_logic_vector(G_DATA_SIZE - 1 downto 0);
   signal   dm_m_ready : std_logic;
   signal   dm_m_valid : std_logic;
   signal   dm_m_res_q : std_logic_vector(G_DATA_SIZE - 1 downto 0);
   signal   dm_m_res_r : std_logic_vector(G_DATA_SIZE - 1 downto 0);

   signal   m_res : std_logic_vector(G_DATA_SIZE - 1 downto 0);

   type     state_type is (IDLE_ST, BUSY_ST);
   signal   state : state_type;

begin

   s_ready_o  <= '1' when state = IDLE_ST and (m_valid_o = '0' or m_ready_i = '1') else
                 '0';

   dm_m_ready <= '1';

   fsm_proc : process (clk_i)
   begin
      if rising_edge(clk_i) then
         dm_s_valid <= '0';

         if m_ready_i = '1' then
            m_valid_o <= '0';
         end if;

         case state is

            when IDLE_ST =>
               if s_valid_i = '1' and s_ready_o = '1' then
                  dm_s_val_n <= s_val_n_i;
                  dm_s_val_d <= s_val_d_i;
                  dm_s_valid <= '1';
                  m_res      <= (others => '0');
                  state      <= BUSY_ST;
               end if;

            when BUSY_ST =>
               if dm_m_valid = '1' then
                  if dm_m_res_r /= C_ZERO then
                     m_res_o   <= m_res;
                     m_valid_o <= '1';
                     state     <= IDLE_ST;
                  else
                     dm_s_val_n <= dm_m_res_q;
                     dm_s_valid <= '1';
                     m_res      <= m_res + 1;
                  end if;
               end if;

         end case;

         if rst_i = '1' then
            dm_s_valid <= '0';
            m_valid_o  <= '0';
            state      <= IDLE_ST;
         end if;
      end if;
   end process fsm_proc;

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
         m_res_q_o => dm_m_res_q,
         m_res_r_o => dm_m_res_r
      ); -- divmod_inst

end architecture synthesis;

