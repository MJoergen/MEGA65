library ieee;
   use ieee.std_logic_1164.all;
   use ieee.numeric_std_unsigned.all;

-- This module performs the Continued Fraction calculations.  Once initialized
-- with the integer N, it will repeatedly output values X and Y, such that
-- 1) X^2 = Y mod N.
-- 2) |Y|<2*sqrt(N).
-- In other words, the number of bits in Y is approximately half that of X and N.
-- The value of Y is represented as a sign bit in W and an absolute value in P.

-- Specifically, this module calculates a recurrence relation with the
-- following initialiazation:
-- p_0 = 1
-- r_0 = 0
-- x_0 = 1
-- p_1 = N - M*M
-- s_1 = 2*M
-- w_1 = -1
-- x_1 = M,
-- and then for each n>=2:
-- 1) a_n = s_n/p_n
-- 2) r_n = s_n-a_n*p_n
-- 3) s_(n+1) = 2*M - r\_n
-- 4) p_(n+1) = a_n (r_n - r_(n-1)) + p_(n-1)
-- 5) w_(n+1) = - w_n
-- 6) x_(n+1) = a_n x_n + x_(n-1) mod N
-- Steps 1 and 2 in the recurrence are performed simultaneously using the divmod module.
-- Steps 4 and 6 are performed simultaneously using the add_mult and amm modules.

entity cf is
   generic (
      G_DATA_SIZE : integer
   );
   port (
      clk_i     : in    std_logic;
      rst_i     : in    std_logic;
      s_start_i : in    std_logic;
      s_val_i   : in    std_logic_vector(2 * G_DATA_SIZE - 1 downto 0); -- N
      m_ready_i : in    std_logic;
      m_valid_o : out   std_logic;
      m_res_x_o : out   std_logic_vector(2 * G_DATA_SIZE - 1 downto 0); -- X
      m_res_p_o : out   std_logic_vector(G_DATA_SIZE - 1 downto 0);     -- |Y|
      m_res_w_o : out   std_logic                                  -- sign(Y)
   );
end entity cf;

architecture synthesis of cf is

   constant C_ZERO : std_logic_vector(G_DATA_SIZE - 1 downto 0) := (others => '0');
   constant C_ONE  : std_logic_vector(G_DATA_SIZE - 1 downto 0) := to_stdlogicvector(1, G_DATA_SIZE);

   -- State variables
   type     state_type is (IDLE_ST, SQRT_ST, CALC_AR_ST, CALC_XP_ST);
   signal   state : state_type;

   signal   val_n     : std_logic_vector(2 * G_DATA_SIZE - 1 downto 0);
   signal   val_2root : std_logic_vector(G_DATA_SIZE - 1 downto 0);

   signal   p_prev : std_logic_vector(G_DATA_SIZE - 1 downto 0);
   signal   r_prev : std_logic_vector(G_DATA_SIZE - 1 downto 0);
   signal   x_prev : std_logic_vector(2 * G_DATA_SIZE - 1 downto 0);

   signal   p_cur : std_logic_vector(G_DATA_SIZE - 1 downto 0);
   signal   s_cur : std_logic_vector(G_DATA_SIZE - 1 downto 0);
   signal   w_cur : std_logic;
   signal   x_cur : std_logic_vector(2 * G_DATA_SIZE - 1 downto 0);

   signal   a_cur : std_logic_vector(G_DATA_SIZE - 1 downto 0);
   signal   r_cur : std_logic_vector(G_DATA_SIZE - 1 downto 0);

   signal   p_new : std_logic_vector(G_DATA_SIZE - 1 downto 0);
   signal   s_new : std_logic_vector(G_DATA_SIZE - 1 downto 0);
   signal   w_new : std_logic;
   signal   x_new : std_logic_vector(2 * G_DATA_SIZE - 1 downto 0);

   -- Signals connected to SQRT module
   signal   sqrt_s_ready : std_logic;
   signal   sqrt_s_valid : std_logic;
   signal   sqrt_s_data  : std_logic_vector(2 * G_DATA_SIZE - 1 downto 0);
   signal   sqrt_m_ready : std_logic;
   signal   sqrt_m_valid : std_logic;
   signal   sqrt_m_res   : std_logic_vector(G_DATA_SIZE - 1 downto 0);
   signal   sqrt_m_diff  : std_logic_vector(G_DATA_SIZE     downto 0);

   -- Signals connected to DIVMOD module
   signal   divmod_s_ready : std_logic;
   signal   divmod_s_valid : std_logic;
   signal   divmod_s_val_n : std_logic_vector(G_DATA_SIZE - 1 downto 0);
   signal   divmod_s_val_d : std_logic_vector(G_DATA_SIZE - 1 downto 0);
   signal   divmod_m_ready : std_logic;
   signal   divmod_m_valid : std_logic;
   signal   divmod_m_res_q : std_logic_vector(G_DATA_SIZE - 1 downto 0);
   signal   divmod_m_res_r : std_logic_vector(G_DATA_SIZE - 1 downto 0);

   -- Signals connected to AMM module
   signal   amm_s_ready : std_logic;
   signal   amm_s_valid : std_logic;
   signal   amm_s_val_a : std_logic_vector(G_DATA_SIZE - 1 downto 0);
   signal   amm_s_val_x : std_logic_vector(2 * G_DATA_SIZE - 1 downto 0);
   signal   amm_s_val_b : std_logic_vector(2 * G_DATA_SIZE - 1 downto 0);
   signal   amm_s_val_n : std_logic_vector(2 * G_DATA_SIZE - 1 downto 0);
   signal   amm_m_ready : std_logic;
   signal   amm_m_valid : std_logic;
   signal   amm_m_res   : std_logic_vector(2 * G_DATA_SIZE - 1 downto 0);

   -- Signals connected to ADD-MULT module
   signal   add_mult_s_ready : std_logic;
   signal   add_mult_s_valid : std_logic;
   signal   add_mult_s_val_a : std_logic_vector(G_DATA_SIZE - 1 downto 0);
   signal   add_mult_s_val_x : std_logic_vector(G_DATA_SIZE - 1 downto 0);
   signal   add_mult_s_val_b : std_logic_vector(2 * G_DATA_SIZE - 1 downto 0);
   signal   add_mult_m_ready : std_logic;
   signal   add_mult_m_valid : std_logic;
   signal   add_mult_m_res   : std_logic_vector(2 * G_DATA_SIZE - 1 downto 0);

   -- Output signals
   signal   res_x : std_logic_vector(2 * G_DATA_SIZE - 1 downto 0);
   signal   res_p : std_logic_vector(G_DATA_SIZE - 1 downto 0);
   signal   res_w : std_logic;

begin

   fsm_proc : process (clk_i)
   begin
      if rising_edge(clk_i) then
         if m_ready_i = '1' then
            m_valid_o <= '0';
         end if;

         -- Set default values
         res_x            <= C_ZERO & C_ZERO;
         res_p            <= C_ZERO;
         res_w            <= '0';

         sqrt_s_valid     <= '0';
         divmod_s_valid   <= '0';
         amm_s_valid      <= '0';
         add_mult_s_valid <= '0';

         case state is

            when IDLE_ST =>
               null;

            when SQRT_ST =>
               -- Wait until data is ready
               if sqrt_s_valid = '0' and sqrt_m_valid = '1' then
                  assert (divmod_s_ready = '1' and amm_s_ready = '1' and add_mult_s_ready = '1') or rst_i = '1';
                  -- Store input values
                  val_2root      <= sqrt_m_res(G_DATA_SIZE - 2 downto 0) & '0';

                  -- Let: p_0 = 1, r_0 = 0, x_0 = 1.
                  p_prev         <= C_ONE;
                  r_prev         <= C_ZERO;
                  x_prev         <= C_ZERO & C_ONE;

                  -- Let: p_1 = N - M*M, s_1 = 2*M, w_1 = -1, x_1 = M.
                  p_cur          <= sqrt_m_diff(G_DATA_SIZE - 1 downto 0);
                  s_cur          <= sqrt_m_res(G_DATA_SIZE - 2 downto 0) & '0';
                  w_cur          <= '1';
                  x_cur          <= C_ZERO & sqrt_m_res;

                  -- Store output values
                  m_valid_o      <= '1';

                  -- Start calculating a_n and p_n.
                  divmod_s_valid <= '1';
                  state          <= CALC_AR_ST;
               end if;

            when CALC_AR_ST =>
               if divmod_s_valid = '0' and divmod_m_valid = '1' then
                  -- Store new values of a_n and r_n
                  a_cur            <= divmod_m_res_q;
                  r_cur            <= divmod_m_res_r;

                  -- Start calculating x_(n+1) and p_(n+1).
                  amm_s_valid      <= '1';
                  add_mult_s_valid <= '1';
                  state            <= CALC_XP_ST;
               end if;

            when CALC_XP_ST =>
               if amm_s_valid = '0' and amm_m_valid = '1' and add_mult_s_valid = '0' and
               add_mult_m_valid = '1' and (m_ready_i = '1' or m_valid_o = '0') then
                  -- Update recursion
                  s_cur          <= s_new;
                  p_cur          <= p_new;
                  w_cur          <= w_new;
                  x_cur          <= x_new;

                  p_prev         <= p_cur;
                  r_prev         <= r_cur;
                  x_prev         <= x_cur;

                  -- Store output values
                  m_valid_o      <= '1';

                  -- Start calculating a_n and p_n.
                  divmod_s_valid <= '1';
                  state          <= CALC_AR_ST;
               end if;

         end case;

         -- A start command should be processed from any state
         if s_start_i = '1' then
            m_valid_o    <= '0';
            val_n        <= s_val_i;
            sqrt_s_valid <= '1';
            state        <= SQRT_ST;

            if s_val_i = 0 then
               sqrt_s_valid <= '0';
               state        <= IDLE_ST;
            end if;
         end if;

         if rst_i = '1' then
            m_valid_o    <= '0';
            sqrt_s_valid <= '0';
            state        <= SQRT_ST;
         end if;
      end if;
   end process fsm_proc;

   -- Calculate M=floor(sqrt(N)).
   sqrt_s_data      <= val_n;

   -- Calculate a_n = s_n/p_n and r_n = s_n-a_n*p_n.
   divmod_s_val_n   <= s_cur;
   divmod_s_val_d   <= p_cur;

   -- Calculate x_(n+1) = (a_n * x_n + x_(n-1)) mod N.
   amm_s_val_a      <= a_cur;
   amm_s_val_x      <= x_cur;
   amm_s_val_b      <= x_prev;
   amm_s_val_n      <= val_n;
   x_new            <= amm_m_res;

   -- Calculate p_(n+1) = p_(n-1) + a_n*[r_n - r_(n-1)].
   add_mult_s_val_a <= a_cur;
   add_mult_s_val_x <= r_cur - r_prev;
   add_mult_s_val_b <= C_ZERO & p_prev;
   p_new            <= add_mult_m_res(G_DATA_SIZE - 1 downto 0);

   -- Calculate s_(n+1) = 2*M - r_n.
   s_new            <= val_2root - r_cur;

   -- Calculate w_(n+1) = - w_n.
   w_new            <= not w_cur;


   --------------------
   -- Instantiate SQRT
   --------------------

   sqrt_m_ready     <= m_ready_i or not m_valid_o;

   sqrt_inst : entity work.sqrt
      generic map (
         G_DATA_SIZE => G_DATA_SIZE
      )
      port map (
         clk_i     => clk_i,
         rst_i     => rst_i,
         s_ready_o => sqrt_s_ready,
         s_valid_i => sqrt_s_valid,
         s_data_i  => sqrt_s_data,
         m_ready_i => sqrt_m_ready,
         m_valid_o => sqrt_m_valid,
         m_res_o   => sqrt_m_res,
         m_diff_o  => sqrt_m_diff
      ); -- sqrt_inst


   ----------------------
   -- Instantiate DIVMOD
   ----------------------

   divmod_m_ready <= m_ready_i or not m_valid_o;

   divmod_inst : entity work.divmod
      generic map (
         G_DATA_SIZE => G_DATA_SIZE
      )
      port map (
         clk_i     => clk_i,
         rst_i     => rst_i,
         s_ready_o => divmod_s_ready,
         s_valid_i => divmod_s_valid,
         s_val_n_i => divmod_s_val_n,
         s_val_d_i => divmod_s_val_d,
         m_ready_i => divmod_m_ready,
         m_valid_o => divmod_m_valid,
         m_res_q_o => divmod_m_res_q,
         m_res_r_o => divmod_m_res_r
      ); -- divmod_inst


   ----------------------
   -- Instantiate AMM
   ----------------------

   amm_m_ready <= m_ready_i or not m_valid_o;

   amm_inst : entity work.amm
      generic map (
         G_DATA_SIZE => G_DATA_SIZE
      )
      port map (
         clk_i     => clk_i,
         rst_i     => rst_i,
         s_ready_o => amm_s_ready,
         s_valid_i => amm_s_valid,
         s_val_a_i => amm_s_val_a,
         s_val_x_i => amm_s_val_x,
         s_val_b_i => amm_s_val_b,
         s_val_n_i => amm_s_val_n,
         m_ready_i => amm_m_ready,
         m_valid_o => amm_m_valid,
         m_res_o   => amm_m_res
      ); -- amm_inst


   ------------------------
   -- Instantiate ADD_MULT
   ------------------------

   add_mult_m_ready <= m_ready_i or not m_valid_o;

   add_mult_inst : entity work.add_mult
      generic map (
         G_DATA_SIZE => G_DATA_SIZE
      )
      port map (
         clk_i     => clk_i,
         rst_i     => rst_i,
         s_ready_o => add_mult_s_ready,
         s_valid_i => add_mult_s_valid,
         s_val_a_i => add_mult_s_val_a,
         s_val_x_i => add_mult_s_val_x,
         s_val_b_i => add_mult_s_val_b,
         m_ready_i => add_mult_m_ready,
         m_valid_o => add_mult_m_valid,
         m_res_o   => add_mult_m_res
      ); -- add_mult_inst


   --------------------------
   -- Connect output signals
   --------------------------

   m_res_x_o <= x_cur;
   m_res_p_o <= p_cur;
   m_res_w_o <= w_cur;

end architecture synthesis;

