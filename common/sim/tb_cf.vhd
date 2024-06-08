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

   type     cf_state_type is record
      n     : natural;
      m     : natural;

      p_old : natural;
      r_old : natural;
      x_old : natural;

      p     : natural;
      s     : natural;
      w     : integer;
      x     : natural;
   end record cf_state_type;

   procedure cf_print (
      cf_state : cf_state_type
   ) is
   begin
      report "n=" & to_string(cf_state.n);
      report "m=" & to_string(cf_state.m);
      report "p_old=" & to_string(cf_state.p_old);
      report "r_old=" & to_string(cf_state.r_old);
      report "x_old=" & to_string(cf_state.x_old);
      report "p=" & to_string(cf_state.p);
      report "s=" & to_string(cf_state.s);
      report "w=" & to_string(cf_state.w);
      report "x=" & to_string(cf_state.x);
   end procedure cf_print;

   -- Calculate integer square

   pure function sqrt (
      n : natural
   ) return natural is
      variable res_v : natural;
   begin
      --
      for i in 1 to n loop
         --
         if i * i > n then
            res_v := i - 1;
            exit;
         end if;
      end loop;

      return res_v;
   end function sqrt;

   -- Calculate a*x mod n, without risk of overflow

   pure function add_mul (
      a : natural;
      x : natural;
      n : natural
   ) return natural is
   begin
      if a = 0 then
         return 0;
      elsif (a mod 2) = 0 then
         return (add_mul(a / 2, x, n) * 2) mod n;
      else
         return (add_mul(a / 2, x, n) * 2 + x) mod n;
      end if;
   end function add_mul;

   procedure cf_check (
      cf_state : cf_state_type
   ) is
   begin
      assert (add_mul(cf_state.x, cf_state.x, cf_state.n) - cf_state.w * cf_state.p) mod cf_state.n = 0;
   end procedure cf_check;

   pure function cf_init (
      n : natural
   ) return cf_state_type is
      variable res_v : cf_state_type;
   begin
      res_v.n     := n;
      res_v.m     := sqrt(n);
      res_v.p_old := 1;
      res_v.r_old := 0;
      res_v.x_old := 1;
      res_v.p     := n - res_v.m * res_v.m;
      res_v.s     := 2 * res_v.m;
      res_v.w     := -1;
      res_v.x     := res_v.m;
      cf_check(res_v);
      return res_v;
   end function cf_init;

   pure function cf_next (
      cf_state : cf_state_type
   ) return cf_state_type is
      variable a_v   : natural;
      variable r_v   : natural;
      variable res_v : cf_state_type;
   begin
      res_v.n     := cf_state.n;
      res_v.m     := cf_state.m;
      a_v         := cf_state.s / cf_state.p;
      r_v         := cf_state.s - a_v * cf_state.p;
      res_v.s     := 2 * cf_state.m - r_v;
      res_v.p     := a_v * (r_v - cf_state.r_old) + cf_state.p_old;
      res_v.w     := -cf_state.w;
      res_v.x     := (a_v * cf_state.x + cf_state.x_old) mod cf_state.n;
      res_v.p_old := cf_state.p;
      res_v.r_old := r_v;
      res_v.x_old := cf_state.x;
      cf_check(res_v);
      return res_v;
   end function cf_next;

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
      -- Verify CF processing

      procedure verify_cf (
         val_n : integer
      ) is
         variable exp_x_v    : std_logic_vector(2 * C_DATA_SIZE - 1 downto 0);
         variable exp_p_v    : std_logic_vector(C_DATA_SIZE - 1 downto 0);
         variable exp_w_v    : std_logic;
         variable cf_state_v : cf_state_type;
      begin
         report "Verify CF: N=" & integer'image(val_n);

         cf_state_v := cf_init(val_n);

         cf_s_val_n <= to_stdlogicvector(val_n, 2 * C_DATA_SIZE);
         cf_s_start <= '1';
         wait until clk = '1';
         cf_s_start <= '0';
         wait until clk = '1';

         for i in 0 to 20 loop
            -- Wait for next value
            wait until clk = '1';

            while (cf_m_valid and cf_m_ready) /= '1' loop
               wait until clk = '1';
            end loop;

            exp_x_v    := to_stdlogicvector(cf_state_v.x, 2 * C_DATA_SIZE);
            exp_p_v    := to_stdlogicvector(cf_state_v.p, C_DATA_SIZE);
            exp_w_v    := '1' when cf_state_v.w = -1 else '0';

            assert cf_m_res_x = exp_x_v and
                   cf_m_res_p = exp_p_v and
                   cf_m_res_w = exp_w_v
               report "Received (" & to_string(cf_m_res_x) & ", " & to_string(cf_m_res_w) & ", " & to_string(cf_m_res_p) & ")";

            cf_state_v := cf_next(cf_state_v);

         --
         end loop;

      --
      end procedure verify_cf;

   --
   begin
      -- Wait until reset is complete
      cf_s_start   <= '0';
      wait until rst = '0';
      wait until clk = '1';

      -- Verify CF
      verify_cf(2623);
      wait for 200 ns;

      verify_cf(2059);
      wait for 200 ns;

      verify_cf(3922201);
      wait for 200 ns;

      -- Stop test
      wait until clk = '1';
      report "Test completed";
      test_running <= '0';
      wait;
   end process main_test_proc;

end architecture simulation;

