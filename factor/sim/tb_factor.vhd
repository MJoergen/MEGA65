library ieee;
   use ieee.std_logic_1164.all;
   use ieee.numeric_std_unsigned.all;

entity tb_factor is
   generic (
      G_DATA_SIZE   : natural;
      G_VECTOR_SIZE : natural
   );
end entity tb_factor;

architecture simulation of tb_factor is

   signal running      : std_logic := '1';
   signal clk          : std_logic := '1';
   signal rst          : std_logic := '1';
   signal dut_s_start  : std_logic;
   signal dut_s_val    : std_logic_vector(2 * G_DATA_SIZE - 1 downto 0);
   signal dut_m_ready  : std_logic;
   signal dut_m_valid  : std_logic;
   signal dut_m_square : std_logic_vector(G_DATA_SIZE - 1 downto 0);
   signal dut_m_last   : std_logic;

   constant C_N : natural := 4559;

   -- Other numbers to try:
   --  2059 =  29 *  71
   --  4559 =  47 *  97
   -- 19549 = 113 * 173
   -- 26329 = 113 * 233
   -- 35119 = 173 * 203
   -- 40309 = 173 * 233

begin

   rst <= '1', '0' after 100 ns;
   clk <= running and not clk after 5 ns;

   factor_inst : entity work.factor
      generic map (
         G_DATA_SIZE   => G_DATA_SIZE,
         G_VECTOR_SIZE => G_VECTOR_SIZE
      )
      port map (
         clk_i      => clk,
         rst_i      => rst,
         s_start_i  => dut_s_start,
         s_val_i    => dut_s_val,
         m_ready_i  => dut_m_ready,
         m_valid_o  => dut_m_valid,
         m_square_o => dut_m_square,
         m_last_o   => dut_m_last
      ); -- factor_inst

   test_proc : process
   begin
      dut_m_ready <= '1';
      dut_s_start <= '0';
      wait until rst = '0';
      wait for 1 us;
      wait until clk = '1';

      report "Test started, N = " & to_string(C_N);
      dut_s_start <= '1';
      dut_s_val   <= to_stdlogicvector(C_N, 2 * G_DATA_SIZE);
      wait until clk = '1';
      dut_s_start <= '0';

      wait for 100 us;
      running     <= '0';
      report "Test finished";
      wait;
   end process test_proc;

end architecture simulation;

