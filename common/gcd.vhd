-- This implements the Binary Euclidian Algorithm.
-- Pseudo-code is as follows:
--   unsigned int gcd(unsigned int a, unsigned int b)
--   {
--     if (a == 0 || b == 0)
--       return 0;
--     if (a == 1 || b == 1)
--       return 1;
--     if ((a%2)==0 && (b%2)==0)
--       return 2*gcd(a/2, b/2); // Both even
--     if ((a%2)==1 && (b%2)==0)
--       return gcd(a, b/2); // b even
--     if ((a%2)==0 && (b%2)==1)
--       return gcd(a/2, b); // a even
--     // Now both are odd
--     if (a > b)
--       return gcd((a-b)/2, b);
--     if (a < b)
--       return gcd((b-a)/2, a);
--     // a == b
--     return a;
--   } // end of gcd


library ieee;
   use ieee.std_logic_1164.all;
   use ieee.numeric_std_unsigned.all;

entity gcd is
   generic (
      G_DATA_SIZE : integer
   );
   port (
      clk_i     : in    std_logic;
      rst_i     : in    std_logic;
      s_valid_i : in    std_logic;
      s_ready_o : out   std_logic;
      s_data1_i : in    std_logic_vector(G_DATA_SIZE - 1 downto 0);
      s_data2_i : in    std_logic_vector(G_DATA_SIZE - 1 downto 0);
      m_valid_o : out   std_logic;
      m_ready_i : in    std_logic;
      m_data_o  : out   std_logic_vector(G_DATA_SIZE - 1 downto 0)
   );
end entity gcd;

architecture synthesis of gcd is

   constant C_ZERO : std_logic_vector(G_DATA_SIZE - 1 downto 0) := (others => '0');
   constant C_ONE  : std_logic_vector(G_DATA_SIZE - 1 downto 0) := (0 => '1', others => '0');

   signal   val1 : std_logic_vector(G_DATA_SIZE - 1 downto 0);
   signal   val2 : std_logic_vector(G_DATA_SIZE - 1 downto 0);

   signal   shift : integer range 0 to G_DATA_SIZE - 1;

   type     fsm_state_type is
    (
      IDLE_ST, REDUCE_ST, SHIFTING_ST, DONE_ST
   );

   signal   state : fsm_state_type;

begin

   m_data_o  <= val1;

   s_ready_o <= '1' when state = IDLE_ST and m_valid_o = '0' else
                '0';

   fsm_proc : process (clk_i)
      variable res1_v : std_logic_vector(G_DATA_SIZE - 1 downto 0);
      variable res2_v : std_logic_vector(G_DATA_SIZE - 1 downto 0);
      variable c_v    : std_logic_vector(1 downto 0);
   begin
      if rising_edge(clk_i) then
         if m_ready_i = '1' then
            m_valid_o <= '0';
         end if;

         case state is

            when IDLE_ST =>
               if s_valid_i = '1' and s_ready_o = '1' then
                  val1  <= s_data1_i;
                  val2  <= s_data2_i;
                  shift <= 0;
                  state <= REDUCE_ST;
               end if;

            when REDUCE_ST =>
               if val1 = C_ZERO or val2 = C_ZERO then
                  val1      <= (others => '0');
                  m_valid_o <= '1';
                  state     <= DONE_ST;
               elsif val1 = C_ONE or val2 = C_ONE then
                  val1  <= C_ONE;
                  val2  <= C_ONE;
                  state <= SHIFTING_ST;
               else
                  if val1(0) = '0' and  val2(0) = '0' then
                     -- both are even, remember this!
                     shift <= shift + 1;
                  end if;

                  if val1(0) = '0' then
                     -- Divide by two
                     val1 <= '0' & val1(G_DATA_SIZE - 1 downto 1);
                  end if;

                  if val2(0) = '0' then
                     -- Divide by two
                     val2 <= '0' & val2(G_DATA_SIZE - 1 downto 1);
                  end if;

                  if val1(0) = '1' and val2(0) = '1' then
                     -- Skip away the '1' bit at the zero position. We
                     -- won't need that anymore.
                     -- We must, however, have an extra zero in front,
                     -- to detect overflow (negative results).
                     res1_v := ('0' & val1(G_DATA_SIZE - 1 downto 1)) - ('0' & val2(G_DATA_SIZE - 1 downto 1));
                     res2_v := ('0' & val2(G_DATA_SIZE - 1 downto 1)) - ('0' & val1(G_DATA_SIZE - 1 downto 1));

                     c_v    := res1_v(G_DATA_SIZE - 1 downto G_DATA_SIZE - 1) & res2_v(G_DATA_SIZE - 1 downto
                                                                                       G_DATA_SIZE - 1);

                     case c_v is

                        when "00" =>
                           -- val1 and val2 are equal. Now we're almost done.
                           state <= SHIFTING_ST;

                        when "01" =>
                           val1 <= res1_v;

                        when "10" =>
                           val2 <= res2_v;

                        when others =>
                           -- This should never happen.
                           -- pragma synthesis_off
                           assert false;
                           -- pragma synthesis_on
                           null;

                     end case;

                  end if;
               end if;

            when SHIFTING_ST =>
               if shift > 0 then
                  -- Multiply by 2
                  val1  <= val1(G_DATA_SIZE - 2 downto 0) & '0';
                  shift <= shift - 1;
               else
                  m_valid_o <= '1';
                  state     <= DONE_ST;
               end if;

            when DONE_ST =>
               if s_valid_i = '0' then
                  state <= IDLE_ST;
               end if;

         end case;

         if rst_i = '1' then
            val1      <= C_ZERO;
            val2      <= C_ZERO;
            shift     <= 0;
            m_valid_o <= '0';
            state     <= IDLE_ST;
         end if;
      end if;
   end process fsm_proc;

end architecture synthesis;

