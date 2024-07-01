library ieee;
   use ieee.std_logic_1164.all;
   use ieee.numeric_std_unsigned.all;

entity gf2_solver is
   generic (
      G_ROW_SIZE  : natural;
      G_USER_SIZE : natural
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

   type     state_type is (RESET_ST, IDLE_ST, SCAN_ST, INSERT_ST, REDUCE_ST, SOLVED_ST, LAST_ST);
   signal   state : state_type;

   signal   s_row       : std_logic_vector(G_ROW_SIZE - 1 downto 0);
   signal   s_user      : std_logic_vector(G_USER_SIZE - 1 downto 0);
   signal   m_user      : std_logic_vector(G_USER_SIZE - 1 downto 0);
   signal   row         : natural range 0 to G_ROW_SIZE - 1;
   signal   column      : natural range 0 to G_ROW_SIZE - 1;
   signal   inverse_row : std_logic_vector(G_ROW_SIZE - 1 downto 0);
   signal   num_rows    : natural range 0 to G_ROW_SIZE;

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

   pure function log2 (
      arg : natural
   ) return natural is
   begin
      --
      for i in 0 to arg loop
         if 2 ** i >= arg then
            return i;
         end if;
      end loop;

      return -1;
   end function log2;

   constant C_USER_RAM_ADDR_SIZE : natural    := log2(G_ROW_SIZE);
   constant C_USER_RAM_DATA_SIZE : natural    := G_USER_SIZE;
   signal   user_ram_a_addr      : std_logic_vector(C_USER_RAM_ADDR_SIZE - 1 downto 0);
   signal   user_ram_a_data      : std_logic_vector(C_USER_RAM_DATA_SIZE - 1 downto 0);
   signal   user_ram_a_we        : std_logic;
   signal   user_ram_b_addr      : std_logic_vector(C_USER_RAM_ADDR_SIZE - 1 downto 0);
   signal   user_ram_b_data      : std_logic_vector(C_USER_RAM_DATA_SIZE - 1 downto 0);

   constant C_INVERSE_RAM_ADDR_SIZE : natural := log2(G_ROW_SIZE);
   constant C_INVERSE_RAM_DATA_SIZE : natural := G_ROW_SIZE;
   signal   inverse_ram_a_addr      : std_logic_vector(C_INVERSE_RAM_ADDR_SIZE - 1 downto 0);
   signal   inverse_ram_a_data      : std_logic_vector(C_INVERSE_RAM_DATA_SIZE - 1 downto 0);
   signal   inverse_ram_a_we        : std_logic;
   signal   inverse_ram_b_addr      : std_logic_vector(C_INVERSE_RAM_ADDR_SIZE - 1 downto 0);
   signal   inverse_ram_b_data      : std_logic_vector(C_INVERSE_RAM_DATA_SIZE - 1 downto 0);

   constant C_MATRIX_RAM_ADDR_SIZE : natural  := log2(G_ROW_SIZE);
   constant C_MATRIX_RAM_DATA_SIZE : natural  := G_ROW_SIZE;
   signal   matrix_ram_a_addr      : std_logic_vector(C_MATRIX_RAM_ADDR_SIZE - 1 downto 0);
   signal   matrix_ram_a_data      : std_logic_vector(C_MATRIX_RAM_DATA_SIZE - 1 downto 0);
   signal   matrix_ram_a_we        : std_logic;
   signal   matrix_ram_b_addr      : std_logic_vector(C_MATRIX_RAM_ADDR_SIZE - 1 downto 0);
   signal   matrix_ram_b_data      : std_logic_vector(C_MATRIX_RAM_DATA_SIZE - 1 downto 0);

begin

   s_ready_o       <= '1' when state = IDLE_ST and (m_valid_o = '0' or m_ready_i = '1') else
                      '0';

   user_ram_b_addr <= to_stdlogicvector(column, C_USER_RAM_ADDR_SIZE);

   user_ram_inst : entity work.ram
      generic map (
         G_ADDR_SIZE => C_USER_RAM_ADDR_SIZE,
         G_DATA_SIZE => C_USER_RAM_DATA_SIZE
      )
      port map (
         clk_i    => clk_i,
         rst_i    => rst_i,
         a_addr_i => user_ram_a_addr,
         a_data_i => user_ram_a_data,
         a_we_i   => user_ram_a_we,
         b_addr_i => user_ram_b_addr,
         b_data_o => user_ram_b_data
      ); -- user_ram_inst

   inverse_ram_b_addr <= to_stdlogicvector(row, C_INVERSE_RAM_ADDR_SIZE);

   inverse_ram_inst : entity work.ram
      generic map (
         G_ADDR_SIZE => C_INVERSE_RAM_ADDR_SIZE,
         G_DATA_SIZE => C_INVERSE_RAM_DATA_SIZE
      )
      port map (
         clk_i    => clk_i,
         rst_i    => rst_i,
         a_addr_i => inverse_ram_a_addr,
         a_data_i => inverse_ram_a_data,
         a_we_i   => inverse_ram_a_we,
         b_addr_i => inverse_ram_b_addr,
         b_data_o => inverse_ram_b_data
      ); -- inverse_ram_inst

   matrix_ram_b_addr <= to_stdlogicvector(row, C_MATRIX_RAM_ADDR_SIZE);

   matrix_ram_inst : entity work.ram
      generic map (
         G_ADDR_SIZE => C_MATRIX_RAM_ADDR_SIZE,
         G_DATA_SIZE => C_MATRIX_RAM_DATA_SIZE
      )
      port map (
         clk_i    => clk_i,
         rst_i    => rst_i,
         a_addr_i => matrix_ram_a_addr,
         a_data_i => matrix_ram_a_data,
         a_we_i   => matrix_ram_a_we,
         b_addr_i => matrix_ram_b_addr,
         b_data_o => matrix_ram_b_data
      ); -- matrix_ram_inst

   fsm_proc : process (clk_i)
      variable index_v       : natural range 0 to G_ROW_SIZE - 1;
      variable inverse_row_v : std_logic_vector(G_ROW_SIZE - 1 downto 0);
   begin
      if rising_edge(clk_i) then
         user_ram_a_we    <= '0';
         inverse_ram_a_we <= '0';
         if m_ready_i = '1' then
            m_last_o  <= '0';
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
               if s_row(column) = '1' and matrix_ram_b_data(column) = '1' then
                  s_row       <= s_row xor matrix_ram_b_data;
                  inverse_row <= inverse_row xor inverse_ram_b_data;
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
                  index_v                := leading_index(s_row);

                  insert_2 : assert s_row(index_v) = '1' or rst_i = '1';
--                  insert_3 : assert matrix(index_v)(index_v) = '0' or rst_i = '1';
                  insert_4 : assert inverse_row(index_v) = '0' or rst_i = '1';
                  matrix_ram_a_addr      <= to_stdlogicvector(index_v, C_MATRIX_RAM_ADDR_SIZE);
                  matrix_ram_a_data      <= s_row;
                  matrix_ram_a_we        <= '1';
                  user_ram_a_addr        <= to_stdlogicvector(index_v, C_USER_RAM_ADDR_SIZE);
                  user_ram_a_data        <= s_user;
                  user_ram_a_we          <= '1';
                  inverse_row(index_v)   <= '1';

                  inverse_row_v          := inverse_row;
                  inverse_row_v(index_v) := '1';

                  inverse_ram_a_addr     <= to_stdlogicvector(index_v, C_INVERSE_RAM_ADDR_SIZE);
                  inverse_ram_a_data     <= inverse_row_v;
                  inverse_ram_a_we       <= '1';

                  insert_5: assert num_rows < G_ROW_SIZE or rst_i = '1';
                  num_rows               <= num_rows + 1;
                  if index_v < G_ROW_SIZE - 1 then
                     column <= index_v;
                     row    <= index_v + 1;
                     state  <= REDUCE_ST;
                  else
                     state <= IDLE_ST;
                  end if;
               end if;

            when REDUCE_ST =>
               if matrix_ram_b_data(column) = '1' then
                  matrix_ram_a_addr  <= to_stdlogicvector(row, C_MATRIX_RAM_ADDR_SIZE);
                  matrix_ram_a_data  <= matrix_ram_b_data xor s_row;
                  matrix_ram_a_we    <= '1';

                  inverse_ram_a_addr <= to_stdlogicvector(row, C_INVERSE_RAM_ADDR_SIZE);
                  inverse_ram_a_data <= inverse_ram_b_data xor inverse_row;
                  inverse_ram_a_we   <= '1';
               end if;
               if row < G_ROW_SIZE - 1 then
                  row <= row + 1;
               else
                  state <= IDLE_ST;
               end if;

            when SOLVED_ST =>
               if m_valid_o = '0' or m_ready_i = '1' then
                  if inverse_row(column) = '1' then
                     m_user_o  <= m_user;
                     m_valid_o <= '1';
                     m_user    <= user_ram_b_data;
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

            when RESET_ST =>
               matrix_ram_a_addr  <= to_stdlogicvector(row, C_MATRIX_RAM_ADDR_SIZE);
               matrix_ram_a_data  <= (others => '0');
               matrix_ram_a_we    <= '1';
               inverse_ram_a_addr <= to_stdlogicvector(row, C_INVERSE_RAM_ADDR_SIZE);
               inverse_ram_a_data <= (others => '0');
               inverse_ram_a_we   <= '1';
               if row < G_ROW_SIZE - 1 then
                  row <= row + 1;
               else
                  state <= IDLE_ST;
               end if;

         end case;

         if rst_i = '1' then
            row       <= 0;
            m_user    <= (others => '0');
            m_last_o  <= '0';
            m_valid_o <= '0';
            state     <= RESET_ST;
            num_rows  <= 0;
         end if;
      end if;
   end process fsm_proc;

end architecture synthesis;

