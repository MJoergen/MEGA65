library ieee;
   use ieee.std_logic_1164.all;
   use ieee.numeric_std_unsigned.all;

-- This is a simple dual-port RAM: one write port and one read port

entity ram is
   generic (
      G_ADDR_SIZE : natural;
      G_DATA_SIZE : natural
   );
   port (
      clk_i    : in    std_logic;
      rst_i    : in    std_logic;
      a_addr_i : in    std_logic_vector(G_ADDR_SIZE - 1 downto 0);
      a_data_i : in    std_logic_vector(G_DATA_SIZE - 1 downto 0);
      a_we_i   : in    std_logic;
      b_addr_i : in    std_logic_vector(G_ADDR_SIZE - 1 downto 0);
      b_data_o : out   std_logic_vector(G_DATA_SIZE - 1 downto 0)
   );
end entity ram;

architecture synthesis of ram is

   type   ram_type is array (natural range <>) of std_logic_vector(G_DATA_SIZE - 1 downto 0);
   signal ram_s : ram_type(0 to 2 ** G_ADDR_SIZE - 1) := (others => (others => '0'));

   attribute ram_style : string;
   attribute ram_style of ram_s : signal is "distributed";

begin

   ram_proc : process (clk_i)
   begin
      if rising_edge(clk_i) then
         if a_we_i = '1' then
            ram_s(to_integer(a_addr_i)) <= a_data_i;
         end if;
      end if;
   end process ram_proc;

   b_data_o <= ram_s(to_integer(b_addr_i));

end architecture synthesis;

