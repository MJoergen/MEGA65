library ieee;
   use ieee.std_logic_1164.all;
   use ieee.numeric_std.all;

entity controller is
   port (
      clk_i      : in    std_logic;
      rst_i      : in    std_logic;
      rx_valid_i : in    std_logic;
      rx_ready_o : out   std_logic;
      rx_data_i  : in    std_logic_vector(7 downto 0);
      valid_i    : in    std_logic;
      step_o     : out   std_logic
   );
end entity controller;

architecture synthesis of controller is

   type   state_type is (IDLE_ST, CONTINUE_ST, END_ST);
   signal state : state_type := IDLE_ST;

begin

   rx_ready_o <= '1' when state = IDLE_ST else
                 '0';

   fsm_proc : process (clk_i)
   begin
      if rising_edge(clk_i) then
         step_o <= '0';

         case state is

            when IDLE_ST =>
               if rx_valid_i = '1' then

                  case rx_data_i is

                     when X"53" | X"73" =>
                        step_o <= '1';

                     when X"43" | X"63" =>
                        step_o <= '1';
                        state  <= CONTINUE_ST;

                     when X"45" | X"65" =>
                        step_o <= '1';
                        state  <= END_ST;

                     when others =>
                        null;

                  end case;

               end if;

            when CONTINUE_ST =>
               if valid_i = '1' then
                  state <= IDLE_ST;
               else
                  step_o <= '1';
               end if;

            when END_ST =>
               step_o <= '1';

         end case;

         if rst_i = '1' then
            state <= IDLE_ST;
         end if;
      end if;
   end process fsm_proc;

end architecture synthesis;

