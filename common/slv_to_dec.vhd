library ieee;
   use ieee.std_logic_1164.all;
   use ieee.numeric_std_unsigned.all;

entity slv_to_dec is
   generic (
      G_SIZE : integer
   );
   port (
      clk_i       : in    std_logic;
      rst_i       : in    std_logic;

      slv_valid_i : in    std_logic;
      slv_ready_o : out   std_logic;
      slv_data_i  : in    std_logic_vector(G_SIZE - 1 downto 0);
      dec_valid_o : out   std_logic;
      dec_last_o  : out   std_logic;
      dec_ready_i : in    std_logic;
      dec_data_o  : out   std_logic_vector(3 downto 0)
   );
end entity slv_to_dec;

architecture synthesis of slv_to_dec is

   type   state_type is (INIT_ST, IDLE_ST, BUSY_ST, WAIT_ST);
   signal state : state_type := INIT_ST;
   signal first : std_logic;

   signal pow_ten  : std_logic_vector(G_SIZE - 1 downto 0) := (others => '0');
   signal slv_data : std_logic_vector(G_SIZE - 1 downto 0);

   signal de_start : std_logic;
   signal de_res   : std_logic_vector(G_SIZE - 1 downto 0);
   signal de_valid : std_logic;
   signal de_ready : std_logic;

begin

   slv_ready_o <= '1' when state = IDLE_ST else
                  '0';

   fsm_proc : process (clk_i)
   begin
      if rising_edge(clk_i) then
         de_start   <= '0';
         if dec_ready_i = '1' then
            dec_last_o <= '0';
            dec_valid_o <= '0';
         end if;

         case state is

            when INIT_ST =>
               if pow_ten(G_SIZE - 1 downto G_SIZE - 3) = "000" then
                  pow_ten <= (pow_ten(G_SIZE - 4 downto 0) & "000") + (pow_ten(G_SIZE - 2 downto 0) & "0");
               else
                  state <= IDLE_ST;
               end if;

            when IDLE_ST =>
               if slv_valid_i = '1' then
                  slv_data   <= slv_data_i;
                  first      <= '1';

                  dec_data_o <= "0000";
                  if or (slv_data_i) = '0' then
                     dec_valid_o <= '1';
                     dec_last_o  <= '1';
                  else
                     state <= BUSY_ST;
                  end if;
               end if;

            when BUSY_ST =>
               if dec_ready_i = '1' or dec_valid_o = '0' then
                  if slv_data >= pow_ten then
                     dec_data_o <= dec_data_o + 1;
                     slv_data   <= slv_data - pow_ten;
                  else
                     if dec_data_o /= "0000" or first = '0' then
                        dec_valid_o <= '1';
                        first       <= '0';
                     end if;
                     if or (pow_ten(G_SIZE - 1 downto 1)) = '0' then
                        dec_last_o <= '1';
                        pow_ten    <= (0 => '1', others => '0');                                               -- Initialize to one.
                        state      <= INIT_ST;
                     else
                        de_start <= '1';
                        state    <= WAIT_ST;
                     end if;
                  end if;
               end if;

            when WAIT_ST =>
               if dec_ready_i = '1' or dec_valid_o = '0' then
                  if de_valid = '1' then
                     pow_ten    <= de_res;
                     dec_data_o <= "0000";
                     state      <= BUSY_ST;
                  end if;
               end if;

         end case;

         if rst_i = '1' then
            pow_ten <= (0 => '1', others => '0');                                                           -- Initialize to one.
            state   <= INIT_ST;
         end if;
      end if;
   end process fsm_proc;

   de_ready <= dec_ready_i or not dec_valid_o;

   divexact_inst : entity work.divexact
      generic map (
         G_VAL_SIZE => G_SIZE
      )
      port map (
         clk_i   => clk_i,
         rst_i   => rst_i,
         val1_i  => pow_ten,
         val2_i  => to_stdlogicvector(10, G_SIZE),
         start_i => de_start,
         res_o   => de_res,
         valid_o => de_valid,
         ready_i => de_ready
      );

end architecture synthesis;

