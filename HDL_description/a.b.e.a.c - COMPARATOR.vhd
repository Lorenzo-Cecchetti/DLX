library ieee;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity COMPARATOR is
	port(
		A,B: in std_logic_vector(31 downto 0);
		SIGN_UNSIGN_n: in std_logic;
		AGB,BGA,AEB,AGEB,BGEA,ANEB: out std_logic);
end entity COMPARATOR;

architecture behavioral of COMPARATOR is

	signal AGB_vect, BGA_vect: std_logic_vector(31 downto 0);
	signal s_AGB,s_BGA,s_AEB: std_logic;
	signal unsign_S: std_logic_vector(32 downto 0);
	signal sign_S: std_logic_vector(31 downto 0);
	signal ext_A,ext_B: std_logic_vector(32 downto 0);
	signal MSB_A,MSB_B,EQ_Z: std_logic;
	
begin	
	-- UNSIGNED COMPARATOR
	unsigned_comp : process(SIGN_UNSIGN_n,A,B)
	begin 
		for i in 31 downto 0 loop
			if i = 31 and SIGN_UNSIGN_n = '1' then
				AGB_vect(i) <= (NOT A(i)) AND B(i);
				BGA_vect(i) <= A(i) AND (NOT B(i));
			else
				AGB_vect(i) <= A(i) AND (NOT B(i));
				BGA_vect(i) <= (NOT A(i)) AND B(i);
			end if;
		end loop;
	end process unsigned_comp;
	
	priority_enc : process(AGB_vect,BGA_vect)
		variable index: integer;
	begin
		priority_loop: for i in 31 downto 0 loop
			if AGB_vect(i) = '1' or BGA_vect(i) = '1' then
				index := i;
				exit priority_loop;
			end if;
			index := 0;
		end loop;
		s_AGB <= AGB_vect(index);
		s_BGA <= BGA_vect(index);
	end process;
	s_AEB <= NOT (s_BGA OR s_AGB);
	
	AGB <= s_AGB;
	AEB <= s_AEB;
	BGA <= s_BGA;
	AGEB <= s_AEB OR s_AGB;
	BGEA <= s_AEB OR s_BGA;
	ANEB <= NOT s_AEB;
end architecture behavioral;