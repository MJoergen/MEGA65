-- This function of this module can be described by the following python pseudo code:
--
--    t = all_prim_prod
--    while True:
--        t = gmpy.gcd(v, t)
--        if t == 1:
--            break
--        v = gmpy.divexact(v, t)
--    return v
--

library ieee;
   use ieee.std_logic_1164.all;
   use ieee.numeric_std_unsigned.all;

entity control is
   generic (
      G_SIZE     : integer;
      G_VAL_SIZE : integer;
      G_LOG_SIZE : integer
   );
   port (
      clk_i       : in    std_logic;
      rst_i       : in    std_logic;

      -- Outputs driven by this module
      start_div_o : out   std_logic;
      start_gcd_o : out   std_logic;
      val2_o      : out   std_logic_vector(G_SIZE - 1 downto 0);
      val1_o      : out   std_logic_vector(G_SIZE - 1 downto 0);
      valid_o     : out   std_logic;
      ready_i     : in    std_logic;
      state_log_o : out   std_logic_vector(G_LOG_SIZE - 1 downto 0);

      -- Inputs from EPP module
      epp_val2_i  : in    std_logic_vector(G_VAL_SIZE - 1 downto 0);
      epp_start_i : in    std_logic;

      -- Inputs from GCD module
      gcd_res_i   : in    std_logic_vector(G_SIZE - 1 downto 0);
      gcd_valid_i : in    std_logic;

      -- Inputs from DIV module
      div_res_i   : in    std_logic_vector(G_VAL_SIZE - 1 downto 0);
      div_valid_i : in    std_logic
   );
end entity control;

architecture behavioral of control is

   type     fsm_state_type is
    (
      IDLE_ST, DO_GCD_ST, DO_DIV_ST, DONE_ST
   );

   signal   state : fsm_state_type;

   signal   val1      : std_logic_vector(G_SIZE - 1 downto 0);
   signal   val2      : std_logic_vector(G_SIZE - 1 downto 0);
   signal   start_gcd : std_logic;
   signal   start_div : std_logic;

   signal   state_log : std_logic_vector(G_LOG_SIZE - 1 downto 0);

   constant C_ZERO : std_logic_vector(G_SIZE - 1 downto 0)          := (others => '0');
   constant C_ONE  : std_logic_vector(G_SIZE - 1 downto 0)          := (0 => '1', others => '0');

   -- val1 is hardcoded to be the product of all primes from 2 up to and including 191.
   -- I.e. it is equal to 2 * 3 * 5 * 7 * 11 * 13 * 17 * 19 * 23 * 29 * 31 * 37 *
   -- 41 * 43 * 47 * 53 * 59 * 61 * 67 * 71 * 73 * 79 * 83 * 89 * 97 * 101 *
   -- 103 * 107 * 109 * 113 * 127 * 131 * 137 * 139 * 149 * 151 * 157 * 163 *
   -- 167 * 173 * 179 * 181 * 191
   constant C_ALL_PRIM_PROD : std_logic_vector(G_SIZE - 1 downto 0) :=
                                                                       X"024776ffd3cbd21c872eccd26ad078c5ba0586e2e57cf68515e3c4828a673a6e";

   -- Debugging
   signal   state_d : fsm_state_type;
   subtype  STATE_SLV_TYPE is std_logic_vector(1 downto 0);

   pure function state2slv (
      state_v : fsm_state_type
   ) return STATE_SLV_TYPE is
   begin
      --
      case state_v is

         when IDLE_ST =>
            return "00";

         when DO_GCD_ST =>
            return "01";

         when DO_DIV_ST =>
            return "10";

         when DONE_ST =>
            return "11";

      end case;

   --
   end function state2slv;

begin

   val1_o      <= val1;
   val2_o      <= val2;
   start_gcd_o <= start_gcd;
   start_div_o <= start_div;
   state_log_o <= state_log;

   log_proc : process (clk_i)
   begin
      if rising_edge(clk_i) then
         if state_d /= state then
            state_log <= state_log(G_LOG_SIZE - 3 downto 0) & state2slv(state);
         end if;
         if state = IDLE_ST then
            state_log <= (others => '0');
         end if;
         state_d <= state;
         if rst_i = '1' then
            state_d   <= IDLE_ST;
            state_log <= (others => '0');
         end if;
      end if;
   end process log_proc;

   ctrl_proc : process (clk_i)
   begin
      if rising_edge(clk_i) then
         if ready_i = '1' then
            valid_o <= '0';
         end if;

         case state is

            when IDLE_ST =>
               start_gcd <= '0';
               start_div <= '0';
               if epp_start_i = '1' then
                  -- Now we have the initial value in epp_val2_i
                  val1      <= C_ALL_PRIM_PROD;
                  val2      <= C_zero(G_SIZE - G_VAL_SIZE - 1 downto 0) & epp_val2_i;
                  start_gcd <= '1';
                  start_div <= '0';
                  state     <= DO_GCD_ST;
               end if;

            when DO_GCD_ST =>
               start_gcd <= '0';
               start_div <= '0';
               if gcd_valid_i = '1' then
                  -- Now we have the result in gcd_res_i
                  if gcd_res_i = C_ONE then
                     -- The desired result is in val2
                     state <= DONE_ST;
                  else
                     val1      <= val2;
                     val2      <= gcd_res_i;
                     start_gcd <= '0';
                     start_div <= '1';
                     state     <= DO_DIV_ST;
                  end if;
               end if;

            when DO_DIV_ST =>
               start_gcd <= '0';
               start_div <= '0';
               if div_valid_i = '1' then
                  -- Now we have the result in div_res_i
                  val1      <= val2;
                  val2      <= C_zero(G_SIZE - G_VAL_SIZE - 1 downto 0) & div_res_i;
                  start_gcd <= '1';
                  start_div <= '0';
                  state     <= DO_GCD_ST;
               end if;

            when DONE_ST =>
               start_gcd <= '0';
               start_div <= '0';

               valid_o <= '1';
               if epp_start_i = '0' then
                  state <= IDLE_ST;
               end if;

         end case;

         if rst_i = '1' then
            val1      <= C_ZERO;
            val2      <= C_ZERO;
            start_gcd <= '0';
            start_div <= '0';
            state     <= IDLE_ST;
         end if;
      end if;
   end process ctrl_proc;

end architecture behavioral;

