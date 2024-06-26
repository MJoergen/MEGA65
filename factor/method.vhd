library ieee;
   use ieee.std_logic_1164.all;
   use ieee.numeric_std_unsigned.all;

-- This factors a number, using the Continued Fraction method
-- Example using N = 2059.
-- The CF method generates a sequence of values (x,p,w) satisfiying
-- x^2 = p*w mod N,
-- and |w| = 1 and p is "small".
-- Since p is small, we can factor it using brute force. Example
--  91^2 =  45 = 3^2 * 5
-- 136^2 = -35 = -1 * 5 * 7
-- 363^2 =  -7 = -1 * 7
-- Multiplying these three relations together gives
-- (91*136*363)^2 = (3*5*7)^2 mod N
-- Take the difference and calculate the gcd:
-- gcd(91*136*363 - 3*5*7, N) = 71, which is a factor of N.

entity method is
   generic (
      G_DATA_SIZE       : natural;
      G_NUM_WORKERS     : natural;
      G_PRIME_ADDR_SIZE : natural;
      G_VECTOR_SIZE     : natural
   );
   port (
      clk_i     : in    std_logic;
      rst_i     : in    std_logic;
      s_ready_o : out   std_logic;
      s_valid_i : in    std_logic;
      s_data_i  : in    std_logic_vector(G_DATA_SIZE - 1 downto 0);
      m_ready_i : in    std_logic;
      m_valid_o : out   std_logic;
      m_data_o  : out   std_logic_vector(G_DATA_SIZE - 1 downto 0);
      m_fail_o  : out   std_logic
   );
end entity method;

architecture synthesis of method is

   constant C_DEBUG     : boolean         := false;
   constant C_HALF_SIZE : natural         := G_DATA_SIZE / 2;

   signal   cf_s_ready : std_logic;
   signal   cf_s_valid : std_logic;
   signal   cf_s_data  : std_logic_vector(G_DATA_SIZE - 1 downto 0);
   signal   cf_m_ready : std_logic;
   signal   cf_m_valid : std_logic;
   signal   cf_m_res_x : std_logic_vector(G_DATA_SIZE - 1 downto 0);
   signal   cf_m_res_p : std_logic_vector(C_HALF_SIZE - 1 downto 0);
   signal   cf_m_res_w : std_logic;

   signal   fv_s_ready    : std_logic;
   signal   fv_s_valid    : std_logic;
   signal   fv_s_data     : std_logic_vector(C_HALF_SIZE - 1 downto 0);
   signal   fv_s_user     : std_logic_vector(G_DATA_SIZE downto 0);
   signal   fv_m_ready    : std_logic;
   signal   fv_m_valid    : std_logic;
   signal   fv_m_complete : std_logic;
   signal   fv_m_square   : std_logic_vector(C_HALF_SIZE - 1 downto 0);
   signal   fv_m_primes   : std_logic_vector(G_VECTOR_SIZE - 1 downto 0);
   signal   fv_m_user     : std_logic_vector(G_DATA_SIZE downto 0);

   subtype  R_FV_USER_X is natural range G_DATA_SIZE - 1 downto 0;
   subtype  R_FV_USER_W is natural range G_DATA_SIZE downto G_DATA_SIZE;
   constant C_FV_USER_SIZE : natural      := G_DATA_SIZE + 1;

   constant C_AFS_FV_DATA_SIZE : natural  := 1 + C_HALF_SIZE + G_VECTOR_SIZE + G_DATA_SIZE + 1;
   constant C_AFS_FV_DEPTH     : natural  := 64;
   signal   afs_fv_s_ready     : std_logic;
   signal   afs_fv_s_valid     : std_logic;
   signal   afs_fv_s_data      : std_logic_vector(C_AFS_FV_DATA_SIZE - 1 downto 0);
   signal   afs_fv_s_fill      : natural range 0 to C_AFS_FV_DEPTH - 1;
   signal   afs_fv_m_ready     : std_logic;
   signal   afs_fv_m_valid     : std_logic;
   signal   afs_fv_m_data      : std_logic_vector(C_AFS_FV_DATA_SIZE - 1 downto 0);
   signal   afs_fv_m_complete  : std_logic;
   signal   afs_fv_m_square    : std_logic_vector(C_HALF_SIZE - 1 downto 0);
   signal   afs_fv_m_primes    : std_logic_vector(G_VECTOR_SIZE - 1 downto 0);
   signal   afs_fv_m_user      : std_logic_vector(G_DATA_SIZE downto 0);

   signal   gf2_s_ready : std_logic;
   signal   gf2_s_valid : std_logic;
   signal   gf2_s_row   : std_logic_vector(G_VECTOR_SIZE downto 0);
   signal   gf2_s_user  : std_logic_vector(G_DATA_SIZE + C_HALF_SIZE + G_VECTOR_SIZE - 1 downto 0);
   signal   gf2_m_ready : std_logic;
   signal   gf2_m_valid : std_logic;
   signal   gf2_m_user  : std_logic_vector(G_DATA_SIZE + C_HALF_SIZE + G_VECTOR_SIZE - 1 downto 0);
   signal   gf2_m_last  : std_logic;

   subtype  R_GF2_USER_X      is natural range G_DATA_SIZE - 1 downto 0;
   subtype  R_GF2_USER_PRIMES is natural range G_DATA_SIZE + G_VECTOR_SIZE - 1 downto G_DATA_SIZE;
   subtype  R_GF2_USER_SQUARE is natural range G_DATA_SIZE + C_HALF_SIZE + G_VECTOR_SIZE - 1 downto G_DATA_SIZE + G_VECTOR_SIZE;
   constant C_GF2_USER_SIZE : natural     := G_DATA_SIZE + C_HALF_SIZE + G_VECTOR_SIZE;

   constant C_AFS_GF2_DATA_SIZE : natural := 1 + C_GF2_USER_SIZE;
   constant C_AFS_GF2_DEPTH     : natural := 64;
   signal   afs_gf2_s_ready     : std_logic;
   signal   afs_gf2_s_valid     : std_logic;
   signal   afs_gf2_s_data      : std_logic_vector(C_AFS_GF2_DATA_SIZE - 1 downto 0);
   signal   afs_gf2_s_fill      : natural range 0 to C_AFS_GF2_DEPTH - 1;
   signal   afs_gf2_m_ready     : std_logic;
   signal   afs_gf2_m_valid     : std_logic;
   signal   afs_gf2_m_data      : std_logic_vector(C_AFS_GF2_DATA_SIZE - 1 downto 0);
   signal   afs_gf2_m_user      : std_logic_vector(C_GF2_USER_SIZE - 1 downto 0);
   signal   afs_gf2_m_last      : std_logic;

   signal   cand_s_ready      : std_logic;
   signal   cand_s_valid      : std_logic;
   signal   cand_s_n          : std_logic_vector(G_DATA_SIZE - 1 downto 0);
   signal   cand_s_x          : std_logic_vector(G_DATA_SIZE - 1 downto 0);
   signal   cand_s_primes     : std_logic_vector(G_VECTOR_SIZE - 1 downto 0);
   signal   cand_s_square     : std_logic_vector(C_HALF_SIZE - 1 downto 0);
   signal   cand_s_last       : std_logic;
   signal   cand_m_ready      : std_logic;
   signal   cand_m_valid      : std_logic;
   signal   cand_m_x          : std_logic_vector(G_DATA_SIZE - 1 downto 0);
   signal   cand_m_y          : std_logic_vector(G_DATA_SIZE - 1 downto 0);
   signal   cand_primes_index : std_logic_vector(G_PRIME_ADDR_SIZE - 1 downto 0);
   signal   cand_primes_data  : std_logic_vector(C_HALF_SIZE - 1 downto 0);

   signal   gcd_s_valid : std_logic;
   signal   gcd_s_ready : std_logic;
   signal   gcd_s_data1 : std_logic_vector(G_DATA_SIZE downto 0);
   signal   gcd_s_data2 : std_logic_vector(G_DATA_SIZE downto 0);
   signal   gcd_m_valid : std_logic;
   signal   gcd_m_ready : std_logic;
   signal   gcd_m_data  : std_logic_vector(G_DATA_SIZE downto 0);

   signal   factor_val : std_logic_vector(G_DATA_SIZE - 1 downto 0);

   constant C_COUNTER_SIZE : natural      := 16;
   signal   fv_st_count    : std_logic_vector(C_COUNTER_SIZE - 1 downto 0);
   signal   fv_st_valid    : std_logic;
   signal   stat_count     : std_logic_vector(C_COUNTER_SIZE - 1 downto 0);
   signal   stat_min       : std_logic_vector(C_COUNTER_SIZE - 1 downto 0);
   signal   stat_max       : std_logic_vector(C_COUNTER_SIZE - 1 downto 0);
   signal   stat_mean      : std_logic_vector(C_COUNTER_SIZE - 1 downto 0);

   signal   fv_s_st_count_00 : std_logic_vector(C_COUNTER_SIZE - 1 downto 0);
   signal   fv_s_st_count_01 : std_logic_vector(C_COUNTER_SIZE - 1 downto 0);
   signal   fv_s_st_count_10 : std_logic_vector(C_COUNTER_SIZE - 1 downto 0);
   signal   fv_s_st_count_11 : std_logic_vector(C_COUNTER_SIZE - 1 downto 0);
   signal   fv_s_st_valid    : std_logic;

   signal   fv_m_st_count_00 : std_logic_vector(C_COUNTER_SIZE - 1 downto 0);
   signal   fv_m_st_count_01 : std_logic_vector(C_COUNTER_SIZE - 1 downto 0);
   signal   fv_m_st_count_10 : std_logic_vector(C_COUNTER_SIZE - 1 downto 0);
   signal   fv_m_st_count_11 : std_logic_vector(C_COUNTER_SIZE - 1 downto 0);
   signal   fv_m_st_valid    : std_logic;

begin

   s_ready_o <= '1' when m_valid_o = '0' or m_ready_i = '1' else
                '0';

   state_proc : process (clk_i)
   begin
      if rising_edge(clk_i) then
         if m_ready_i = '1' then
            m_fail_o  <= '0';
            m_valid_o <= '0';
         end if;

         if cf_m_valid = '1' and cf_m_ready = '1' and cf_m_res_x = 1 then
            m_fail_o  <= '1';
            m_valid_o <= '1';
         end if;
         if gcd_m_valid = '1' and gcd_m_ready = '1' then
            m_data_o  <= factor_val;
            m_valid_o <= '1';
         end if;

         cf_s_valid <= '0';
         if s_valid_i = '1' and s_ready_o = '1' then
            cf_s_valid <= '1';
            cf_s_data  <= s_data_i;
            m_valid_o  <= '0';
         end if;

         if rst_i = '1' or cf_s_valid = '1' then
            m_valid_o <= '0';
         end if;
      end if;
   end process state_proc;


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
         s_ready_o => cf_s_ready,
         s_valid_i => cf_s_valid,
         s_data_i  => cf_s_data,
         m_ready_i => cf_m_ready,
         m_valid_o => cf_m_valid,
         m_res_x_o => cf_m_res_x,
         m_res_p_o => cf_m_res_p,
         m_res_w_o => cf_m_res_w
      ); -- cf_inst


   ---------------------------------------------------------------
   -- The FV method factorizes a number using small primes.
   -- satisfying N = y^2*Prod(p_i), p_i are primes.
   -- The choice of p_i is returned as a vector.
   --
   -- Example: N = 45 gives the following sequence of values:
   -- 45 = 3^2 * 5, i.e.
   -- * complete = 1
   -- * square = 3
   -- * primes = "...100".
   ---------------------------------------------------------------

   fv_s_valid <= cf_m_valid;
   fv_s_data  <= cf_m_res_p;
   fv_s_user  <= cf_m_res_w & cf_m_res_x;
   cf_m_ready <= fv_s_ready;

   fv_wrapper_inst : entity work.fv_wrapper
      generic map (
         G_DATA_SIZE       => C_HALF_SIZE,
         G_NUM_WORKERS     => G_NUM_WORKERS,
         G_PRIME_ADDR_SIZE => G_PRIME_ADDR_SIZE,
         G_VECTOR_SIZE     => G_VECTOR_SIZE,
         G_USER_SIZE       => C_FV_USER_SIZE
      )
      port map (
         clk_i        => clk_i,
         rst_i        => rst_i or cf_s_valid,
         s_ready_o    => fv_s_ready,
         s_valid_i    => fv_s_valid,
         s_data_i     => fv_s_data,
         s_user_i     => fv_s_user,
         m_ready_i    => fv_m_ready,
         m_valid_o    => fv_m_valid,
         m_complete_o => fv_m_complete,
         m_square_o   => fv_m_square,
         m_primes_o   => fv_m_primes,
         m_user_o     => fv_m_user
      ); -- fv_wrapper_inst

   fv_m_ready     <= afs_fv_s_ready;
   afs_fv_s_valid <= fv_m_valid;
   afs_fv_s_data  <= fv_m_complete & fv_m_square & fv_m_primes & fv_m_user;

   axi_fifo_small_fv_inst : entity work.axi_fifo_small
      generic map (
         G_RAM_WIDTH => C_AFS_FV_DATA_SIZE,
         G_RAM_DEPTH => C_AFS_FV_DEPTH
      )
      port map (
         clk_i     => clk_i,
         rst_i     => rst_i or cf_s_valid,
         s_ready_o => afs_fv_s_ready,
         s_valid_i => afs_fv_s_valid,
         s_data_i  => afs_fv_s_data,
         s_fill_o  => afs_fv_s_fill,
         m_ready_i => afs_fv_m_ready,
         m_valid_o => afs_fv_m_valid,
         m_data_o  => afs_fv_m_data
      ); -- axi_fifo_small_fv_inst

   (afs_fv_m_complete, afs_fv_m_square, afs_fv_m_primes, afs_fv_m_user)
                  <= afs_fv_m_data;


   ---------------------------------------------------------------
   -- The GF2 entity solves a system of linear GF(2) equations.
   --
   -- Example: The input sequence
   -- * ("0101", X"A")
   -- * ("0011", X"B")
   -- * ("1101", X"C")
   -- * ("1010", X"D")
   -- * ("0110", X"E")
   -- gives the output sequence
   -- * (X"E", '0')
   -- * (X"A", '0')
   -- * (X"B", '1')
   ---------------------------------------------------------------

   gf2_s_valid    <= afs_fv_m_valid and afs_fv_m_complete;
   gf2_s_row      <= afs_fv_m_primes & afs_fv_m_user(G_DATA_SIZE);
   gf2_s_user     <= afs_fv_m_square & afs_fv_m_primes & afs_fv_m_user(G_DATA_SIZE - 1 downto 0);
   afs_fv_m_ready <= gf2_s_ready;

   gf2_solver_inst : entity work.gf2_solver
      generic map (
         G_ROW_SIZE  => G_VECTOR_SIZE + 1,
         G_USER_SIZE => C_GF2_USER_SIZE
      )
      port map (
         clk_i     => clk_i,
         rst_i     => rst_i or cf_s_valid,
         s_ready_o => gf2_s_ready,
         s_valid_i => gf2_s_valid,
         s_row_i   => gf2_s_row,
         s_user_i  => gf2_s_user,
         m_ready_i => gf2_m_ready,
         m_valid_o => gf2_m_valid,
         m_user_o  => gf2_m_user,
         m_last_o  => gf2_m_last
      ); -- gf2_solver_inst

   gf2_m_ready     <= afs_gf2_s_ready;
   afs_gf2_s_valid <= gf2_m_valid;
   afs_gf2_s_data  <= gf2_m_user & gf2_m_last;

   axi_fifo_small_gf2_inst : entity work.axi_fifo_small
      generic map (
         G_RAM_WIDTH => C_AFS_GF2_DATA_SIZE,
         G_RAM_DEPTH => C_AFS_GF2_DEPTH
      )
      port map (
         clk_i     => clk_i,
         rst_i     => rst_i or cf_s_valid,
         s_ready_o => afs_gf2_s_ready,
         s_valid_i => afs_gf2_s_valid,
         s_data_i  => afs_gf2_s_data,
         s_fill_o  => afs_gf2_s_fill,
         m_ready_i => afs_gf2_m_ready,
         m_valid_o => afs_gf2_m_valid,
         m_data_o  => afs_gf2_m_data
      ); -- axi_fifo_small_gf2_inst

   (afs_gf2_m_user, afs_gf2_m_last) <= afs_gf2_m_data;

   ---------------------------------------------------------------
   -- The candidate entity generates a solution candidate
   --
   -- Example: The input sequence (N=4559):
   -- * x=1245, p=00001100, s=1
   -- * x=  67, p=00001101, s=1
   -- * x=1553, p=00000001, s=7, LAST
   -- gives the output sequence
   -- * x=4069, y=490
   ---------------------------------------------------------------

   cand_s_valid                     <= afs_gf2_m_valid;
   cand_s_n                         <= cf_s_data;
   cand_s_x                         <= afs_gf2_m_user(R_GF2_USER_X);
   cand_s_primes                    <= afs_gf2_m_user(R_GF2_USER_PRIMES);
   cand_s_square                    <= afs_gf2_m_user(R_GF2_USER_SQUARE);
   cand_s_last                      <= afs_gf2_m_last;
   afs_gf2_m_ready                  <= cand_s_ready;

   candidate_inst : entity work.candidate
      generic map (
         G_DATA_SIZE       => G_DATA_SIZE,
         G_PRIME_ADDR_SIZE => G_PRIME_ADDR_SIZE,
         G_VECTOR_SIZE     => G_VECTOR_SIZE
      )
      port map (
         clk_i          => clk_i,
         rst_i          => rst_i or cf_s_valid,
         s_ready_o      => cand_s_ready,
         s_valid_i      => cand_s_valid,
         s_n_i          => cand_s_n,
         s_x_i          => cand_s_x,
         s_primes_i     => cand_s_primes,
         s_square_i     => cand_s_square,
         s_last_i       => cand_s_last,
         m_ready_i      => cand_m_ready,
         m_valid_o      => cand_m_valid,
         m_x_o          => cand_m_x,
         m_y_o          => cand_m_y,
         primes_index_o => cand_primes_index,
         primes_data_i  => cand_primes_data
      ); -- candidate_inst

   cand_primes_inst : entity work.primes
      generic map (
         G_DATA_SIZE => C_HALF_SIZE,
         G_ADDR_SIZE => G_PRIME_ADDR_SIZE
      )
      port map (
         clk_i   => clk_i,
         rst_i   => rst_i or cf_s_valid,
         index_i => cand_primes_index,
         data_o  => cand_primes_data
      ); -- cand_primes_inst


   cand_m_ready <= gcd_s_ready;
   gcd_s_valid  <= cand_m_valid;
   gcd_s_data1  <= ("0" & cand_m_x) + ("0" & cand_m_y);
   gcd_s_data2  <= "0" & cf_s_data;

   gcd_inst : entity work.gcd
      generic map (
         G_DATA_SIZE => G_DATA_SIZE + 1
      )
      port map (
         clk_i     => clk_i,
         rst_i     => rst_i or cf_s_valid,
         s_valid_i => gcd_s_valid,
         s_ready_o => gcd_s_ready,
         s_data1_i => gcd_s_data1,
         s_data2_i => gcd_s_data2,
         m_valid_o => gcd_m_valid,
         m_ready_i => gcd_m_ready,
         m_data_o  => gcd_m_data
      ); -- gcd_inst


   factor_val  <= gcd_m_data(G_DATA_SIZE - 1 downto 0);

   gcd_m_ready <= m_ready_i;


   ---------------------------------------------------------------
   -- Debug counters
   ---------------------------------------------------------------

   cf_debug_proc : process (clk_i)
      variable x_v : integer;
      variable p_v : integer;
      variable w_v : integer;
      variable n_v : integer;
   begin
      if rising_edge(clk_i) then
         if cf_m_valid = '1' and cf_m_ready = '1' then
            if C_DEBUG then
               x_v := to_integer(cf_m_res_x);
               p_v := to_integer(cf_m_res_p);
               w_v := 1 when cf_m_res_w = '0' else -1;
               n_v := to_integer(cf_s_data);
               report "CF: x=" & to_string(x_v) &
                      ", p=" & to_string(p_v) &
                      ", w=" & to_string(w_v) &
                      ", n=" & to_string(n_v);
               assert w_v * w_v = 1;
               assert p_v * p_v < 4 * n_v;
               assert (x_v * x_v mod n_v) = p_v * w_v or
                      (x_v * x_v mod n_v) = p_v * w_v + n_v;
            end if;
         end if;
      end if;
   end process cf_debug_proc;

   fv_debug_proc : process (clk_i)
   begin
      if rising_edge(clk_i) then
         if fv_m_valid = '1' and fv_m_complete = '1' and fv_m_ready = '1' then
            if C_DEBUG then
               report "FV: square=" & to_string(to_integer(fv_m_square)) &
                      ", primes=" & to_string(fv_m_primes) &
                      ", user=" & to_string(fv_m_user(R_FV_USER_W)) &
                      "," & to_string(to_integer(fv_m_user(R_FV_USER_X)));
            end if;
         end if;
      end if;
   end process fv_debug_proc;

   gf2_debug_proc : process (clk_i)
   begin
      if rising_edge(clk_i) then
         if gf2_m_valid = '1' and gf2_m_ready = '1' then
            if C_DEBUG then
               report "GF2: user=" & to_string(to_integer(gf2_m_user(R_GF2_USER_X))) &
                      "," & to_string(gf2_m_user(R_GF2_USER_PRIMES)) &
                      "," & to_string(to_integer(gf2_m_user(R_GF2_USER_SQUARE))) &
                      ", last=" & to_string(gf2_m_last);
            end if;
         end if;
      end if;
   end process gf2_debug_proc;

   cand_debug_proc : process (clk_i)
      variable x_v : integer;
      variable y_v : integer;
      variable n_v : integer;
   begin
      if rising_edge(clk_i) then
         if cand_m_valid = '1' and cand_m_ready = '1' then
            if C_DEBUG then
               x_v := to_integer(cand_m_x);
               y_v := to_integer(cand_m_y);
               n_v := to_integer(cf_s_data);
               report "CAND: x=" & to_string(x_v) &
                      ", y=" & to_string(y_v) &
                      ", n=" & to_string(n_v);
               assert (x_v * x_v mod n_v) = (y_v * y_v mod n_v);
            end if;
         end if;
      end if;
   end process cand_debug_proc;

   gcd_debug_proc : process (clk_i)
   begin
      if rising_edge(clk_i) then
         if gcd_m_valid = '1' and gcd_m_ready = '1' then
            if C_DEBUG then
               report "GCD: res=" & to_string(to_integer(gcd_m_data));
            end if;
         end if;
      end if;
   end process gcd_debug_proc;

   fv_stat_latency_inst : entity work.stat_latency
      generic map (
         G_COUNTER_SIZE => C_COUNTER_SIZE
      )
      port map (
         clk_i      => clk_i,
         rst_i      => rst_i,
         s_ready_i  => fv_s_ready,
         s_valid_i  => fv_s_valid,
         m_ready_i  => fv_m_ready,
         m_valid_i  => fv_m_valid,
         st_count_o => fv_st_count,
         st_valid_o => fv_st_valid
      ); -- fv_stat_latency_inst

   fv_stat_inst : entity work.stat
      generic map (
         G_DATA_SIZE     => C_COUNTER_SIZE,
         G_FRACTION_SIZE => 6
      )
      port map (
         clk_i     => clk_i,
         rst_i     => rst_i,
         s_data_i  => fv_st_count,
         s_valid_i => fv_st_valid,
         m_count_o => stat_count,
         m_min_o   => stat_min,
         m_max_o   => stat_max,
         m_mean_o  => stat_mean
      ); -- fv_stat_inst

   fv_s_stat_wait_inst : entity work.stat_wait
      generic map (
         G_COUNTER_SIZE => C_COUNTER_SIZE
      )
      port map (
         clk_i         => clk_i,
         rst_i         => rst_i,
         ready_i       => fv_s_ready,
         valid_i       => fv_s_valid,
         st_count_00_o => fv_s_st_count_00,
         st_count_01_o => fv_s_st_count_01,
         st_count_10_o => fv_s_st_count_10,
         st_count_11_o => fv_s_st_count_11,
         st_valid_o    => fv_s_st_valid
      ); -- fv_s_stat_wait_inst

   fv_m_stat_wait_inst : entity work.stat_wait
      generic map (
         G_COUNTER_SIZE => C_COUNTER_SIZE
      )
      port map (
         clk_i         => clk_i,
         rst_i         => rst_i,
         ready_i       => fv_m_ready,
         valid_i       => fv_m_valid,
         st_count_00_o => fv_m_st_count_00,
         st_count_01_o => fv_m_st_count_01,
         st_count_10_o => fv_m_st_count_10,
         st_count_11_o => fv_m_st_count_11,
         st_valid_o    => fv_m_st_valid
      ); -- fv_m_stat_wait_inst

end architecture synthesis;

