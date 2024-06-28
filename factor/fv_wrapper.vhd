library ieee;
   use ieee.std_logic_1164.all;
   use ieee.numeric_std_unsigned.all;

entity fv_wrapper is
   generic (
      G_NUM_WORKERS     : natural;
      G_PRIME_ADDR_SIZE : natural;
      G_DATA_SIZE       : natural;
      G_VECTOR_SIZE     : natural; -- Number of primes to attempt trial division
      G_USER_SIZE       : natural
   );
   port (
      clk_i        : in    std_logic;
      rst_i        : in    std_logic;
      s_ready_o    : out   std_logic;
      s_valid_i    : in    std_logic;
      s_data_i     : in    std_logic_vector(G_DATA_SIZE - 1 downto 0);
      s_user_i     : in    std_logic_vector(G_USER_SIZE - 1 downto 0);
      m_ready_i    : in    std_logic;
      m_valid_o    : out   std_logic;
      m_complete_o : out   std_logic;
      m_square_o   : out   std_logic_vector(G_DATA_SIZE - 1 downto 0);
      m_primes_o   : out   std_logic_vector(G_VECTOR_SIZE - 1 downto 0);
      m_user_o     : out   std_logic_vector(G_USER_SIZE - 1 downto 0)
   );
end entity fv_wrapper;

architecture synthesis of fv_wrapper is

   signal  fv_s_index : natural range 0 to G_NUM_WORKERS - 1;
   signal  fv_m_index : natural range 0 to G_NUM_WORKERS - 1;
   signal  fv_fill    : natural range 0 to G_NUM_WORKERS;

   subtype DATA_TYPE is std_logic_vector(G_DATA_SIZE - 1 downto 0);
   subtype VECTOR_TYPE is std_logic_vector(G_VECTOR_SIZE - 1 downto 0);
   subtype USER_TYPE is std_logic_vector(G_USER_SIZE - 1 downto 0);
   subtype PRIME_ADDR_TYPE is std_logic_vector(G_PRIME_ADDR_SIZE - 1 downto 0);

   type    data_vector_type is array (natural range <>) of DATA_TYPE;

   type    vector_vector_type is array (natural range <>) of VECTOR_TYPE;

   type    user_vector_type is array (natural range <>) of USER_TYPE;

   type    prime_addr_vector_type is array (natural range <>) of PRIME_ADDR_TYPE;


   signal  s_ready    : std_logic_vector(G_NUM_WORKERS - 1 downto 0);
   signal  s_valid    : std_logic_vector(G_NUM_WORKERS - 1 downto 0);
   signal  s_data     : data_vector_type(G_NUM_WORKERS - 1 downto 0);
   signal  s_user     : user_vector_type(G_NUM_WORKERS - 1 downto 0);
   signal  m_ready    : std_logic_vector(G_NUM_WORKERS - 1 downto 0);
   signal  m_valid    : std_logic_vector(G_NUM_WORKERS - 1 downto 0);
   signal  m_complete : std_logic_vector(G_NUM_WORKERS - 1 downto 0);
   signal  m_square   : data_vector_type(G_NUM_WORKERS - 1 downto 0);
   signal  m_primes   : vector_vector_type(G_NUM_WORKERS - 1 downto 0);
   signal  m_user     : user_vector_type(G_NUM_WORKERS - 1 downto 0);

   signal  primes_index : prime_addr_vector_type(G_NUM_WORKERS - 1 downto 0);
   signal  primes_data  : data_vector_type(G_NUM_WORKERS - 1 downto 0);

begin

   s_ready_o <= s_ready(fv_s_index);

   s_valid_proc : process (all)
   begin
      s_valid <= (others => '0');
      s_data  <= (others => (others => '0'));
      s_user  <= (others => (others => '0'));

      if s_valid_i = '1' then
         s_valid(fv_s_index) <= s_valid_i;
         s_data(fv_s_index)  <= s_data_i;
         s_user(fv_s_index)  <= s_user_i;
      end if;
   end process s_valid_proc;

   fv_s_index_proc : process (clk_i)
   begin
      if rising_edge(clk_i) then
         if s_ready_o = '1' and s_valid_i = '1' then
            if fv_s_index < G_NUM_WORKERS - 1 then
               fv_s_index <= fv_s_index + 1;
            else
               fv_s_index <= 0;
            end if;
         end if;

         if rst_i = '1' then
            fv_s_index <= 0;
         end if;
      end if;
   end process fv_s_index_proc;

   factor_vect_gen : for i in 0 to G_NUM_WORKERS - 1 generate

      factor_vect_inst : entity work.factor_vect
         generic map (
            G_PRIME_ADDR_SIZE => G_PRIME_ADDR_SIZE,
            G_DATA_SIZE       => G_DATA_SIZE,
            G_VECTOR_SIZE     => G_VECTOR_SIZE,
            G_USER_SIZE       => G_USER_SIZE
         )
         port map (
            clk_i          => clk_i,
            rst_i          => rst_i,
            s_ready_o      => s_ready(i),
            s_valid_i      => s_valid(i),
            s_data_i       => s_data(i),
            s_user_i       => s_user(i),
            m_ready_i      => m_ready(i),
            m_valid_o      => m_valid(i),
            m_complete_o   => m_complete(i),
            m_square_o     => m_square(i),
            m_primes_o     => m_primes(i),
            m_user_o       => m_user(i),
            primes_index_o => primes_index(i),
            primes_data_i  => primes_data(i)
         ); -- factor_vect_inst

      fv_primes_inst : entity work.primes
         generic map (
            G_ADDR_SIZE => G_PRIME_ADDR_SIZE,
            G_DATA_SIZE => G_DATA_SIZE
         )
         port map (
            clk_i   => clk_i,
            rst_i   => rst_i,
            index_i => primes_index(i),
            data_o  => primes_data(i)
         ); -- fv_primes_inst

   end generate factor_vect_gen;

   m_ready_proc : process (all)
   begin
      m_ready             <= (others => '0');
      m_ready(fv_m_index) <= m_ready_i;
   end process m_ready_proc;

   m_valid_o    <= m_valid(fv_m_index);
   m_complete_o <= m_complete(fv_m_index);
   m_square_o   <= m_square(fv_m_index);
   m_primes_o   <= m_primes(fv_m_index);
   m_user_o     <= m_user(fv_m_index);

   fv_m_index_proc : process (clk_i)
   begin
      if rising_edge(clk_i) then
         if m_ready_i = '1' and m_valid_o = '1' then
            if fv_m_index < G_NUM_WORKERS - 1 then
               fv_m_index <= fv_m_index + 1;
            else
               fv_m_index <= 0;
            end if;
         end if;

         if rst_i = '1' then
            fv_m_index <= 0;
         end if;
      end if;
   end process fv_m_index_proc;

   fv_fill_proc : process (clk_i)
   begin
      if rising_edge(clk_i) then
         if (s_ready_o = '1' and s_valid_i = '1') and
            not (m_ready_i = '1' and m_valid_o = '1') then
            assert fv_fill < G_NUM_WORKERS;
            fv_fill <= fv_fill + 1;
         end if;

         if not (s_ready_o = '1' and s_valid_i = '1') and
            (m_ready_i = '1' and m_valid_o = '1') then
            assert fv_fill > 0;
            fv_fill <= fv_fill - 1;
         end if;

         if rst_i = '1' then
            fv_fill <= 0;
         end if;
      end if;
   end process fv_fill_proc;

end architecture synthesis;

