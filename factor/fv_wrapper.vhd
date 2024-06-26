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
      clk_i          : in    std_logic;
      rst_i          : in    std_logic;
      s_ready_o      : out   std_logic;
      s_valid_i      : in    std_logic;
      s_data_i       : in    std_logic_vector(G_DATA_SIZE - 1 downto 0);
      s_user_i       : in    std_logic_vector(G_USER_SIZE - 1 downto 0);
      m_ready_i      : in    std_logic;
      m_valid_o      : out   std_logic;
      m_complete_o   : out   std_logic;
      m_square_o     : out   std_logic_vector(G_DATA_SIZE - 1 downto 0);
      m_primes_o     : out   std_logic_vector(G_VECTOR_SIZE - 1 downto 0);
      m_user_o       : out   std_logic_vector(G_USER_SIZE - 1 downto 0);
      primes_index_o : out   std_logic_vector(G_PRIME_ADDR_SIZE - 1 downto 0);
      primes_data_i  : in    std_logic_vector(G_DATA_SIZE - 1 downto 0)
   );
end entity fv_wrapper;

architecture synthesis of fv_wrapper is

   signal fv_s_index : natural range 0 to G_NUM_WORKERS - 1;
   signal fv_m_index : natural range 0 to G_NUM_WORKERS - 1;

   type   fv_type is record
      s_ready      : std_logic;
      s_valid      : std_logic;
      s_data       : std_logic_vector(G_DATA_SIZE - 1 downto 0);
      s_user       : std_logic_vector(G_USER_SIZE - 1 downto 0);
      m_ready      : std_logic;
      m_valid      : std_logic;
      m_complete   : std_logic;
      m_square     : std_logic_vector(G_DATA_SIZE - 1 downto 0);
      m_primes     : std_logic_vector(G_VECTOR_SIZE - 1 downto 0);
      m_user       : std_logic_vector(G_USER_SIZE - 1 downto 0);
      primes_index : std_logic_vector(G_PRIME_ADDR_SIZE - 1 downto 0);
      primes_data  : std_logic_vector(G_DATA_SIZE - 1 downto 0);
   end record fv_type;

   type   fv_vector_type is array (natural range <>) of fv_type;
   signal fv_vector : fv_vector_type(0 to G_NUM_WORKERS - 1);

begin

   s_ready_o                     <= fv_vector(fv_s_index).s_ready;
   fv_vector(fv_s_index).s_valid <= s_valid_i;
   fv_vector(fv_s_index).s_data  <= s_data_i;
   fv_vector(fv_s_index).s_user  <= s_user_i;

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
            G_USER_SIZE       => C_FV_USER_SIZE
         )
         port map (
            clk_i          => clk_i,
            rst_i          => rst_i,
            s_ready_o      => fv_vector(i).s_ready,
            s_valid_i      => fv_vector(i).s_valid,
            s_data_i       => fv_vector(i).s_data,
            s_user_i       => fv_vector(i).s_user,
            m_ready_i      => fv_vector(i).m_ready,
            m_valid_o      => fv_vector(i).m_valid,
            m_complete_o   => fv_vector(i).m_complete,
            m_square_o     => fv_vector(i).m_square,
            m_primes_o     => fv_vector(i).m_primes,
            m_user_o       => fv_vector(i).m_user,
            primes_index_o => fv_vector(i).primes_index,
            primes_data_i  => fv_vector(i).primes_data
         ); -- factor_vect_inst

      fv_primes_inst : entity work.primes
         generic map (
            G_ADDR_SIZE => G_PRIME_ADDR_SIZE,
            G_DATA_SIZE => G_DATA_SIZE
         )
         port map (
            clk_i   => clk_i,
            rst_i   => rst_i,
            index_i => fv_primes_index(i),
            data_o  => fv_primes_data(i)
         ); -- fv_primes_inst

   end generate factor_vect_gen;

   fv_vector(fv_m_index).m_ready <= m_ready_i;
   m_valid_o                     <= fv_vector(fv_m_index).m_valid;
   m_complete_o                  <= fv_vector(fv_m_index).m_complete;
   m_square_o                    <= fv_vector(fv_m_index).m_square;
   m_primes_o                    <= fv_vector(fv_m_index).m_primes;
   m_user_o                      <= fv_vector(fv_m_index).m_user;

   fv_m_index_proc : process (clk_i)
   begin
      if rising_edge(clk_i) then
         if m_ready_o = '1' and m_valid_i = '1' then
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

end architecture synthesis;

