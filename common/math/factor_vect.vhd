library ieee;
   use ieee.std_logic_1164.all;
   use ieee.numeric_std_unsigned.all;

-- Input is a number. Output is a vector of indices into primes with odd powers.
-- Example: The number 90 = 2 * 3^2 * 5 gets translated to the pair
-- (3, "00000101").

entity factor_vect is
   generic (
      G_DATA_SIZE   : integer;
      G_VECTOR_SIZE : integer -- Number of primes to attempt trial division
   );
   port (
      clk_i        : in    std_logic;
      rst_i        : in    std_logic;
      s_ready_o    : out   std_logic;
      s_valid_i    : in    std_logic;
      s_data_i     : in    std_logic_vector(G_DATA_SIZE - 1 downto 0);
      m_ready_i    : in    std_logic;
      m_valid_o    : out   std_logic;
      m_complete_o : out   std_logic;
      m_square_o   : out   std_logic_vector(G_DATA_SIZE - 1 downto 0);
      m_primes_o   : out   std_logic_vector(G_VECTOR_SIZE - 1 downto 0)
   );
end entity factor_vect;

architecture synthesis of factor_vect is

   pure function log2 (
      arg : natural
   ) return natural is
   begin
      --
      for i in 0 to arg loop
         if (2 ** i) >= arg then
            return i;
         end if;
      end loop;

      return -1;
   end function log2;

   constant C_ZERO2           : std_logic_vector(2 * G_DATA_SIZE - 1 downto 0) := (others => '0');
   constant C_ONE             : std_logic_vector(G_DATA_SIZE - 1 downto 0)     := (0 => '1', others => '0');
   constant C_PRIME_ADDR_SIZE : natural                                        := log2(G_VECTOR_SIZE);

   signal   primes_index : std_logic_vector(C_PRIME_ADDR_SIZE - 1 downto 0);
   signal   primes_data  : std_logic_vector(G_DATA_SIZE - 1 downto 0);

   signal   divexp_s_ready  : std_logic;
   signal   divexp_s_valid  : std_logic;
   signal   divexp_s_val_n  : std_logic_vector(G_DATA_SIZE - 1 downto 0);
   signal   divexp_s_val_d  : std_logic_vector(G_DATA_SIZE - 1 downto 0);
   signal   divexp_m_ready  : std_logic;
   signal   divexp_m_valid  : std_logic;
   signal   divexp_m_quot   : std_logic_vector(G_DATA_SIZE - 1 downto 0);
   signal   divexp_m_square : std_logic_vector(G_DATA_SIZE - 1 downto 0);
   signal   divexp_m_exp    : std_logic;

   signal   am_s_ready : std_logic;
   signal   am_s_valid : std_logic;
   signal   am_s_val_a : std_logic_vector(G_DATA_SIZE - 1 downto 0);
   signal   am_s_val_x : std_logic_vector(G_DATA_SIZE - 1 downto 0);
   signal   am_s_val_b : std_logic_vector(2 * G_DATA_SIZE - 1 downto 0);
   signal   am_m_ready : std_logic;
   signal   am_m_valid : std_logic;
   signal   am_m_res   : std_logic_vector(2 * G_DATA_SIZE - 1 downto 0);

   type     state_type is (IDLE_ST, READ_PRIME_ST, DIVEXP_ST, AM_ST, WAIT_IDLE_ST, WAIT_PRIME_ST);
   signal   state  : state_type;
   signal   s_data : std_logic_vector(G_DATA_SIZE - 1 downto 0);

   signal   m_square : std_logic_vector(G_DATA_SIZE - 1 downto 0);
   signal   m_primes : std_logic_vector(G_VECTOR_SIZE - 1 downto 0);

begin

   s_ready_o  <= '1' when state = IDLE_ST else
                 '0';

   m_square_o <= m_square when m_valid_o = '1' else
                 (others => '0');
   m_primes_o <= m_primes when m_valid_o = '1' else
                 (others => '0');

   state_proc : process (clk_i)
   begin
      if rising_edge(clk_i) then
         if divexp_s_ready = '1' then
            divexp_s_valid <= '0';
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
                  m_square     <= C_ONE;
                  m_primes     <= (others => '0');
                  s_data       <= s_data_i;
                  primes_index <= (others => '0');
                  state        <= READ_PRIME_ST;
               end if;

            when READ_PRIME_ST =>
               state <= DIVEXP_ST;

            when DIVEXP_ST =>
               divexp_s_val_n <= s_data;
               divexp_s_val_d <= primes_data;
               divexp_s_valid <= '1';
               state          <= AM_ST;

            when AM_ST =>
               if divexp_m_valid = '1' then
                  s_data                             <= divexp_m_quot;
                  m_primes(to_integer(primes_index)) <= divexp_m_exp;

                  am_s_val_a                         <= m_square;
                  am_s_val_x                         <= divexp_m_square;
                  am_s_val_b                         <= C_ZERO2;
                  am_s_valid                         <= '1';

                  if divexp_m_quot = 1 then
                     m_complete_o <= '1';
                     state        <= WAIT_IDLE_ST;
                  elsif and (primes_index) = '1' then
                     m_complete_o <= '0';
                     state        <= WAIT_IDLE_ST;
                  else
                     primes_index <= primes_index + 1;
                     state        <= WAIT_PRIME_ST;
                  end if;
               end if;

            when WAIT_IDLE_ST =>
               if am_m_valid = '1' then
                  m_square  <= am_m_res(G_DATA_SIZE - 1 downto 0);
                  m_valid_o <= '1';
                  state     <= IDLE_ST;
               end if;

            when WAIT_PRIME_ST =>
               if am_m_valid = '1' then
                  m_square <= am_m_res(G_DATA_SIZE - 1 downto 0);
                  state    <= DIVEXP_ST;
               end if;

         end case;

         if rst_i = '1' then
            divexp_s_valid <= '0';
            am_s_valid     <= '0';
            m_valid_o      <= '0';
            state          <= IDLE_ST;
         end if;
      end if;
   end process state_proc;

   primes_inst : entity work.primes
      generic map (
         G_ADDR_SIZE => C_PRIME_ADDR_SIZE,
         G_DATA_SIZE => G_DATA_SIZE
      )
      port map (
         clk_i   => clk_i,
         rst_i   => rst_i,
         index_i => primes_index,
         data_o  => primes_data
      ); -- primes_inst

   divexp_m_ready <= '1' when state = AM_ST else '0';

   am_m_ready     <= '1' when state = WAIT_IDLE_ST or state = WAIT_PRIME_ST else '0';

   divexp_inst : entity work.divexp
      generic map (
         G_DATA_SIZE => G_DATA_SIZE
      )
      port map (
         clk_i      => clk_i,
         rst_i      => rst_i,
         s_ready_o  => divexp_s_ready,
         s_valid_i  => divexp_s_valid,
         s_val_n_i  => divexp_s_val_n,
         s_val_d_i  => divexp_s_val_d,
         m_ready_i  => divexp_m_ready,
         m_valid_o  => divexp_m_valid,
         m_quot_o   => divexp_m_quot,
         m_square_o => divexp_m_square,
         m_exp_o    => divexp_m_exp
      ); -- divexp_inst

   add_mult_inst : entity work.add_mult
      generic map (
         G_DATA_SIZE => G_DATA_SIZE
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

