library ieee;
   use ieee.std_logic_1164.all;
   use ieee.numeric_std_unsigned.all;

entity tb_factor_vect is
end entity tb_factor_vect;

architecture simulation of tb_factor_vect is

   constant C_DATA_SIZE   : integer  := 8;
   constant C_VECTOR_SIZE : integer  := 8;

   signal   test_running : std_logic := '1';
   signal   clk          : std_logic := '1';
   signal   rst          : std_logic := '1';

   -- Signals conected to DUT
   signal   dut_s_ready    : std_logic;
   signal   dut_s_valid    : std_logic;
   signal   dut_s_data     : std_logic_vector(C_DATA_SIZE - 1 downto 0);
   signal   dut_m_ready    : std_logic;
   signal   dut_m_valid    : std_logic;
   signal   dut_m_complete : std_logic;
   signal   dut_m_square   : std_logic_vector(C_VECTOR_SIZE - 1 downto 0);
   signal   dut_m_primes   : std_logic_vector(C_VECTOR_SIZE - 1 downto 0);

begin

   clk <= test_running and not clk after 5 ns;
   rst <= '1', '0' after 100 ns;


   --------------------------------------------------
   -- Instantiate DUT
   --------------------------------------------------

   factor_vect_inst : entity work.factor_vect
      generic map (
         G_DATA_SIZE   => C_DATA_SIZE,
         G_VECTOR_SIZE => C_VECTOR_SIZE
      )
      port map (
         clk_i        => clk,
         rst_i        => rst,
         s_ready_o    => dut_s_ready,
         s_valid_i    => dut_s_valid,
         s_data_i     => dut_s_data,
         m_ready_i    => dut_m_ready,
         m_valid_o    => dut_m_valid,
         m_complete_o => dut_m_complete,
         m_square_o   => dut_m_square,
         m_primes_o   => dut_m_primes
      ); -- factor_vect_inst


   --------------------------------------------------
   -- Main test procedure starts here
   --------------------------------------------------

   main_test_proc : process
      procedure verify (
         arg      : natural;
         res      : std_logic_vector;
         square   : natural;
         complete : std_logic
      ) is
      begin
         report "verify " & to_string(arg);
         dut_s_data  <= to_stdlogicvector(arg, C_DATA_SIZE);
         dut_s_valid <= '1';
         wait until clk = '1';
         dut_s_valid <= '0';

         while dut_m_valid = '0' loop
            wait until clk = '1';
         end loop;

         assert dut_m_primes = res;
         assert to_integer(dut_m_square) = square;
         assert dut_m_complete = complete;
      end procedure verify;

   begin
      -- Wait until reset is complete
      dut_s_valid  <= '0';
      dut_m_ready  <= '1';
      wait until rst = '0';
      wait until clk = '1';

      verify(  2, "00000001", 1, '1');
      verify(  3, "00000010", 1, '1');
      verify(  5, "00000100", 1, '1');
      verify(  7, "00001000", 1, '1');
      verify( 11, "00010000", 1, '1');
      verify( 13, "00100000", 1, '1');
      verify( 17, "01000000", 1, '1');
      verify( 19, "10000000", 1, '1');
      verify( 23, "00000000", 1, '0');

      verify(  4, "00000000", 2, '1'); -- 2^2
      verify(  8, "00000001", 2, '1'); -- 2^3
      verify( 16, "00000000", 4, '1'); -- 2^4
      verify( 32, "00000001", 4, '1'); -- 2^5
      verify( 64, "00000000", 8, '1'); -- 2^6
      verify(128, "00000001", 8, '1'); -- 2^7

      verify(  9, "00000000", 3, '1'); -- 3^2
      verify( 27, "00000010", 3, '1'); -- 3^3
      verify( 81, "00000000", 9, '1'); -- 3^4
      verify(243, "00000010", 9, '1'); -- 3^5

      verify(  6, "00000011", 1, '1'); -- 2*3
      verify( 15, "00000110", 1, '1'); -- 3*5
      verify( 35, "00001100", 1, '1'); -- 5*7
      verify( 77, "00011000", 1, '1'); -- 7*11
      verify(143, "00110000", 1, '1'); -- 11*13
      verify(221, "01100000", 1, '1'); -- 13*17

      verify( 10, "00000101", 1, '1'); -- 2*5
      verify( 20, "00000100", 2, '1'); -- 2^2*5
      verify( 30, "00000111", 1, '1'); -- 2*3*5
      verify( 40, "00000101", 2, '1'); -- 2^3*5
      verify( 50, "00000001", 5, '1'); -- 2*5^2
      verify( 90, "00000101", 3, '1'); -- 2*3^2*5

      verify( 36, "00000000", 6, '1'); -- 2^2 * 3^2

      wait for 2 us;

      -- Stop test
      wait until clk = '1';
      report "Test completed";
      test_running <= '0';
      wait;
   end process main_test_proc;

end architecture simulation;

