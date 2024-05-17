library ieee;
   use ieee.std_logic_1164.all;
   use ieee.numeric_std_unsigned.all;

entity uart_wrapper is
   generic (
      G_N           : natural;
      G_K           : natural;
      G_T           : natural;
      G_B           : natural
   );
   port (
      clk_i           : in    std_logic;
      rst_i           : in    std_logic;
      uart_rx_valid_i : in    std_logic;
      uart_rx_ready_o : out   std_logic;
      uart_rx_data_i  : in    std_logic_vector(7 downto 0);
      uart_tx_valid_o : out   std_logic;
      uart_tx_ready_i : in    std_logic;
      uart_tx_data_o  : out   std_logic_vector(7 downto 0);
      valid_i         : in    std_logic;
      ready_o         : out   std_logic;
      result_i        : in    std_logic_vector(G_N*G_B-1 downto 0);
      done_i          : in    std_logic
   );
end entity uart_wrapper;

architecture synthesis of uart_wrapper is

   type     uart_tx_state_type is (IDLE_ST, ROW_ST, EOL_ST, END_ST);
   signal   uart_tx_state : uart_tx_state_type                := IDLE_ST;

   signal   row    : natural range 0 to G_B-1;
   signal   result : std_logic_vector(G_N*G_B-1 downto 0);

   signal   hex_valid : std_logic;
   signal   hex_ready : std_logic;
   signal   hex_data  : std_logic_vector(G_N - 1 downto 0);
   signal   ser_data  : std_logic_vector(8 * G_N - 1 downto 0);

   signal   eol_valid : std_logic;
   signal   eol_ready : std_logic;

   signal   uart_tx_hex_valid : std_logic;
   signal   uart_tx_hex_data  : std_logic_vector(7 downto 0);
   signal   uart_tx_eol_valid : std_logic;
   signal   uart_tx_eol_data  : std_logic_vector(7 downto 0);

begin

   uart_rx_ready_o <= '1';

   ready_o          <= '1' when uart_tx_state = IDLE_ST else
                       '0';

   uart_tx_proc : process (clk_i)
   begin
      if rising_edge(clk_i) then
         if hex_ready = '1' then
            hex_valid <= '0';
         end if;
         if eol_ready = '1' then
            eol_valid <= '0';
         end if;

         case uart_tx_state is

            when IDLE_ST =>
               if valid_i = '1' then
                  result        <= result_i;
                  row           <= 0;
                  uart_tx_state <= ROW_ST;
               end if;
               if done_i = '1' then
                  uart_tx_state <= END_ST;
               end if;

            when ROW_ST =>
               if hex_ready = '1' and eol_ready = '1' then
                  hex_data <= result(G_N*(row+1)-1 downto G_N*row);
                  hex_valid <= '1';
                  if row < G_B-1 then
                     row <= row + 1;
                  else
                     uart_tx_state <= EOL_ST;
                  end if;
               end if;

            when EOL_ST =>
               if hex_ready = '1' and hex_valid = '0' then
                  if eol_valid = '1' then
                     uart_tx_state <= IDLE_ST;
                  else
                     eol_valid <= '1';
                  end if;
               end if;

            when END_ST =>
               null;

         end case;

         if rst_i = '1' then
            uart_tx_state <= IDLE_ST;
         end if;
      end if;
   end process uart_tx_proc;

   stringifier_inst : entity work.stringifier
      generic map (
         G_DATA_BITS => G_N
      )
      port map (
         s_data_i => hex_data,
         m_data_o => ser_data
      ); -- stringifier_inst

   serializer_hex_inst : entity work.serializer
      generic map (
         G_DATA_SIZE_IN  => 8 * G_N + 16,
         G_DATA_SIZE_OUT => 8
      )
      port map (
         clk_i     => clk_i,
         rst_i     => rst_i,
         s_valid_i => hex_valid,
         s_ready_o => hex_ready,
         s_data_i  => ser_data & X"0D0A",
         m_valid_o => uart_tx_hex_valid,
         m_ready_i => uart_tx_ready_i,
         m_data_o  => uart_tx_hex_data
      ); -- serializer_hex_inst

   serializer_eol_inst : entity work.serializer
      generic map (
         G_DATA_SIZE_IN  => 16,
         G_DATA_SIZE_OUT => 8
      )
      port map (
         clk_i     => clk_i,
         rst_i     => rst_i,
         s_valid_i => eol_valid,
         s_ready_o => eol_ready,
         s_data_i  => X"0D0A",
         m_valid_o => uart_tx_eol_valid,
         m_ready_i => uart_tx_ready_i,
         m_data_o  => uart_tx_eol_data
      ); -- serializer_eol_inst

   uart_tx_valid_o <= uart_tx_hex_valid or uart_tx_eol_valid;
   uart_tx_data_o  <= uart_tx_hex_data  or uart_tx_eol_data;

end architecture synthesis;

