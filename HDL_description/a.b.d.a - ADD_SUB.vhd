library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity JUMP_ADDER is
	port(
		A : in std_logic_vector( 31 downto 0);
		B : in std_logic_vector( 31 downto 0);
		S : out std_logic_vector( 31 downto 0));
end entity;

architecture BEHAVIORAL of JUMP_ADDER is
begin
	S <= std_logic_vector(unsigned(A) + unsigned(B));
end architecture;