library ieee;
   use ieee.std_logic_1164.all;
   use ieee.numeric_std_unsigned.all;

-- This factors a number, using the Continued Fraction method
-- Example using N = 2059.
-- The CF method generates a sequence of values (x,p,w) satisfiying
-- x^2 = p*w mod N,
-- and |w| = 1 and p is "small".
-- Since p is small, we can factor it using brute force. Example
-- 91^2 = 45 = 3^2 * 5
-- 136^2 = -35 = -1 * 5 * 7
-- 363^2 = -7 = -1 * 7
-- Multiplying these three relations together gives
-- (91*136*363)^2 = (3*5*7)^2 mod N
-- Take the difference and calculate the gcd:
-- gcd(91*136*363 - 3*5*7, N) = 71, which is a factor of N.

entity factor is
   generic (
      G_DATA_SIZE   : integer;
      G_VECTOR_SIZE : integer
   );
   port (
      clk_i      : in    std_logic;
      rst_i      : in    std_logic;
      s_start_i  : in    std_logic;
      s_val_i    : in    std_logic_vector(2 * G_DATA_SIZE - 1 downto 0);
      m_ready_i  : in    std_logic;
      m_valid_o  : out   std_logic;
      m_number_o : out   std_logic_vector(2 * G_DATA_SIZE - 1 downto 0);
      m_square_o : out   std_logic_vector(G_DATA_SIZE - 1 downto 0);
      m_primes_o : out   std_logic_vector(G_VECTOR_SIZE - 1 downto 0);
      m_parity_o : out   std_logic
   );
end entity factor;

architecture synthesis of factor is

   signal cf_s_start : std_logic;
   signal cf_s_val   : std_logic_vector(2 * G_DATA_SIZE - 1 downto 0);
   signal cf_m_ready : std_logic;
   signal cf_m_valid : std_logic;
   signal cf_m_res_x : std_logic_vector(2 * G_DATA_SIZE - 1 downto 0);
   signal cf_m_res_p : std_logic_vector(G_DATA_SIZE - 1 downto 0);
   signal cf_m_res_w : std_logic;

   signal fv_s_ready    : std_logic;
   signal fv_s_valid    : std_logic;
   signal fv_s_data     : std_logic_vector(G_DATA_SIZE - 1 downto 0);
   signal fv_m_ready    : std_logic;
   signal fv_m_valid    : std_logic;
   signal fv_m_complete : std_logic;
   signal fv_m_square   : std_logic_vector(G_DATA_SIZE - 1 downto 0);
   signal fv_m_primes   : std_logic_vector(G_VECTOR_SIZE - 1 downto 0);

   signal fv_s_number : std_logic_vector(2 * G_DATA_SIZE - 1 downto 0);
   signal fv_s_parity : std_logic;

begin

   cf_s_start <= s_start_i;
   cf_s_val   <= s_val_i;

   ---------------------------------------------------------------
   -- The CF method generates a sequence of values (x,p,w)
   -- satisfiying x^2 = p*w mod N, where p is "small" and |w| = 1
   --
   -- Example: N = 2059 gives the following sequence of values:
   -- (45, 34, 1)
   -- (91, 45, 0)
   -- (136, 35, 1)
   -- (227, 54, 0)
   -- etc
   ---------------------------------------------------------------
   cf_inst : entity work.cf
      generic map (
         G_DATA_SIZE => G_DATA_SIZE
      )
      port map (
         clk_i     => clk_i,
         rst_i     => rst_i,
         s_start_i => cf_s_start,
         s_val_i   => cf_s_val,
         m_ready_i => cf_m_ready,
         m_valid_o => cf_m_valid,
         m_res_x_o => cf_m_res_x,
         m_res_p_o => cf_m_res_p,
         m_res_w_o => cf_m_res_w
      ); -- cf_inst

   cf_debug_proc : process (clk_i)
   begin
      if rising_edge(clk_i) then
         if cf_m_valid = '1' and cf_m_ready = '1' then
            report "x=" & to_string(to_integer(cf_m_res_x)) &
                   ", p=" & to_string(to_integer(cf_m_res_p)) &
                   ", w=" & to_string(cf_m_res_w);
         end if;
      end if;
   end process cf_debug_proc;


   fv_s_valid <= cf_m_valid;
   fv_s_data  <= cf_m_res_p;
   cf_m_ready <= fv_s_ready;

   factor_vect_inst : entity work.factor_vect
      generic map (
         G_DATA_SIZE   => G_DATA_SIZE,
         G_VECTOR_SIZE => G_VECTOR_SIZE
      )
      port map (
         clk_i        => clk_i,
         rst_i        => rst_i,
         s_ready_o    => fv_s_ready,
         s_valid_i    => fv_s_valid,
         s_data_i     => fv_s_data,
         m_ready_i    => fv_m_ready,
         m_valid_o    => fv_m_valid,
         m_complete_o => fv_m_complete,
         m_square_o   => fv_m_square,
         m_primes_o   => fv_m_primes
      ); -- factor_vect_inst

   fv_debug_proc : process (clk_i)
   begin
      if rising_edge(clk_i) then
         if fv_m_valid = '1' and fv_m_complete = '1' and fv_m_ready = '1' then
            report "square=" & to_string(to_integer(fv_m_square)) &
                   ", primes=" & to_hstring(fv_m_primes);
         end if;
      end if;
   end process fv_debug_proc;


   number_proc : process (clk_i)
   begin
      if rising_edge(clk_i) then
         if cf_m_valid = '1' and cf_m_ready = '1' then
            fv_s_number <= cf_m_res_x;
            fv_s_parity <= cf_m_res_w;
         end if;
      end if;
   end process number_proc;

   m_number_o <= fv_s_number;
   m_primes_o <= fv_m_primes;
   m_square_o <= fv_m_square;
   m_parity_o <= fv_s_parity;
   m_valid_o  <= fv_m_valid and fv_m_complete;
   fv_m_ready <= m_ready_i;

end architecture synthesis;

