library ieee;
   use ieee.std_logic_1164.all;
   use ieee.numeric_std_unsigned.all;

entity fact is
   generic (
      G_SIZE     : integer := 256;
      G_VAL_SIZE : integer := 64;
      G_LOG_SIZE : integer := 8
   );
   port (
      clk_i            : in    std_logic;
      rst_i            : in    std_logic;
      epp_val2_i       : in    std_logic_vector(G_VAL_SIZE - 1 downto 0);
      epp_start_i      : in    std_logic;
      ctrl_val2_o      : out   std_logic_vector(G_SIZE - 1 downto 0);
      ctrl_valid_o     : out   std_logic;
      ctrl_ready_i     : in    std_logic;
      ctrl_state_log_o : out   std_logic_vector(G_LOG_SIZE - 1 downto 0)
   );
end entity fact;

architecture behavioral of fact is

   -- Signals driven by the GCD module
   signal gcd_res   : std_logic_vector(G_SIZE - 1 downto 0);
   signal gcd_valid : std_logic;

   -- Signals driven by the "divexact" module
   signal div_res   : std_logic_vector(G_VAL_SIZE - 1 downto 0);
   signal div_valid : std_logic;
   signal div_ready : std_logic;

   -- Signals driven by the "control" module
   signal ctrl_start_div : std_logic;
   signal ctrl_start_gcd : std_logic;
   signal ctrl_val1      : std_logic_vector(G_SIZE - 1 downto 0);

begin

   -- Calculate the GCD between the input value and "val1" above.
   gcd_inst : entity work.gcd
      generic map (
         G_DATA_SIZE => G_SIZE
      )
      port map (
         clk_i     => clk_i,
         rst_i     => rst_i,
         s_valid_i => ctrl_start_gcd,
         s_ready_o => open,
         s_data1_i => ctrl_val1,
         s_data2_i => ctrl_val2_o,
         m_valid_o => gcd_valid,
         m_ready_i => '1',
         m_data_o  => gcd_res
      ); -- gcd_inst

   -- Perform exact division of the initial value and the GCD.
   divexact_inst : entity work.divexact
      generic map (
         G_DATA_SIZE => G_VAL_SIZE
      )
      port map (
         clk_i     => clk_i,
         rst_i     => rst_i,
         s_valid_i => ctrl_start_div,
         s_ready_o => open,
         s_data1_i => ctrl_val1(G_VAL_SIZE - 1 downto 0),
         s_data2_i => ctrl_val2_o(G_VAL_SIZE - 1 downto 0),
         m_valid_o => div_valid,
         m_ready_i => div_ready,
         m_data_o  => div_res
      ); -- divexact_inst

   div_ready <= '1';

   -- Control
   control_inst : entity work.control
      generic map (
         G_SIZE     => G_SIZE,
         G_VAL_SIZE => G_VAL_SIZE,
         G_LOG_SIZE => G_LOG_SIZE
      )
      port map (
         clk_i       => clk_i,
         rst_i       => rst_i,
         start_div_o => ctrl_start_div,
         start_gcd_o => ctrl_start_gcd,
         valid_o     => ctrl_valid_o,
         ready_i     => ctrl_ready_i,
         val1_o      => ctrl_val1,
         val2_o      => ctrl_val2_o,
         state_log_o => ctrl_state_log_o,
         epp_val2_i  => epp_val2_i,
         div_res_i   => div_res,
         gcd_res_i   => gcd_res,
         epp_start_i => epp_start_i,
         gcd_valid_i => gcd_valid,
         div_valid_i => div_valid
      );

end architecture behavioral;

