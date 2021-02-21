library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity NAND4 is 
	port(A, B, C, D : in std_logic;
		 Z : out std_logic);
end entity;

architecture BEHAVIORAL of NAND4 is 
begin
	Z <= not( A and B and C and D);
end BEHAVIORAL;