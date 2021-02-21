library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity LHU is 
	port(MEM_OUT: in std_logic_vector (31 downto 0);
		DIMENSION: in std_logic_vector(1 downto 0); -- 00-> not enabled 01->b 10->h 11->w
		SIGN_UNSIGN_n: in std_logic;
		LHU_OUT: out std_logic_vector (31 downto 0));
end entity;

architecture behavioral of LHU is 

begin
	LHU_Proc: process(MEM_OUT,DIMENSION,SIGN_UNSIGN_n)
	begin
		if DIMENSION = "10" then
			LHU_OUT(15 downto 0) <= MEM_OUT (31 downto 16);
			if SIGN_UNSIGN_n = '1' then 
				LHU_OUT(31 downto 16) <= (others => MEM_OUT(31));
			else 
				LHU_OUT(31 downto 16) <= (others => '0');
			end if;
		elsif DIMENSION = "01" then
			LHU_OUT(7 downto 0) <= MEM_OUT (31 downto 24);
			if SIGN_UNSIGN_n = '1' then 
				LHU_OUT(31 downto 8) <= (others => MEM_OUT(31));
			else 
				LHU_OUT(31 downto 8) <= (others => '0');
			end if;
		elsif DIMENSION = "11" then
			LHU_OUT <= MEM_OUT;
		else 
			LHU_OUT <= (others => '0');
		end if;
	end process;
end architecture;