library ieee;
   use ieee.std_logic_1164.all;
   use ieee.numeric_std_unsigned.all;

entity gf2_solver is
   generic (
      G_ROW_SIZE  : integer;
      G_USER_SIZE : integer
   );
   port (
      clk_i     : in    std_logic;
      rst_i     : in    std_logic;
      s_ready_o : out   std_logic;
      s_valid_i : in    std_logic;
      s_row_i   : in    std_logic_vector(G_ROW_SIZE - 1 downto 0);
      s_user_i  : in    std_logic_vector(G_USER_SIZE - 1 downto 0);
      m_ready_i : in    std_logic;
      m_valid_o : out   std_logic;
      m_user_o  : out   std_logic_vector(G_USER_SIZE - 1 downto 0);
      m_last_o  : out   std_logic
   );
end entity gf2_solver;

architecture synthesis of gf2_solver is

   -- In this initial implementation, this will just be a large array of registers.
   -- Later, this can be refactored to use BRAMs or LUTRAMs.
   type   matrix_type is array (natural range <>) of std_logic_vector(G_ROW_SIZE - 1 downto 0);
   signal matrix  : matrix_type(0 to G_ROW_SIZE - 1) := (others => (others => '0'));
   signal inverse : matrix_type(0 to G_ROW_SIZE - 1) := (others => (others => '0'));

   type   user_type is array (natural range <>) of std_logic_vector(G_USER_SIZE - 1 downto 0);
   signal user : user_type(0 to G_ROW_SIZE - 1)      := (others => (others => '0'));

   type   state_type is (IDLE_ST, SCAN_ST, INSERT_ST, REDUCE_ST, SOLVED_ST, LAST_ST);
   signal state : state_type;

   signal s_row       : std_logic_vector(G_ROW_SIZE - 1 downto 0);
   signal s_user      : std_logic_vector(G_USER_SIZE - 1 downto 0);
   signal m_user      : std_logic_vector(G_USER_SIZE - 1 downto 0);
   signal row         : natural range 0 to G_ROW_SIZE - 1;
   signal column      : natural range 0 to G_ROW_SIZE - 1;
   signal inverse_row : std_logic_vector(G_ROW_SIZE - 1 downto 0);

   pure function leading_index (
      arg : std_logic_vector
   ) return natural is
   begin
      for i in arg'range loop
         if arg(i) = '1' then
            return i;
         end if;
      end loop;
      return 0; -- This should never occur
   end function leading_index;

begin

   s_ready_o <= '1' when state = IDLE_ST and m_ready_i = '1' else
                '0';

   fsm_proc : process (clk_i)
      variable index_v : natural range 0 to G_ROW_SIZE - 1;
   begin
      if rising_edge(clk_i) then
         if m_ready_i = '1' then
            m_valid_o <= '0';
         end if;

         case state is

            when IDLE_ST =>
               if s_valid_i = '1' and s_ready_o = '1' then
                  if s_row_i = 0 then
                     m_user_o  <= s_user_i;
                     m_last_o  <= '1';
                     m_valid_o <= '1';
                     state     <= IDLE_ST;
                  else
                     idle : assert s_row_i /= 0 or rst_i = '1';
                     s_row       <= s_row_i;
                     s_user      <= s_user_i;
                     inverse_row <= (others => '0');
                     row         <= G_ROW_SIZE - 1;
                     column      <= G_ROW_SIZE - 1;
                     state       <= SCAN_ST;
                  end if;
               end if;

            when SCAN_ST =>
               scan : assert row = column or rst_i = '1';
               -- First we scan through the new row, and simplify with
               -- existing rows.
               if s_row(column) = '1' and matrix(row)(column) = '1' then
                  s_row       <= s_row xor matrix(row);
                  inverse_row <= inverse_row xor inverse(column);
               end if;

               if column > 0 then
                  column <= column - 1;
                  row    <= row - 1;
               else
                  state <= INSERT_ST;
               end if;

            when INSERT_ST =>
               if s_row = 0 then
                  m_user <= s_user;
                  column <= G_ROW_SIZE - 1;
                  state  <= SOLVED_ST;
               else
                  insert_1 : assert s_row /= 0 or rst_i = '1';
                  -- Now we insert the new row into an empty spot in the matrix
                  index_v                   := leading_index(s_row);

                  insert_2 : assert s_row(index_v) = '1' or rst_i = '1';
                  insert_3 : assert matrix(index_v)(index_v) = '0' or rst_i = '1';
                  insert_4 : assert inverse_row(index_v) = '0' or rst_i = '1';
                  matrix(index_v)           <= s_row;
                  user(index_v)             <= s_user;
                  inverse(index_v)          <= inverse_row;
                  inverse(index_v)(index_v) <= '1';
                  column                    <= index_v;
                  row                       <= index_v;
                  state                     <= REDUCE_ST;
               end if;

            when REDUCE_ST =>
               --
               for i in 0 to G_ROW_SIZE - 1 loop
                  if matrix(i)(column) = '1' and i /= row then
                     matrix(i)  <= matrix(i) xor matrix(row);
                     inverse(i) <= inverse(i) xor inverse(row);
                  end if;
               end loop;

               state <= IDLE_ST;

            when SOLVED_ST =>
               if m_valid_o = '0' or m_ready_i = '1' then
                  if inverse_row(column) = '1' then
                     m_user_o  <= m_user;
                     m_valid_o <= '1';
                     m_user    <= user(column);
                  end if;
                  if column > 0 then
                     column <= column - 1;
                  else
                     state <= LAST_ST;
                  end if;
               end if;

            when LAST_ST =>
               if m_valid_o = '0' or m_ready_i = '1' then
                  m_user_o  <= m_user;
                  m_last_o  <= '1';
                  m_valid_o <= '1';
                  state     <= IDLE_ST;
               end if;

         end case;

         if rst_i = '1' then
            for i in 0 to G_ROW_SIZE-1 loop
               matrix(i) <= (others => '0');
               inverse(i) <= (others => '0');
            end loop;
            m_user    <= (others => '0');
            m_last_o  <= '0';
            m_valid_o <= '0';
            state     <= IDLE_ST;
         end if;
      end if;
   end process fsm_proc;

end architecture synthesis;

