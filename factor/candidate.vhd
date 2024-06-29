library ieee;
   use ieee.std_logic_1164.all;
   use ieee.numeric_std_unsigned.all;

-- Example:
-- Inputs (N=4559):
-- * x=1245, p=00001100, s=1
-- * x=  67, p=00001101, s=1
-- * x=1553, p=00000001, s=7, LAST
-- Output:
-- * x=4069, y=490

entity candidate is
   generic (
      G_DATA_SIZE       : integer;
      G_PRIME_ADDR_SIZE : integer;
      G_VECTOR_SIZE     : integer
   );
   port (
      clk_i          : in    std_logic;
      rst_i          : in    std_logic;
      s_ready_o      : out   std_logic;
      s_valid_i      : in    std_logic;
      s_n_i          : in    std_logic_vector(G_DATA_SIZE - 1 downto 0);
      s_x_i          : in    std_logic_vector(G_DATA_SIZE - 1 downto 0);
      s_primes_i     : in    std_logic_vector(G_VECTOR_SIZE - 1 downto 0);
      s_square_i     : in    std_logic_vector(G_DATA_SIZE / 2 - 1 downto 0);
      s_last_i       : in    std_logic;
      m_ready_i      : in    std_logic;
      m_valid_o      : out   std_logic;
      m_x_o          : out   std_logic_vector(G_DATA_SIZE - 1 downto 0);
      m_y_o          : out   std_logic_vector(G_DATA_SIZE - 1 downto 0);
      primes_index_o : out   std_logic_vector(G_PRIME_ADDR_SIZE - 1 downto 0);
      primes_data_i  : in    std_logic_vector(G_DATA_SIZE / 2 - 1 downto 0)
   );
end entity candidate;

architecture synthesis of candidate is

   constant C_HALF_SIZE : natural                               := G_DATA_SIZE / 2;

   constant C_ZERO : std_logic_vector(C_HALF_SIZE - 1 downto 0) := (others => '0');
   constant C_ONE2 : std_logic_vector(G_DATA_SIZE - 1 downto 0) := (0 => '1', others => '0');

   signal   amm_s_ready : std_logic;
   signal   amm_s_valid : std_logic;
   signal   amm_s_val_a : std_logic_vector(G_DATA_SIZE - 1 downto 0);
   signal   amm_s_val_x : std_logic_vector(G_DATA_SIZE - 1 downto 0);
   signal   amm_s_val_b : std_logic_vector(G_DATA_SIZE - 1 downto 0);
   signal   amm_s_val_n : std_logic_vector(G_DATA_SIZE - 1 downto 0);
   signal   amm_m_ready : std_logic;
   signal   amm_m_valid : std_logic;
   signal   amm_m_res   : std_logic_vector(G_DATA_SIZE - 1 downto 0);

   type     state_type is (IDLE_ST, MULT_X_ST, SQUARE_ST, READ_PRIME_ST, MULT_PRIME_ST, WAIT_MULT_PRIME_ST, END_ST);
   signal   state    : state_type;
   signal   s_n      : std_logic_vector(G_DATA_SIZE - 1 downto 0);
   signal   s_x      : std_logic_vector(G_DATA_SIZE - 1 downto 0);
   signal   s_primes : std_logic_vector(G_VECTOR_SIZE - 1 downto 0);
   signal   s_square : std_logic_vector(C_HALF_SIZE - 1 downto 0);
   signal   s_last   : std_logic;

   signal   s_primes_square : std_logic_vector(G_VECTOR_SIZE - 1 downto 0);
   signal   state_primes    : std_logic_vector(G_VECTOR_SIZE - 1 downto 0);
   signal   m_y             : std_logic_vector(G_DATA_SIZE - 1 downto 0);

   signal   primes_index_d : std_logic_vector(G_PRIME_ADDR_SIZE - 1 downto 0);

begin

   s_ready_o   <= '1' when state = IDLE_ST and
                           (amm_s_valid = '0' or amm_s_ready = '1') and
                           (m_valid_o = '0' or m_ready_i = '1') else
                  '0';

   fsm_proc : process (clk_i)
   begin
      if rising_edge(clk_i) then
         if amm_s_ready = '1' then
            amm_s_valid <= '0';
         end if;
         if m_ready_i = '1' then
            m_valid_o <= '0';
         end if;

         case state is

            when IDLE_ST =>
               if s_valid_i = '1' and s_ready_o = '1' then
                  s_primes        <= s_primes_i;
                  s_square        <= s_square_i;
                  s_primes_square <= s_primes_i and state_primes;
                  s_last          <= s_last_i;
                  s_n             <= s_n_i;

                  amm_s_val_a     <= s_x;
                  amm_s_val_x     <= s_x_i;
                  amm_s_val_b     <= (others => '0');
                  amm_s_val_n     <= s_n_i;
                  amm_s_valid     <= '1';
                  state           <= MULT_X_ST;
               end if;

            when MULT_X_ST =>
               if amm_m_valid = '1' then
                  s_x         <= amm_m_res;
                  amm_s_val_a <= C_ZERO & s_square;
                  amm_s_val_x <= m_y;
                  amm_s_val_b <= (others => '0');
                  amm_s_val_n <= s_n;
                  amm_s_valid <= '1';
                  state       <= SQUARE_ST;
               end if;

            when SQUARE_ST =>
               if amm_m_valid = '1' then
                  m_y          <= amm_m_res;
                  state_primes <= state_primes xor s_primes;
                  if or (s_primes_square) = '0' then
                     state <= END_ST;
                  else
                     primes_index_o <= to_stdlogicvector(G_VECTOR_SIZE - 1, G_PRIME_ADDR_SIZE);
                     primes_index_d <= to_stdlogicvector(G_VECTOR_SIZE - 1, G_PRIME_ADDR_SIZE);
                     state          <= READ_PRIME_ST;
                  end if;
               end if;

            when READ_PRIME_ST =>
               if primes_index_o > 0 then
                  primes_index_o <= primes_index_o - 1;
               end if;
               primes_index_d <= primes_index_o;
               state          <= MULT_PRIME_ST;

            when MULT_PRIME_ST =>
               if primes_index_d = 0 then
                  state <= END_ST;
               end if;
               if s_primes_square(to_integer(primes_index_d)) = '1' then
                  amm_s_val_a <= C_ZERO & primes_data_i;
                  amm_s_val_x <= m_y;
                  amm_s_val_b <= (others => '0');
                  amm_s_val_n <= s_n;
                  amm_s_valid <= '1';
                  state       <= WAIT_MULT_PRIME_ST;
               else
                  primes_index_d <= primes_index_o;
                  if primes_index_o > 0 then
                     primes_index_o <= primes_index_o - 1;
                  end if;
               end if;

            when WAIT_MULT_PRIME_ST =>
               if amm_m_valid = '1' then
                  m_y   <= amm_m_res;
                  state <= READ_PRIME_ST;
                  if primes_index_d = 0 then
                     state <= END_ST;
                  end if;
               end if;

            when END_ST =>
               if s_last = '1' then
                  assert state_primes = 0;
                  m_x_o     <= s_x;
                  m_y_o     <= m_y;
                  m_valid_o <= '1';
                  -- Are these next two statements necessary?
                  m_y       <= C_ONE2;
                  s_x       <= C_ONE2;
               end if;
               state <= IDLE_ST;

         end case;

         if rst_i = '1' then
            primes_index_o <= (others => '0');
            m_y            <= C_ONE2;
            s_x            <= C_ONE2;
            state_primes   <= (others => '0');
            amm_s_valid    <= '0';
            m_valid_o      <= '0';
            state          <= IDLE_ST;
         end if;
      end if;
   end process fsm_proc;

   amm_m_ready <= '1';

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

end architecture synthesis;

