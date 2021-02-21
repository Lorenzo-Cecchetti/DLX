library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity NAND3 is 
	port(A, B, C : in std_logic;
		 Z : out std_logic);
end entity;

architecture BEHAVIORAL of NAND3 is 
begin
	Z <= not( A and B and C);
end BEHAVIORAL;