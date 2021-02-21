library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity G_BLOCK is
  port(Gik,Pik,Gkj : in std_logic;
       Gij : out std_logic);
end entity G_BLOCK;

architecture behavioral of G_BLOCK is
begin

  Gij <= Gik or (Pik and Gkj);

end architecture behavioral;
