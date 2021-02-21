library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity ADDER_PC is
	port(	PC : in std_logic_vector(31 downto 0);
			NEW_PC : out std_logic_vector(31 downto 0));
end entity;

architecture BEHAVIORAL of ADDER_PC is
begin
	NEW_PC <= PC + std_logic_vector(to_unsigned(4,32));
end BEHAVIORAL; 
