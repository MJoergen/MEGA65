library ieee;
   use ieee.std_logic_1164.all;
   use ieee.numeric_std_unsigned.all;

entity primes is
   generic (
      G_ADDR_SIZE : integer := 12;
      G_DATA_SIZE : integer := 16
   );
   port (
      clk_i   : in    std_logic;
      rst_i   : in    std_logic;
      index_i : in    std_logic_vector(G_ADDR_SIZE - 1 downto 0);
      data_o  : out   std_logic_vector(G_DATA_SIZE - 1 downto 0)
   );
end entity primes;

architecture synthesis of primes is

   type   ram_type is array (natural range <>) of std_logic_vector(G_DATA_SIZE - 1 downto 0);

   pure function is_prime(val : natural) return boolean is
   begin
      for i in 2 to val-1 loop
         if (val mod i) = 0 then
            return false;
         end if;
      end loop;
      return true;
   end function is_prime;

   pure function ram_init return ram_type is
      variable res_v : ram_type(0 to 2 ** G_ADDR_SIZE - 1);
      variable prime_v : natural;
   begin
      prime_v := 2;

      for i in 0 to 2 ** G_ADDR_SIZE - 1 loop
         res_v(i) := to_stdlogicvector(prime_v, G_DATA_SIZE);

         prime_v := prime_v + 1;
         while not is_prime(prime_v) loop
            prime_v := prime_v + 1;
         end loop;
      end loop;

      return res_v;
   end function ram_init;

   signal ram : ram_type(0 to 2 ** G_ADDR_SIZE - 1) := ram_init;

begin

   ram_proc : process (clk_i)
   begin
      if rising_edge(clk_i) then
         data_o <= ram(to_integer(index_i));
      end if;
   end process ram_proc;

end architecture synthesis;

