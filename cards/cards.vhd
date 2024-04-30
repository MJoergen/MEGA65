library ieee;
   use ieee.std_logic_1164.all;

entity cards is
   generic (
      G_PAIRS : natural := 4
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

   constant C_SIZE : natural                                   := 2 * G_PAIRS;

   signal   cards_all : std_logic_vector(C_SIZE * G_PAIRS - 1 downto 0);
   signal   cards_or  : std_logic_vector(C_SIZE * G_PAIRS - 1 downto 0);
   signal   invalid   : std_logic_vector(C_SIZE * G_PAIRS - 1 downto 0);

   constant C_ZERO_ROW : std_logic_vector(C_SIZE - 1 downto 0) := (others => '0');

   signal   done : std_logic;

begin

   done_o                        <= done;

   cards_o                       <= cards_all;
   cards_or_o                    <= cards_or;
   invalid_o                     <= invalid;

   valid_o                       <= '1' when invalid(C_SIZE * G_PAIRS - 1 downto C_SIZE * G_PAIRS - C_SIZE) = C_ZERO_ROW else
                                    '0';

   cards_or(C_SIZE - 1 downto 0) <= cards_all(C_SIZE - 1 downto 0);

   cards_or_gen : for row in 1 to G_PAIRS - 1 generate
      cards_or(row * C_SIZE + C_SIZE - 1 downto row * C_SIZE) <= cards_or((row - 1) * C_SIZE + C_SIZE - 1 downto (row - 1) * C_SIZE)
                                                                 or cards_all(row * C_SIZE + C_SIZE - 1 downto row * C_SIZE);
   end generate cards_or_gen;

   invalid(C_SIZE - 1 downto 0) <= C_ZERO_ROW;

   invalid_gen : for row in 1 to G_PAIRS - 1 generate
      invalid(row * C_SIZE + C_SIZE - 1 downto row * C_SIZE) <= invalid((row - 1) * C_SIZE + C_SIZE - 1 downto (row - 1) * C_SIZE)
                                                                or (cards_or((row - 1) * C_SIZE + C_SIZE - 1 downto (row - 1) * C_SIZE)
                                                                     and cards_all(row * C_SIZE + C_SIZE - 1 downto row * C_SIZE));
   end generate invalid_gen;

   calc_proc : process (clk_i)
   begin
      if rising_edge(clk_i) then
         if done = '0' and en_i = '1' then

            for row in G_PAIRS - 1 downto 0 loop
               if row = 0 then
                  if cards_all(row * C_SIZE + 0) = '0' then
                     cards_all(row * C_SIZE + C_SIZE - 1 downto row * C_SIZE) <= "0" &
                                                                                 cards_all(row * C_SIZE + C_SIZE - 1 downto row * C_SIZE + 1);
                     exit;
                  else
                     cards_all(row * C_SIZE + C_SIZE - 1 downto row * C_SIZE) <= C_ZERO_ROW;
                     cards_all(row * C_SIZE + C_SIZE - 1)                     <= '1';
                     cards_all(row * C_SIZE + C_SIZE - row - 3)               <= '1';
                     done                                                     <= '1';
                  end if;
               elsif cards_all(row * C_SIZE + 0) = '0' and
                     invalid((row - 1) * C_SIZE + C_SIZE - 1 downto (row - 1) * C_SIZE) = C_ZERO_ROW then
                  cards_all(row * C_SIZE + C_SIZE - 1 downto row * C_SIZE) <= "0" &
                                                                              cards_all(row * C_SIZE + C_SIZE - 1 downto row * C_SIZE + 1);
                  exit;
               else
                  cards_all(row * C_SIZE + C_SIZE - 1 downto row * C_SIZE) <= C_ZERO_ROW;
                  cards_all(row * C_SIZE + C_SIZE - 1)                     <= '1';
                  cards_all(row * C_SIZE + C_SIZE - row - 3)               <= '1';
               end if;
            end loop;

         end if; -- if done = '0' and en_i = '1' then

         if rst_i = '1' then
            cards_all <= (others => '0');

            for row in 0 to G_PAIRS - 1 loop
               cards_all(row * C_SIZE + C_SIZE - 1)       <= '1';
               cards_all(row * C_SIZE + C_SIZE - row - 3) <= '1';
            end loop;

            done <= '0';
         end if;
      end if;
   end process calc_proc;

end architecture behavioral;

