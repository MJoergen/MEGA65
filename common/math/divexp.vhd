library ieee;
   use ieee.std_logic_1164.all;
   use ieee.numeric_std_unsigned.all;

-- This calculates the largest power "res" of "d" that divides "n".
-- In other words, on return, n mod d^res = 0 and n mod d^(res+1) /= 0.

-- Given a number N and a prime p, this module performs the following factorization:
-- N = q * (p^d)^2 * p^e
-- and returns q, (p^d), and e.

entity divexp is
   generic (
      G_DATA_SIZE : integer
   );
   port (
      clk_i      : in    std_logic;
      rst_i      : in    std_logic;
      s_ready_o  : out   std_logic;
      s_valid_i  : in    std_logic;
      s_val_n_i  : in    std_logic_vector(G_DATA_SIZE - 1 downto 0);
      s_val_d_i  : in    std_logic_vector(G_DATA_SIZE - 1 downto 0);
      m_ready_i  : in    std_logic;
      m_valid_o  : out   std_logic;
      m_quot_o   : out   std_logic_vector(G_DATA_SIZE - 1 downto 0);
      m_square_o : out   std_logic_vector(G_DATA_SIZE - 1 downto 0);
      m_exp_o    : out   std_logic
   );
end entity divexp;

architecture synthesis of divexp is

   constant C_ZERO  : std_logic_vector(G_DATA_SIZE - 1 downto 0)     := (others => '0');
   constant C_ZERO2 : std_logic_vector(2 * G_DATA_SIZE - 1 downto 0) := (others => '0');
   constant C_ONE   : std_logic_vector(G_DATA_SIZE - 1 downto 0)     := (0 => '1', others => '0');

   signal   dm_s_ready : std_logic;
   signal   dm_s_valid : std_logic;
   signal   dm_s_val_n : std_logic_vector(G_DATA_SIZE - 1 downto 0);
   signal   dm_s_val_d : std_logic_vector(G_DATA_SIZE - 1 downto 0);
   signal   dm_m_ready : std_logic;
   signal   dm_m_valid : std_logic;
   signal   dm_m_res_q : std_logic_vector(G_DATA_SIZE - 1 downto 0);
   signal   dm_m_res_r : std_logic_vector(G_DATA_SIZE - 1 downto 0);

   signal   am_s_ready : std_logic;
   signal   am_s_valid : std_logic;
   signal   am_s_val_a : std_logic_vector(G_DATA_SIZE - 1 downto 0);
   signal   am_s_val_x : std_logic_vector(G_DATA_SIZE - 1 downto 0);
   signal   am_s_val_b : std_logic_vector(2 * G_DATA_SIZE - 1 downto 0);
   signal   am_m_ready : std_logic;
   signal   am_m_valid : std_logic;
   signal   am_m_res   : std_logic_vector(2 * G_DATA_SIZE - 1 downto 0);

   type     state_type is (IDLE_ST, BUSY_ST);
   signal   state : state_type;

begin

   s_ready_o  <= '1' when state = IDLE_ST and (m_valid_o = '0' or m_ready_i = '1') else
                 '0';

   -- Make sure both outputs are consumed simultaneously
   dm_m_ready <= am_m_valid or not am_s_valid;
   am_m_ready <= dm_m_valid;

   fsm_proc : process (clk_i)
   begin
      if rising_edge(clk_i) then
         if dm_s_ready = '1' then
            dm_s_valid <= '0';
         end if;
         if am_s_ready = '1' then
            am_s_valid <= '0';
         end if;

         if m_ready_i = '1' then
            m_valid_o <= '0';
         end if;

         case state is

            when IDLE_ST =>
               if s_valid_i = '1' and s_ready_o = '1' then
                  -- Prepare division N/D
                  dm_s_val_n <= s_val_n_i;
                  dm_s_val_d <= s_val_d_i;
                  dm_s_valid <= '1';
                  -- Prepare multiplication Q*D
                  am_s_val_a <= C_ONE;
                  am_s_val_x <= s_val_d_i;
                  am_s_val_b <= C_ZERO2;
                  am_s_valid <= '1';
                  -- Setup initial values
                  m_quot_o   <= s_val_n_i;
                  m_square_o <= C_ONE;
                  m_exp_o    <= '0';
                  state      <= BUSY_ST;
               end if;

            when BUSY_ST =>
               if dm_m_valid = '1' and (am_m_valid = '1' or am_s_valid = '0') then
                  if dm_m_res_r /= C_ZERO then
                     m_valid_o <= '1';
                     state     <= IDLE_ST;
                  else
                     -- Prepare next division
                     dm_s_val_n <= dm_m_res_q;
                     dm_s_valid <= '1';
                     -- Prepare next multiplication
                     if m_exp_o = '1' then
                        m_square_o <= am_m_res(G_DATA_SIZE - 1 downto 0);
                        am_s_val_a <= am_m_res(G_DATA_SIZE - 1 downto 0);
                        am_s_valid <= '1';
                     end if;
                     -- Update output values
                     m_quot_o   <= dm_m_res_q;
                     m_exp_o    <= not m_exp_o;
                  end if;
               end if;

         end case;

         if rst_i = '1' then
            dm_s_valid <= '0';
            am_s_valid <= '0';
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

   add_mult_inst : entity work.add_mult
      generic map (
         G_DATA_SIZE => G_DATA_SIZE*2
      )
      port map (
         clk_i     => clk_i,
         rst_i     => rst_i,
         s_ready_o => am_s_ready,
         s_valid_i => am_s_valid,
         s_val_a_i => am_s_val_a,
         s_val_x_i => am_s_val_x,
         s_val_b_i => am_s_val_b,
         m_ready_i => am_m_ready,
         m_valid_o => am_m_valid,
         m_res_o   => am_m_res
      ); -- add_mult_inst

end architecture synthesis;

