library ieee;
   use ieee.std_logic_1164.all;
   use ieee.numeric_std_unsigned.all;

entity add_mult is
   generic (
      G_DATA_SIZE : integer
   );
   port (
      clk_i     : in    std_logic;
      rst_i     : in    std_logic;
      s_ready_o : out   std_logic;
      s_valid_i : in    std_logic;
      s_val_a_i : in    std_logic_vector(G_DATA_SIZE - 1 downto 0);
      s_val_x_i : in    std_logic_vector(G_DATA_SIZE - 1 downto 0);
      s_val_b_i : in    std_logic_vector(2 * G_DATA_SIZE - 1 downto 0);
      m_ready_i : in    std_logic;
      m_valid_o : out   std_logic;
      m_res_o   : out   std_logic_vector(2 * G_DATA_SIZE - 1 downto 0)
   );
end entity add_mult;

architecture synthesis of add_mult is

   constant C_ZERO : std_logic_vector(G_DATA_SIZE - 1 downto 0) := (others => '0');

   signal   mult_r : std_logic_vector(G_DATA_SIZE - 1 downto 0);
   signal   add_r  : std_logic_vector(2 * G_DATA_SIZE - 1 downto 0);
   signal   res_r  : std_logic_vector(2 * G_DATA_SIZE - 1 downto 0);

   type     state_type is (IDLE_ST, MULT_ST);
   signal   state_r : state_type;

begin

   -- Connect output signals
   m_res_o   <= res_r;
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
                  mult_r  <= s_val_a_i;
                  add_r   <= C_ZERO & s_val_x_i;
                  res_r   <= s_val_b_i;
                  state_r <= MULT_ST;
               end if;

            when MULT_ST =>
               if mult_r(0) = '1' then
                  res_r <= res_r + add_r;
               end if;

               mult_r <= '0' & mult_r(G_DATA_SIZE - 1 downto 1);
               add_r  <= add_r(2 * G_DATA_SIZE - 2 downto 0) & '0';

               if mult_r = 0 then
                  m_valid_o <= '1';
                  state_r   <= IDLE_ST;
               end if;

         end case;

         if rst_i = '1' then
            m_valid_o <= '0';
            state_r   <= IDLE_ST;
         end if;
      end if;
   end process fsm_proc;

end architecture synthesis;

