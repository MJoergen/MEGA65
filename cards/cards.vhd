library ieee;
   use ieee.std_logic_1164.all;

entity cards is
   generic (
      G_PAIRS : integer := 4
   );
   port (
      clk_i      : in    std_logic;
      rst_i      : in    std_logic;
      en_i       : in    std_logic;
      cards_o    : out   std_logic_vector(2 * G_PAIRS * G_PAIRS - 1 downto 0);
      cards_or_o : out   std_logic_vector(2 * G_PAIRS * G_PAIRS - 1 downto 0);
      invalid_o  : out   std_logic_vector(2 * G_PAIRS * G_PAIRS - 1 downto 0);
      valid_o    : out   std_logic;
      done_o     : out   std_logic
   );
end entity cards;

architecture behavioral of cards is

   signal   cards    : std_logic_vector(2 * G_PAIRS * G_PAIRS - 1 downto 0);
   signal   cards_or : std_logic_vector(2 * G_PAIRS * G_PAIRS - 1 downto 0);
   signal   invalid  : std_logic_vector(2 * G_PAIRS * G_PAIRS - 1 downto 0);

   constant C_ZERO_ROW : std_logic_vector(2 * G_PAIRS - 1 downto 0) := (others => '0');

   signal   done : std_logic;

begin

   done_o                             <= done;

   cards_o                            <= cards;
   cards_or_o                         <= cards_or;
   invalid_o                          <= invalid;

   valid_o                            <= '1' when invalid(2 * G_PAIRS * G_PAIRS - 1 downto 2 * G_PAIRS * G_PAIRS - 2 * G_PAIRS) = C_ZERO_ROW else
                                         '0';

   cards_or(2 * G_PAIRS - 1 downto 0) <= cards(2 * G_PAIRS - 1 downto 0);

   cards_or_gen : for row in 1 to G_PAIRS - 1 generate
      cards_or(row * 2 * G_PAIRS + 2 * G_PAIRS - 1 downto row * 2 * G_PAIRS) <= cards_or((row - 1) * 2 * G_PAIRS + 2 * G_PAIRS - 1 downto (row - 1) * 2 * G_PAIRS)
                                                                                or cards(row * 2 * G_PAIRS + 2 * G_PAIRS - 1 downto row * 2 * G_PAIRS);
   end generate cards_or_gen;

   invalid(2 * G_PAIRS - 1 downto 0) <= C_ZERO_ROW;

   invalid_gen : for row in 1 to G_PAIRS - 1 generate
      invalid(row * 2 * G_PAIRS + 2 * G_PAIRS - 1 downto row * 2 * G_PAIRS) <= invalid((row - 1) * 2 * G_PAIRS + 2 * G_PAIRS - 1 downto (row - 1) * 2 * G_PAIRS)
                                                                               or (cards_or((row - 1) * 2 * G_PAIRS + 2 * G_PAIRS - 1 downto (row - 1) * 2 * G_PAIRS)
                                                                                    and cards(row * 2 * G_PAIRS + 2 * G_PAIRS - 1 downto row * 2 * G_PAIRS));
   end generate invalid_gen;

   calc_proc : process (clk_i)
   begin
      if rising_edge(clk_i) then
         if done = '0' and en_i = '1' then

            for row in G_PAIRS - 1 downto 0 loop
               if row = 0 then
                  if cards(row * 2 * G_PAIRS + 0) = '0' then
                     cards(row * 2 * G_PAIRS + 2 * G_PAIRS - 1 downto row * 2 * G_PAIRS) <= "0" & cards(row * 2 * G_PAIRS + 2 * G_PAIRS - 1 downto row * 2 * G_PAIRS + 1);
                     exit;
                  else
                     cards(row * 2 * G_PAIRS + 2 * G_PAIRS - 1 downto row * 2 * G_PAIRS)
                                                                      <= C_ZERO_ROW;
                     cards(row * 2 * G_PAIRS + 2 * G_PAIRS - 1)       <= '1';
                     cards(row * 2 * G_PAIRS + 2 * G_PAIRS - row - 3) <= '1';
                     done                                             <= '1';
                  end if;
               elsif cards(row * 2 * G_PAIRS + 0) = '0' and
                     invalid((row - 1) * 2 * G_PAIRS + 2 * G_PAIRS - 1 downto (row - 1) * 2 * G_PAIRS) = C_ZERO_ROW then
                  cards(row * 2 * G_PAIRS + 2 * G_PAIRS - 1 downto row * 2 * G_PAIRS) <= "0" & cards(row * 2 * G_PAIRS + 2 * G_PAIRS - 1 downto row * 2 * G_PAIRS + 1);
                  exit;
               else
                  cards(row * 2 * G_PAIRS + 2 * G_PAIRS - 1 downto row * 2 * G_PAIRS) <= C_ZERO_ROW;
                  cards(row * 2 * G_PAIRS + 2 * G_PAIRS - 1)                          <= '1';
                  cards(row * 2 * G_PAIRS + 2 * G_PAIRS - row - 3)                    <= '1';
               end if;
            end loop;

         end if; -- if done = '0' and en_i = '1' then

         if rst_i = '1' then

            for row in 0 to G_PAIRS - 1 loop
               cards(row * 2 * G_PAIRS + 2 * G_PAIRS - 1 downto row * 2 * G_PAIRS) <= C_ZERO_ROW;
               cards(row * 2 * G_PAIRS + 2 * G_PAIRS - 1)                          <= '1';
               cards(row * 2 * G_PAIRS + 2 * G_PAIRS - row - 3)                    <= '1';
            end loop;

            done <= '0';
         end if;
      end if;
   end process calc_proc;

end architecture behavioral;

