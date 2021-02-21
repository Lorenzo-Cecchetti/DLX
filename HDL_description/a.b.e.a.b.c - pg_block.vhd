library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity PG_BLOCK is
  port(Gik,Pik,Gkj,Pkj : in std_logic;
       Gij,Pij : out std_logic);
end entity PG_BLOCK;

architecture behavioral of PG_BLOCK is
begin

  Gij <= Gik or (Pik and Gkj);
  Pij <= Pik and Pkj;
  
end architecture behavioral;
