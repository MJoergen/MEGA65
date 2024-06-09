library ieee;
   use ieee.std_logic_1164.all;
   use ieee.numeric_std_unsigned.all;

-- Input is a number. Output is a vector of indices into primes with odd powers.

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
      m_data_o     : out   std_logic_vector(G_VECTOR_SIZE - 1 downto 0)
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

   constant C_PRIME_ADDR_SIZE : natural := log2(G_VECTOR_SIZE);
   constant C_EXP_SIZE        : natural := 8;

   signal   primes_index : std_logic_vector(C_PRIME_ADDR_SIZE - 1 downto 0);
   signal   primes_data  : std_logic_vector(G_DATA_SIZE - 1 downto 0);

   signal   divexp_s_ready : std_logic;
   signal   divexp_s_valid : std_logic;
   signal   divexp_s_val_n : std_logic_vector(G_DATA_SIZE - 1 downto 0);
   signal   divexp_s_val_d : std_logic_vector(G_DATA_SIZE - 1 downto 0);
   signal   divexp_m_ready : std_logic;
   signal   divexp_m_valid : std_logic;
   signal   divexp_m_quot  : std_logic_vector(G_DATA_SIZE - 1 downto 0);
   signal   divexp_m_exp   : std_logic_vector(C_EXP_SIZE - 1 downto 0);

   type     state_type is (IDLE_ST, READ_PRIME_ST, DIVEXP_ST, WAIT_ST);
   signal   state  : state_type;
   signal   s_data : std_logic_vector(G_DATA_SIZE - 1 downto 0);

   signal   m_data : std_logic_vector(G_VECTOR_SIZE - 1 downto 0);

begin

   s_ready_o <= '1' when state = IDLE_ST else
                '0';

   m_data_o <= m_data when m_valid_o = '1' else (others => '0');

   state_proc : process (clk_i)
   begin
      if rising_edge(clk_i) then
         divexp_s_valid <= '0';
         if m_ready_i = '1' then
            m_valid_o <= '0';
         end if;

         case state is

            when IDLE_ST =>
               if s_valid_i = '1' and s_ready_o = '1' then
                  m_data       <= (others => '0');
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
               state          <= WAIT_ST;

            when WAIT_ST =>
               if divexp_m_valid = '1' then
                  if and (divexp_m_exp) = '1' then
                     m_complete_o <= '0';
                     m_valid_o    <= '1';
                     state        <= IDLE_ST;
                  else
                     s_data                           <= divexp_m_quot;
                     m_data(to_integer(primes_index)) <= divexp_m_exp(0);
                     if divexp_m_quot = 1 then
                        m_complete_o <= '1';
                        m_valid_o    <= '1';
                        state        <= IDLE_ST;
                     elsif and (primes_index) = '1' then
                        m_complete_o <= '0';
                        m_valid_o    <= '1';
                        state        <= IDLE_ST;
                     else
                        primes_index <= primes_index + 1;
                        state        <= READ_PRIME_ST;
                     end if;
                  end if;
               end if;

         end case;

         if rst_i = '1' then
            m_valid_o <= '0';
            state     <= IDLE_ST;
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

   divexp_m_ready <= m_ready_i;

   divexp_inst : entity work.divexp
      generic map (
         G_DATA_SIZE => G_DATA_SIZE,
         G_EXP_SIZE  => C_EXP_SIZE
      )
      port map (
         clk_i     => clk_i,
         rst_i     => rst_i,
         s_ready_o => divexp_s_ready,
         s_valid_i => divexp_s_valid,
         s_val_n_i => divexp_s_val_n,
         s_val_d_i => divexp_s_val_d,
         m_ready_i => divexp_m_ready,
         m_valid_o => divexp_m_valid,
         m_quot_o  => divexp_m_quot,
         m_exp_o   => divexp_m_exp
      ); -- divexp_inst

end architecture synthesis;

