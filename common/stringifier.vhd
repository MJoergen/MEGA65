library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity stringifier is
   generic (
      G_DATA_BITS : natural
   );
   port (
      s_data_i : in  std_logic_vector(G_DATA_BITS-1 downto 0);
      m_data_o : out std_logic_vector(8*G_DATA_BITS-1 downto 0)
   );
end entity stringifier;

architecture synthesis of stringifier is

   function to_hex(arg : std_logic_vector) return std_logic_vector is
      variable val : integer range 0 to 15;
   begin
      val := to_integer(unsigned(arg));
      if val < 10 then
         return std_logic_vector(to_unsigned(val + character'pos('0'), 8));
      else
         return std_logic_vector(to_unsigned(val + character'pos('A') - 10, 8));
      end if;
   end function to_hex;

begin

   gen_out : for i in 0 to G_DATA_BITS-1 generate
      m_data_o(8*i+7 downto 8*i) <= to_hex("000" & s_data_i(i));
   end generate gen_out;

end architecture synthesis;

