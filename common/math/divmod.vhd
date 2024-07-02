library ieee;
   use ieee.std_logic_1164.all;
   use ieee.numeric_std_unsigned.all;

-- This module calculates the division n/d = q + r/d,
-- and returns the quotient q and remainder r.
-- The algorithm is identical to the old-school method
-- using repeated subtractions.
-- The running time is proportional to the number of bits
-- in the quotient. In other words, to the difference in size
-- of the numerator and the denominator.

entity divmod is
   generic (
      G_DATA_SIZE : integer
   );
   port (
      clk_i     : in    std_logic;
      rst_i     : in    std_logic;
      s_ready_o : out   std_logic;
      s_valid_i : in    std_logic;
      s_val_n_i : in    std_logic_vector(G_DATA_SIZE - 1 downto 0);
      s_val_d_i : in    std_logic_vector(G_DATA_SIZE - 1 downto 0);
      m_ready_i : in    std_logic;
      m_valid_o : out   std_logic;
      m_res_q_o : out   std_logic_vector(G_DATA_SIZE - 1 downto 0);
      m_res_r_o : out   std_logic_vector(G_DATA_SIZE - 1 downto 0)
   );
end entity divmod;

architecture synthesis of divmod is

   constant C_ZERO : std_logic_vector(G_DATA_SIZE - 1 downto 0) := (others => '0');
   constant C_ONE  : std_logic_vector(G_DATA_SIZE - 1 downto 0) := to_stdlogicvector(1, G_DATA_SIZE);

   type     state_type is (IDLE_ST, PREPARE_ST, SHIFT_ST, REDUCE_ST);
   signal   state : state_type;

   signal   val_d : std_logic_vector(G_DATA_SIZE downto 0);
   signal   shift : integer range 0 to G_DATA_SIZE;

   -- Output signals
   signal   res_q : std_logic_vector(G_DATA_SIZE - 1 downto 0);
   signal   res_r : std_logic_vector(G_DATA_SIZE downto 0);

   pure function leading_index (
      arg : std_logic_vector
   ) return natural is
   begin
      assert arg /= 0;
      --
      for i in arg'range loop
         if arg(i) = '1' then
            return i;
         end if;
      end loop;

      -- This should never occur
      assert false;
      return 0;
   end function leading_index;

begin

   m_res_q_o <= res_q;
   m_res_r_o <= res_r(G_DATA_SIZE - 1 downto 0);
   s_ready_o <= '1' when state = IDLE_ST and (m_valid_o = '0' or m_ready_i = '1') else
                '0';

   fsm_proc : process (clk_i)
      variable index_res_v : natural range 0 to G_DATA_SIZE - 1;
      variable index_val_v : natural range 0 to G_DATA_SIZE - 1;
   begin
      if rising_edge(clk_i) then
         if m_ready_i = '1' then
            m_valid_o <= '0';
         end if;

         case state is

            -- Store the input values
            when IDLE_ST =>
               if s_valid_i = '1' and s_ready_o = '1' then
                  assert s_val_d_i /= 0;
                  res_q <= (others => '0');
                  res_r <= '0' & s_val_n_i;
                  val_d <= '0' & s_val_d_i;

                  if s_val_n_i = 0 then
                     m_valid_o <= '1';
                     state     <= IDLE_ST;
                  else
                     m_valid_o <= '0';
                     index_res_v := leading_index(s_val_n_i);
                     index_val_v := leading_index(s_val_d_i);
                     if index_res_v > index_val_v then
                        shift <= index_res_v - index_val_v;
                        state <= PREPARE_ST;
                     else
                        shift <= 0;
                        state <= SHIFT_ST;
                     end if;
                  end if;
               end if;

            when PREPARE_ST =>
               val_d <= shift_left(val_d, shift);
               state <= SHIFT_ST;

            -- Shift the denominator, until it is larger than the numerator
            when SHIFT_ST =>
               if res_r > val_d then
                  val_d <= val_d(G_DATA_SIZE - 1 downto 0) & '0';
                  shift <= shift + 1;
               else
                  state <= REDUCE_ST;
               end if;

            -- Subtract the denominator from the numerator.
            when REDUCE_ST =>
               if res_r >= val_d then
                  res_r <= res_r - val_d;
                  res_q <= res_q(G_DATA_SIZE - 2 downto 0) & '1';
               else
                  res_q <= res_q(G_DATA_SIZE - 2 downto 0) & '0';
               end if;
               val_d <= '0' & val_d(G_DATA_SIZE downto 1);

               if shift > 0 then
                  f_shift : assert val_d(0) = '0' or rst_i = '1';
                  shift <= shift - 1;
               else
                  m_valid_o <= '1';
                  state     <= IDLE_ST;
               end if;

         end case;

         if rst_i = '1' then
            res_q     <= (others => '0');
            res_r     <= (others => '0');
            m_valid_o <= '0';
            state     <= IDLE_ST;
         end if;
      end if;
   end process fsm_proc;

end architecture synthesis;

