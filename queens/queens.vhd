library ieee;
   use ieee.std_logic_1164.all;
   use ieee.numeric_std.all;

entity queens is
   generic (
      G_NUM_QUEENS : integer
   );
   port (
      clk_i   : in    std_logic;
      rst_i   : in    std_logic;
      en_i    : in    std_logic;
      board_o : out   std_logic_vector(G_NUM_QUEENS * G_NUM_QUEENS - 1 downto 0);
      valid_o : out   std_logic;
      done_o  : out   std_logic
   );
end entity queens;

architecture behavioral of queens is

   signal  board : std_logic_vector(G_NUM_QUEENS * G_NUM_QUEENS - 1 downto 0);
   signal  done  : std_logic;

   function or_all (
      v : std_logic_vector
   ) return std_logic is
      variable res_v : std_logic;
   begin
      res_v := '0';
      for i in v'range loop
         res_v := res_v or v(i);
      end loop;
      return res_v;
   end function or_all;

   subtype ROW_TYPE is std_logic_vector(G_NUM_QUEENS - 1 downto 0);

   type    row_vector_type is array(natural range <>) of ROW_TYPE;

   signal  row_or       : row_vector_type(G_NUM_QUEENS - 1 downto 0);
   signal  row_left_or  : row_vector_type(G_NUM_QUEENS - 1 downto 0);
   signal  row_right_or : row_vector_type(G_NUM_QUEENS - 1 downto 0);
   signal  valid        : std_logic_vector(G_NUM_QUEENS - 1 downto 0);

begin

   done_o          <= done;
   board_o         <= board;
   valid_o         <= valid(G_NUM_QUEENS - 1);

   row_or(0)       <= (others => '0');
   row_left_or(0)  <= (others => '0');
   row_right_or(0) <= (others => '0');
   valid(0)        <= '1';

   valid_gen : for row in 1 to G_NUM_QUEENS - 1 generate
      row_or(row)       <= row_or(row - 1)
                           or board((row - 1) * G_NUM_QUEENS + G_NUM_QUEENS - 1 downto (row - 1) * G_NUM_QUEENS);
      row_left_or(row)  <= "0" & (row_left_or(row - 1)(G_NUM_QUEENS - 1 downto 1)
                                  or board((row - 1) * G_NUM_QUEENS + G_NUM_QUEENS - 1 downto (row - 1) * G_NUM_QUEENS + 1));
      row_right_or(row) <= (row_right_or(row - 1)(G_NUM_QUEENS - 2 downto 0)
                           or board((row - 1) * G_NUM_QUEENS + G_NUM_QUEENS - 2 downto (row - 1) * G_NUM_QUEENS)) & "0";
      valid(row)        <= valid(row - 1) and not or_all((row_or(row) or row_left_or(row) or row_right_or(row))
                                                         and board(row * G_NUM_QUEENS + G_NUM_QUEENS - 1 downto row * G_NUM_QUEENS));
   end generate valid_gen;

   update_proc : process (clk_i)
   begin
      if rising_edge(clk_i) then
         if done = '0' and en_i = '1' then
            for row in G_NUM_QUEENS - 1 downto 0 loop
               if row = 0 or valid(row - 1) = '1' then
                  if board(row * G_NUM_QUEENS) = '0' then
                     board(row * G_NUM_QUEENS + G_NUM_QUEENS - 1 downto row *
                     G_NUM_QUEENS) <= "0" & board(row * G_NUM_QUEENS + G_NUM_QUEENS - 1
                                                  downto row * G_NUM_QUEENS + 1);
                     exit; -- the for loop
                  elsif row = 0 then
                     done <= '1';
                  end if;
               end if;
               board(row * G_NUM_QUEENS + G_NUM_QUEENS - 2 downto row * G_NUM_QUEENS) <= (others => '0');
               board(row * G_NUM_QUEENS + G_NUM_QUEENS - 1)                           <= '1';
            end loop;
         end if;

         if rst_i = '1' then
            for row in 0 to G_NUM_QUEENS - 1 loop
               board(row * G_NUM_QUEENS + G_NUM_QUEENS - 2 downto row * G_NUM_QUEENS) <= (others => '0');
               board(row * G_NUM_QUEENS + G_NUM_QUEENS - 1)                           <= '1';
            end loop;
            done <= '0';
         end if;
      end if;
   end process update_proc;

end architecture behavioral;

