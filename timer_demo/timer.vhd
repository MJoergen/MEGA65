library ieee;
   use ieee.std_logic_1164.all;
   use ieee.numeric_std_unsigned.all;

entity timer is
   port (
      clk_i       : in    std_logic;
      rst_i       : in    std_logic;
      step_i      : in    std_logic;
      timer_h10_o : out   std_logic_vector(3 downto 0);
      timer_h1_o  : out   std_logic_vector(3 downto 0);
      timer_m10_o : out   std_logic_vector(3 downto 0);
      timer_m1_o  : out   std_logic_vector(3 downto 0);
      timer_s10_o : out   std_logic_vector(3 downto 0);
      timer_s1_o  : out   std_logic_vector(3 downto 0)
   );

end entity timer;

architecture structural of timer is

   signal   timer_h10 : std_logic_vector(3 downto 0);
   signal   timer_h1  : std_logic_vector(3 downto 0);
   signal   timer_m10 : std_logic_vector(3 downto 0);
   signal   timer_m1  : std_logic_vector(3 downto 0);
   signal   timer_s10 : std_logic_vector(3 downto 0);
   signal   timer_s1  : std_logic_vector(3 downto 0);

   constant C_ZERO  : std_logic_vector(3 downto 0) := "0000";
   constant C_ONE   : std_logic_vector(3 downto 0) := "0001";
   constant C_TWO   : std_logic_vector(3 downto 0) := "0010";
   constant C_THREE : std_logic_vector(3 downto 0) := "0011";
   constant C_FIVE  : std_logic_vector(3 downto 0) := "0101";
   constant C_NINE  : std_logic_vector(3 downto 0) := "1001";

begin

   timer_h10_o <= timer_h10;
   timer_h1_o  <= timer_h1;
   timer_m10_o <= timer_m10;
   timer_m1_o  <= timer_m1;
   timer_s10_o <= timer_s10;
   timer_s1_o  <= timer_s1;

   timer_proc : process (clk_i)
   begin
      if rising_edge(clk_i) then
         if step_i = '1' then
            if timer_s1 < C_NINE then
               timer_s1 <= timer_s1 + C_ONE;
            else
               timer_s1 <= C_ZERO;
               if timer_s10 < C_FIVE then
                  timer_s10 <= timer_s10 + C_ONE;
               else
                  timer_s10 <= C_ZERO;
                  if timer_m1 < C_NINE then
                     timer_m1 <= timer_m1 + C_ONE;
                  else
                     timer_m1 <= C_ZERO;
                     if timer_m10 < C_FIVE then
                        timer_m10 <= timer_m10 + C_ONE;
                     else
                        timer_m10 <= C_ZERO;
                        if (timer_h10 < C_TWO and timer_h1 < C_NINE) or (timer_h10 = C_TWO and timer_h1 < C_THREE) then
                           timer_h1 <= timer_h1 + C_ONE;
                        else
                           timer_h1 <= C_ZERO;
                           if timer_h10 < C_TWO then
                              timer_h10 <= timer_h10 + C_ONE;
                           else
                              timer_h10 <= C_ZERO;
                           end if;
                        end if;
                     end if;
                  end if;
               end if;
            end if;
         end if;

         if rst_i = '1' then
            timer_h10 <= (others => '0');
            timer_h1  <= (others => '0');
            timer_m10 <= (others => '0');
            timer_m1  <= (others => '0');
            timer_s10 <= (others => '0');
            timer_s1  <= (others => '0');
         end if;
      end if;
   end process timer_proc;

end architecture structural;

