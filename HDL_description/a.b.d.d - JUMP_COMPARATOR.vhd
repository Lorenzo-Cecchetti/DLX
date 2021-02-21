library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity JUMP_COMPARATOR is
	port( 
		A : in std_logic_vector(31 downto 0);
		EQ_NEQ_n: in std_logic;
		BR_INSTR : in std_logic;
		COND : out std_logic);
end entity;

architecture BEHAVIORAL of JUMP_COMPARATOR is 
begin
	output: process(A,EQ_NEQ_n, BR_INSTR)
	begin
		if BR_INSTR = '1' then 
			if A = std_logic_vector(to_unsigned(0,32)) and EQ_NEQ_n = '1' then
				COND <= '1';
			elsif A /= std_logic_vector(to_unsigned(0,32)) and EQ_NEQ_n = '0' then
				COND <= '1';
			else 
				COND <= '0';
			end if;
		else 
			COND <= '0';
		end if;
	end process;
end architecture;