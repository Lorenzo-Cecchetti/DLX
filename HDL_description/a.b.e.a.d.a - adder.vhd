library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity ADDER is 
	port( A : in std_logic_vector(63 downto 0);
		  B : in std_logic_vector(63 downto 0);
		  Cin : in std_logic;
		  S: out std_logic_vector(63 downto 0));
end entity;

architecture BEHAVIORAL of ADDER is
	signal Ci_ext : std_logic_vector(63 downto 0);
	
begin
	Ci_ext(0) <= Cin;
	Ci_ext(63 downto 1) <= (others => '0');
	S <= A + B + Ci_ext;
	
end BEHAVIORAL;
