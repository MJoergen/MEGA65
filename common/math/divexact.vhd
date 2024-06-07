-- This computes the exact quotient of res = val1 / val2.
-- It is required that the division is exact, i.e. that there is no remainder.
-- In other words, the algorithm assumes that val1 = res * val2.

library ieee;
   use ieee.std_logic_1164.all;
   use ieee.numeric_std_unsigned.all;

entity divexact is
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
end entity divexact;

architecture synthesis of divexact is

   constant C_ZERO : std_logic_vector(G_DATA_SIZE - 1 downto 0) := (others => '0');

   signal   val1 : std_logic_vector(G_DATA_SIZE - 1 downto 0);
   signal   val2 : std_logic_vector(G_DATA_SIZE - 1 downto 0);

   signal   index : integer range 0 to G_DATA_SIZE - 1;

   type     fsm_state_type is
    (
      IDLE_ST, REDUCING_ST, WORKING_ST, DONE_ST
   );

   signal   state : fsm_state_type;

   pure function or_range (
      arg : std_logic_vector;
      right : natural
   ) return std_logic is
   begin
      for i in arg'range loop
         if i < right then
            return '0';
         end if;
         if arg(i) = '1' then
            return '1';
         end if;
      end loop;

      return '0';
   end function or_range;

begin

   m_data_o  <= val1;

   s_ready_o <= '1' when state = IDLE_ST and m_valid_o = '0' else
                '0';

   fsm_proc : process (clk_i)
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
                  index <= 0;
                  state <= REDUCING_ST;
               end if;

            when REDUCING_ST =>
               if val1(0) = '0' and val2(0) = '0' then
                  val1 <= "0" & val1(G_DATA_SIZE - 1 downto 1);
                  val2 <= "0" & val2(G_DATA_SIZE - 1 downto 1);
               else
                  -- At this stage val2 will always be odd, because the division is assumed to be exact.
                  -- pragma synthesis_off
                  assert val2(0) = '1';
                  -- pragma synthesis_on
                  -- Clear the LSB
                  val2  <= val2(G_DATA_SIZE - 1 downto 1) & "0";
                  index <= 0;
                  state <= WORKING_ST;
               end if;

            when WORKING_ST =>
               if or_range(val1, index) = '0' then
                  state <= DONE_ST;
               else
                  if val1(index) = '1' then
                     val1 <= val1 - val2;
                  end if;
                  -- Multiply by 2
                  val2  <= val2(G_DATA_SIZE - 2 downto 0) & "0";
                  index <= index + 1;
               end if;

            when DONE_ST =>
               m_valid_o <= '1';
               if s_valid_i = '0' then
                  state <= IDLE_ST;
               end if;

         end case;

         if rst_i = '1' then
            val1      <= C_ZERO;
            val2      <= C_ZERO;
            index     <= 0;
            state     <= IDLE_ST;
            m_valid_o <= '0';
         end if;
      end if;
   end process fsm_proc;

end architecture synthesis;

