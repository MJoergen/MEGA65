library ieee;
   use ieee.std_logic_1164.all;
   use ieee.numeric_std_unsigned.all;

entity controller is
   generic (
      G_N           : natural;
      G_K           : natural;
      G_T           : natural;
      G_RESULT_SIZE : integer
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
      result_i        : in    std_logic_vector(G_RESULT_SIZE downto 0);
      valid_i         : in    std_logic;
      done_i          : in    std_logic;
      step_o          : out   std_logic
   );
end entity controller;

architecture synthesis of controller is

   pure function binom (
      n : natural;
      k : natural
   ) return natural is
      variable res_v : natural := 1;
   begin
      for i in 1 to k loop
         res_v := (res_v * (n + 1 - i)) / i; -- This division will never cause fractions
      end loop;
      return res_v;
   end function binom;

   -- Each row has length "n".
   type     ram_type is array (natural range <>) of std_logic_vector(G_N - 1 downto 0);

   -- This calculates an array of all possible combinations of N choose K.

   pure function combination_init (
      n : natural;
      k : natural
   ) return ram_type is
      variable res_v : ram_type(G_RESULT_SIZE downto 0) := (others => (others => '0'));
      variable kk_v  : natural                          := k;
      variable ii_v  : natural                          := 0;
   begin
      report "combination_init: n=" & to_string(n) & ", k=" & to_string(k);
      loop_i : for i in 0 to G_RESULT_SIZE - 1 loop
         kk_v := k;
         ii_v := i;
         loop_j : for j in 0 to G_N - 1 loop
            if kk_v = 0 then
               exit loop_j;
            end if;
            if ii_v < binom(n - j - 1, kk_v - 1) then
               res_v(i)(G_N-1-j) := '1';
               kk_v        := kk_v - 1;
            else
               ii_v := ii_v - binom(n - j - 1, kk_v - 1);
            end if;
         end loop loop_j;
      end loop loop_i;
      report "combination_init done.";
      return res_v;
   end function combination_init;

   -- Each row contains exactly "k" ones, except the last which is just zero.
   constant C_COMBINATIONS : ram_type(G_RESULT_SIZE downto 0) := combination_init(G_N, G_K);

   type     uart_tx_state_type is (IDLE_ST, ROW_ST, EOL_ST, END_ST);
   signal   uart_tx_state : uart_tx_state_type                := IDLE_ST;

   signal   row    : natural range 0 to G_RESULT_SIZE;
   signal   result : std_logic_vector(G_RESULT_SIZE downto 0);

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

   step_o          <= '1' when uart_tx_state = IDLE_ST else
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
                  if result(row) = '1' then
                     hex_data  <= C_COMBINATIONS(row);
                     hex_valid <= '1';
                  end if;
                  if row < G_RESULT_SIZE then
                     row <= row + 1;
                  else
                     uart_tx_state <= EOL_ST;
                  end if;
               end if;

            when EOL_ST =>
               if hex_ready = '1' then
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

