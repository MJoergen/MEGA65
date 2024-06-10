library ieee;
   use ieee.std_logic_1164.all;
   use ieee.numeric_std_unsigned.all;

entity slv_to_dec is
   generic (
      G_DATA_SIZE : integer
   );
   port (
      clk_i     : in    std_logic;
      rst_i     : in    std_logic;

      s_valid_i : in    std_logic;
      s_ready_o : out   std_logic;
      s_data_i  : in    std_logic_vector(G_DATA_SIZE - 1 downto 0);
      m_valid_o : out   std_logic;
      m_ready_i : in    std_logic;
      m_last_o  : out   std_logic;
      m_data_o  : out   std_logic_vector(3 downto 0)
   );
end entity slv_to_dec;

architecture synthesis of slv_to_dec is

   type     state_type is (IDLE_ST, BUSY_ST, WAIT_ST);
   signal   state : state_type                                    := IDLE_ST;
   signal   first : std_logic;

   constant C_ONE : std_logic_vector(G_DATA_SIZE - 1 downto 0)    := (0 => '1', others => '0');

   signal   de_in_valid  : std_logic;
   signal   de_in_ready  : std_logic;
   signal   de_out_res   : std_logic_vector(G_DATA_SIZE - 1 downto 0);
   signal   de_out_valid : std_logic;
   signal   de_out_ready : std_logic;

   pure function largest_pow_ten (
      size : natural
   ) return std_logic_vector is
      variable res_v : std_logic_vector(size - 1 downto 0);
      variable new_v : std_logic_vector(size downto 0);
   begin
      --
      res_v := (0 => '1', others => '0');
      infinite_loop : loop
         new_v := ("0" & res_v(size - 4 downto 0) & "000") +
                  ("0" & res_v(size - 2 downto 0) & "0");
         if new_v(size) = '1' or res_v(size-1 downto size-3) /= "00" then
            return res_v;
         end if;
         res_v := new_v(size-1 downto 0);
      end loop infinite_loop;

   --
   end function largest_pow_ten;

   signal   pow_ten  : std_logic_vector(G_DATA_SIZE - 1 downto 0) := largest_pow_ten(G_DATA_SIZE);
   signal   slv_data : std_logic_vector(G_DATA_SIZE - 1 downto 0);

begin

   s_ready_o    <= not m_valid_o when state = IDLE_ST else
                   '0';

   fsm_proc : process (clk_i)
   begin
      if rising_edge(clk_i) then
         de_in_valid <= '0';
         if m_ready_i = '1' then
            m_last_o  <= '0';
            m_valid_o <= '0';
         end if;

         case state is

            when IDLE_ST =>
               if s_valid_i = '1' and s_ready_o = '1' then
                  slv_data <= s_data_i;
                  first    <= '1';

                  m_data_o <= "0000";
                  if or (s_data_i) = '0' then
                     m_valid_o <= '1';
                     m_last_o  <= '1';
                  else
                     state <= BUSY_ST;
                  end if;
               end if;

            when BUSY_ST =>
               if m_ready_i = '1' or m_valid_o = '0' then
                  if slv_data >= pow_ten then
                     m_data_o <= m_data_o + 1;
                     slv_data <= slv_data - pow_ten;
                  else
                     if m_data_o /= "0000" or first = '0' then
                        m_valid_o <= '1';
                        first     <= '0';
                     end if;
                     if pow_ten = C_ONE then
                        m_last_o <= '1';
                        pow_ten  <= largest_pow_ten(G_DATA_SIZE);
                        state    <= IDLE_ST;
                     else
                        de_in_valid <= '1';
                        state       <= WAIT_ST;
                     end if;
                  end if;
               end if;

            when WAIT_ST =>
               if de_out_valid = '1' and de_out_ready = '1' then
                  pow_ten  <= de_out_res;
                  m_data_o <= "0000";
                  state    <= BUSY_ST;
               end if;

         end case;

         if rst_i = '1' then
            -- Initialize to one.
            pow_ten   <= largest_pow_ten(G_DATA_SIZE);
            state     <= IDLE_ST;
            m_valid_o <= '0';
            m_last_o  <= '0';
         end if;
      end if;
   end process fsm_proc;

   de_out_ready <= m_ready_i or not m_valid_o;

   divexact_inst : entity work.divexact
      generic map (
         G_DATA_SIZE => G_DATA_SIZE
      )
      port map (
         clk_i     => clk_i,
         rst_i     => rst_i,
         s_valid_i => de_in_valid,
         s_ready_o => de_in_ready,
         s_data1_i => pow_ten,
         s_data2_i => to_stdlogicvector(10, G_DATA_SIZE),
         m_valid_o => de_out_valid,
         m_ready_i => de_out_ready,
         m_data_o  => de_out_res
      ); -- divexact_inst

end architecture synthesis;

