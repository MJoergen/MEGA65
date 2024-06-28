library ieee;
   use ieee.std_logic_1164.all;
   use ieee.numeric_std_unsigned.all;

-- This module takes an integer N and calculates the integer square root
-- M = floor(sqrt(N)) as well as the remainder N-M*M.

-- The algorithm is taken from
-- https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Binary_numeral_system_(base_2)
-- and uses a fixed number of clock cycles each time, equal to G_DATA_SIZE.

-- The value N is presented on the input bus s_data_i, and the input signal
-- s_valid_i is pulsed once. Some time later the result will be present on the
-- output busses m_res_o and m_diff_o, and the output signal m_valid_o will be held
-- high.  s_data_i and s_valid_i only need to be valid for a single clock cycle.
-- However, m_res_o and m_diff_o will remain valid until m_ready_i is
-- asserted.

-- There is an extra signal s_ready_o which is de-asserted when a calculation is in
-- progress. It is not possible to interrupt a calculation, and asserting
-- s_valid_i will be ignored as long as s_ready_o is de-asserted.

entity sqrt is
   generic (
      G_DATA_SIZE : integer
   );
   port (
      clk_i     : in    std_logic;
      rst_i     : in    std_logic;
      s_ready_o : out   std_logic;
      s_valid_i : in    std_logic;
      s_data_i  : in    std_logic_vector(G_DATA_SIZE - 1 downto 0);     -- N
      m_ready_i : in    std_logic;
      m_valid_o : out   std_logic;
      m_res_o   : out   std_logic_vector(G_DATA_SIZE / 2 - 1 downto 0); -- M = floor(sqrt(N))
      m_diff_o  : out   std_logic_vector(G_DATA_SIZE / 2     downto 0)  -- N - M*M
   );
end entity sqrt;

architecture synthesis of sqrt is

   constant C_HALF_SIZE : natural := G_DATA_SIZE/2;

   constant C_ZERO : std_logic_vector(C_HALF_SIZE - 1 downto 0) := (others => '0');

   type     state_type is (IDLE_ST, CALC_ST);
   signal   state_r : state_type;

   signal   val_r : std_logic_vector(G_DATA_SIZE - 1 downto 0);
   signal   bit_r : std_logic_vector(G_DATA_SIZE - 1 downto 0);

   signal   res_r : std_logic_vector(G_DATA_SIZE - 1 downto 0);

begin

   -- Connect output signals
   m_res_o   <= res_r(C_HALF_SIZE - 1 downto 0);
   m_diff_o  <= val_r(C_HALF_SIZE     downto 0);
   s_ready_o <= '1' when state_r = IDLE_ST and (m_valid_o = '0' or m_ready_i = '1') else
                '0';

   fsm_proc : process (clk_i)
   begin
      if rising_edge(clk_i) then
         if m_ready_i = '1' then
            m_valid_o <= '0';
         end if;

         case state_r is

            when IDLE_ST =>
               if s_valid_i = '1' and s_ready_o = '1' then
                  val_r   <= s_data_i; -- Store input value
                  bit_r   <= "01" & to_stdlogicvector(0, G_DATA_SIZE - 2);
                  res_r   <= (others => '0');
                  state_r <= CALC_ST;
               end if;

            when CALC_ST =>
               if val_r >= (res_r or bit_r) then
                  val_r <= val_r - (res_r or bit_r);
                  res_r <= ("0" & res_r(G_DATA_SIZE - 1 downto 1)) or bit_r;
               else
                  res_r <= ("0" & res_r(G_DATA_SIZE - 1 downto 1));
               end if;

               bit_r   <= "00" & bit_r(G_DATA_SIZE - 1 downto 2);
               state_r <= CALC_ST;

               if bit_r(0) = '1' then
                  m_valid_o <= '1';
                  state_r   <= IDLE_ST;
               end if;

         end case;

         if rst_i = '1' then
            res_r     <= (others => '0');
            val_r     <= (others => '0');
            m_valid_o <= '0';
            state_r   <= IDLE_ST;
         end if;
      end if;
   end process fsm_proc;

end architecture synthesis;

