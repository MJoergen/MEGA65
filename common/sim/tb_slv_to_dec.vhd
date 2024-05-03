library ieee;
   use ieee.std_logic_1164.all;
   use ieee.numeric_std_unsigned.all;

entity tb_slv_to_dec is
end entity tb_slv_to_dec;

architecture simulation of tb_slv_to_dec is

   constant C_SIZE : integer    := 16;

   signal   running : std_logic := '1';
   signal   rst     : std_logic := '1';
   signal   clk     : std_logic := '1';

   signal   slv_valid : std_logic;
   signal   slv_ready : std_logic;
   signal   slv_data  : std_logic_vector(C_SIZE - 1 downto 0);
   signal   dec_valid : std_logic;
   signal   dec_last  : std_logic;
   signal   dec_ready : std_logic;
   signal   dec_data  : std_logic_vector(3 downto 0);

   signal   res : integer;

   signal   lfsr_output : std_logic_vector(7 downto 0);

begin

   rst <= '1', '0' after 100 ns;
   clk <= running and not clk after 5 ns;

   slv_to_dec_inst : entity work.slv_to_dec
      generic map (
         G_SIZE => C_SIZE
      )
      port map (
         clk_i       => clk,
         rst_i       => rst,
         slv_valid_i => slv_valid,
         slv_ready_o => slv_ready,
         slv_data_i  => slv_data,
         dec_valid_o => dec_valid,
         dec_ready_i => dec_ready,
         dec_data_o  => dec_data,
         dec_last_o  => dec_last
      );

   lfsr_inst : entity work.lfsr
      generic map (
         G_TAPS  => X"000000000000008E",
         G_WIDTH => 8
      )
      port map (
         clk_i      => clk,
         rst_i      => rst,
         update_i   => '1',
         load_i     => '0',
         load_val_i => (others => '0'),
         output_o   => lfsr_output
      );

   dec_ready <= and(lfsr_output(2 downto 0));

   test_proc : process
      --

      procedure verify (
         arg : integer
      ) is
      begin
         slv_data  <= to_stdlogicvector(arg, C_SIZE);
         slv_valid <= '1';
         wait until clk = '1';

         while slv_ready /= '1' loop
            wait until clk = '1';
         end loop;

         slv_valid <= '0';

         res       <= 0;

         loop
            --
            while dec_valid /= '1' or dec_ready /= '1' loop
               wait until clk = '1';
            end loop;

            assert to_integer(dec_data) < 10;

            res <= res * 10 + to_integer(dec_data);
            if dec_last = '1' then
               wait until clk = '1';
               report "slv_to_dec(" & integer'image(arg)
                      & ") -> " & integer'image(res);
               assert res = arg;
               exit;
            end if;
            wait until clk = '1';
         end loop;

      --
      end procedure verify;

   --
   begin
      slv_valid <= '0';
      wait until rst = '0';
      wait for 100 ns;
      wait until clk = '1';

      verify(0);
      verify(1);
      verify(2);
      verify(9);
      verify(10);
      verify(11);
      verify(12);
      verify(20);
      verify(21);
      verify(22);
      verify(99);
      verify(100);
      verify(101);
      verify(102);
      verify(190);
      verify(199);
      verify(909);
      verify(999);

      wait for 1000 ns;

      running   <= '0';
      report "End of test";
      wait;
   end process test_proc;

end architecture simulation;

