library ieee;
   use ieee.std_logic_1164.all;
   use ieee.numeric_std_unsigned.all;

-- This is a self-verifying testbench for the Continued Fraction module.

entity tb_cf is
end entity tb_cf;

architecture simulation of tb_cf is

   constant C_DATA_SIZE : integer                    := 72;

   -- Signal to control execution of the testbench.
   signal   clk          : std_logic                 := '1';
   signal   rst          : std_logic                 := '1';
   signal   test_running : std_logic                 := '1';

   -- Signals conected to DUT
   signal   cf_s_start : std_logic;
   signal   cf_s_val_n : std_logic_vector(2 * C_DATA_SIZE - 1 downto 0);
   signal   cf_m_ready : std_logic;
   signal   cf_m_valid : std_logic;
   signal   cf_m_res_x : std_logic_vector(2 * C_DATA_SIZE - 1 downto 0);
   signal   cf_m_res_p : std_logic_vector(C_DATA_SIZE - 1 downto 0);
   signal   cf_m_res_w : std_logic;

   signal   ready_cnt : std_logic_vector(3 downto 0) := (others => '0');

begin

   clk        <= test_running and not clk after 5 ns;
   rst        <= '1', '0' after 100 ns;

   ready_cnt_proc : process (clk)
   begin
      if rising_edge(clk) then
         ready_cnt <= ready_cnt + 1;
      end if;
   end process ready_cnt_proc;

   cf_m_ready <= and(ready_cnt);


   --------------------------------------------------
   -- Instantiate DUT
   --------------------------------------------------

   cf_inst : entity work.cf
      generic map (
         G_DATA_SIZE => C_DATA_SIZE
      )
      port map (
         clk_i     => clk,
         rst_i     => rst,
         s_start_i => cf_s_start,
         s_val_i   => cf_s_val_n,
         m_ready_i => cf_m_ready,
         m_valid_o => cf_m_valid,
         m_res_x_o => cf_m_res_x,
         m_res_p_o => cf_m_res_p,
         m_res_w_o => cf_m_res_w
      ); -- cf_inst


   --------------------------------------------------
   -- Main test procedure starts here
   --------------------------------------------------

   main_test_proc : process

      type     res_type is record
         x : integer;
         y : integer;
      end record res_type;

      type     res_vector_type is array (natural range <>) of res_type;

      -- Verify CF processing

      procedure verify_cf (
         val_n : integer;
         res   : res_vector_type
      ) is
         variable exp_x_v : std_logic_vector(2 * C_DATA_SIZE - 1 downto 0);
         variable exp_p_v : std_logic_vector(C_DATA_SIZE - 1 downto 0);
         variable exp_w_v : std_logic;
      begin
         report "Verify CF: N=" & integer'image(val_n);

         cf_s_val_n <= to_stdlogicvector(val_n, 2 * C_DATA_SIZE);
         cf_s_start <= '1';
         wait until clk = '1';
         cf_s_start <= '0';
         wait until clk = '1';

         for i in 0 to res'length-1 loop
            report "Verifying response (" & integer'image(res(i).x) &
                   ", " & integer'image(res(i).y) & ")";

            -- Wait for next value
            wait until clk = '1';

            while (cf_m_valid and cf_m_ready) /= '1' loop
               wait until clk = '1';
            end loop;

            -- Verify received response is correct
            exp_x_v := to_stdlogicvector(res(i).x, 2 * C_DATA_SIZE);
            if res(i).y > 0 then
               exp_p_v := to_stdlogicvector(res(i).y, C_DATA_SIZE);
               exp_w_v := '0';
            else
               exp_p_v := to_stdlogicvector(-res(i).y, C_DATA_SIZE);
               exp_w_v := '1';
            end if;
            assert cf_m_res_x = exp_x_v and
                   cf_m_res_p = exp_p_v and
                   cf_m_res_w = exp_w_v
               report "Received (" & to_string(cf_m_res_x) & ", " & to_string(cf_m_res_w) & ", " & to_string(cf_m_res_p) & ")";

         --
         end loop;

      --
      end procedure verify_cf;

      -- These values are copied from the spread sheet cf.xlsx.
      constant C_RES2059    : res_vector_type :=
      (
         (
            45,
            -34
         ),
         (
            91,
            45
         ),
         (
            136,
            -35
         ),
         (
            227,
            54
         ),
         (
            363,
            -7
         ),
         (
            465,
            30
         ),
         (
            1293,
            -59
         ),
         (
            1758,
            5
         ),
         (
            294,
            -42
         ),
         (
            287,
            9
         ),
         (
            818,
            -51
         ),
         (
            1105,
            38
         ),
         (
            1923,
            -35
         ),
         (
            833,
            6
         ),
         (
            1231,
            -63
         ),
         (
            5,
            25
         )
      );

      constant C_RES2623    : res_vector_type :=
      (
         (
            51,
            -22
         ),
         (
            205,
            57
         ),
         (
            256,
            -39
         ),
         (
            461,
            58
         ),
         (
            717,
            -19
         ),
         (
            706,
            66
         ),
         (
            1423,
            -27
         ),
         (
            929,
            74
         ),
         (
            2352,
            -3
         ),
         (
            2478,
            41
         ),
         (
            2062,
            -39
         ),
         (
            1356,
            13
         )
      );

      constant C_RES3922201 : res_vector_type :=
      (
         (
            1980,
            -1801
         ),
         (
            3961,
            717
         ),
         (
            21785,
            -96
         ),
         (
            897146,
            307
         ),
         (
            2943135,
            -3240
         ),
         (
            3840281,
            489
         ),
         (
            2369695,
            -685
         ),
         (
            3922153,
            2304
         ),
         (
            2369647,
            -1443
         ),
         (
            2369599,
            2407
         ),
         (
            817045,
            -376
         ),
         (
            1878602,
            3217
         ),
         (
            2695647,
            -453
         ),
         (
            1137126,
            3000
         ),
         (
            3832773,
            -655
         ),
         (
            689986,
            615
         ),
         (
            128287,
            -1027
         )
      );
   begin
      -- Wait until reset is complete
      cf_s_start   <= '0';
      wait until rst = '0';
      wait until clk = '1';

      -- Verify CF
      verify_cf(2623, C_RES2623);
      wait for 200 ns;

      verify_cf(2059, C_RES2059);
      wait for 200 ns;

      verify_cf(3922201, C_RES3922201);
      wait for 200 ns;

      -- Stop test
      wait until clk = '1';
      report "Test completed";
      test_running <= '0';
      wait;
   end process main_test_proc;

end architecture simulation;

