library ieee;
   use ieee.std_logic_1164.all;
   use ieee.numeric_std_unsigned.all;

-- This is a self-verifying testbench for the Jacobi module.

entity tb_jacobi is
end entity tb_jacobi;

architecture simulation of tb_jacobi is

   constant C_DATA_SIZE : integer    := 64;

   signal   clk : std_logic          := '1';
   signal   rst : std_logic          := '1';

   -- Signals conected to DUT
   signal   jb_s_ready : std_logic;
   signal   jb_s_valid : std_logic;
   signal   jb_s_val_n : std_logic_vector(C_DATA_SIZE - 1 downto 0);
   signal   jb_s_val_k : std_logic_vector(C_DATA_SIZE - 1 downto 0);
   signal   jb_m_ready : std_logic;
   signal   jb_m_valid : std_logic;
   signal   jb_m_res   : std_logic_vector(1 downto 0);

   -- Signal to control execution of the testbench.
   signal   test_running : std_logic := '1';

begin

   clk <= test_running and not clk after 5 ns;
   rst <= '1', '0' after 100 ns;

   --------------------------------------------------
   -- Instantiate DUT
   --------------------------------------------------

   jacobi_inst : entity work.jacobi
      generic map (
         G_DATA_SIZE => C_DATA_SIZE
      )
      port map (
         clk_i     => clk,
         rst_i     => rst,
         s_ready_o => jb_s_ready,
         s_valid_i => jb_s_valid,
         s_val_n_i => jb_s_val_n,
         s_val_k_i => jb_s_val_k,
         m_ready_i => jb_m_ready,
         m_valid_o => jb_m_valid,
         m_res_o   => jb_m_res
      ); -- jacobi_inst


   --------------------------------------------------
   -- Main test procedure starts here
   --------------------------------------------------

   main_test_proc : process
      --

      pure function jacobi (
         arg_n : natural;
         arg_k : natural
      ) return integer
      is
         variable n_v : natural;
         variable k_v : natural;
         variable t_v : integer;
         variable r_v : natural;
      begin
         n_v := arg_n;
         k_v := arg_k;
         assert (k_v > 0);
         assert (k_v mod 2 = 1);
         n_v := n_v mod k_v;
         t_v := 1;

         while n_v /= 0 loop
            --
            while n_v mod 2 = 0 loop
               n_v := n_v / 2;
               r_v := k_v mod 8;
               if r_v = 3 or r_v = 5 then
                  t_v := -t_v;
               end if;
            end loop;

            r_v := n_v;
            n_v := k_v;
            k_v := r_v;
            if n_v mod 4 = 3 and k_v mod 4 = 3 then
               t_v := -t_v;
            end if;
            n_v := n_v mod k_v;
         end loop;

         if k_v = 1 then
            return t_v;
         else
            return 0;
         end if;
      end function jacobi;

      -- Verify Jacobi processing

      procedure verify_jacobi (
         n : integer;
         k : integer
      ) is
         variable exp_v : std_logic_vector(1 downto 0);
         variable j_v   : integer;
      begin
         --
         jb_m_ready <= '1';
         j_v        := jacobi(n, k);
         report "Verify Jacobi: n=" & integer'image(n) &
                ", k=" & integer'image(k) &
                ", j=" & integer'image(j_v);

         wait until clk = '1';
         jb_s_val_n <= to_stdlogicvector(n, C_DATA_SIZE);
         jb_s_val_k <= to_stdlogicvector(k, C_DATA_SIZE);
         jb_s_valid <= '1';
         wait until clk = '1';
         jb_s_valid <= '0';
         wait until clk = '1';
         assert jb_m_valid = '0';

         exp_v      := "00";
         if j_v = 1 then
            exp_v := "01";
         elsif j_v = -1 then
            exp_v := "11";
         end if;

         -- Verify received response is correct
         while jb_m_valid = '0' loop
            wait until clk = '1';
         end loop;

         assert jb_m_res = exp_v
            report "Received " & to_string(jb_m_res);

      --
      end procedure verify_jacobi;

   --
   begin
      -- Wait until reset is complete
      jb_s_valid   <= '0';
      wait until rst = '0';
      wait until clk = '1';

      -- Verify Jacobi
      verify_jacobi(1, 1);
      verify_jacobi(2, 1);
      verify_jacobi(3, 1);
      verify_jacobi(4, 1);
      verify_jacobi(5, 1);
      verify_jacobi(6, 1);
      verify_jacobi(7, 1);

      verify_jacobi(1, 3);
      verify_jacobi(2, 3);
      verify_jacobi(3, 3);
      verify_jacobi(4, 3);
      verify_jacobi(5, 3);
      verify_jacobi(6, 3);
      verify_jacobi(7, 3);

      verify_jacobi(1, 5);
      verify_jacobi(2, 5);
      verify_jacobi(3, 5);
      verify_jacobi(4, 5);
      verify_jacobi(5, 5);
      verify_jacobi(6, 5);
      verify_jacobi(7, 5);

      verify_jacobi(5, 21);
      verify_jacobi(8, 21);
      verify_jacobi(19, 45);
      verify_jacobi(30, 7);
      verify_jacobi(30, 11);
      verify_jacobi(30, 13);
      verify_jacobi(1001, 9907);
      wait for 200 ns;

      -- Stop test
      wait until clk = '1';
      report "Test completed";
      test_running <= '0';
      wait;
   end process main_test_proc;

end architecture simulation;

