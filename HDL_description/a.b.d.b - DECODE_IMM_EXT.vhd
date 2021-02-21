library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity DECODE_IMM_EXT is
	port (
		J_INSTR : in std_logic;
		I_INSTR : in std_logic;
		JAL_INSTR : in std_logic;
		IR : in std_logic_vector(25 downto 0);
		SIGNED_UNSIGNED_n : in std_logic;
		STORE_INSTR : in std_logic;
		
		RS_1, RS_2, RD : out std_logic_vector(4 downto 0);
		IMMEDIATE : out std_logic_vector(31 downto 0));
end entity; 

architecture BEHAVIORAL of DECODE_IMM_EXT is

constant IR_REG_SIZE: integer := 5;
signal JUMP_TARGET : std_logic_vector(25 downto 0);
signal IMM : std_logic_vector(15 downto 0);

begin
	dec: process(J_INSTR, I_INSTR, STORE_INSTR, IR,JAL_INSTR)
	begin
		if J_INSTR = '1' then
			if JAL_INSTR = '1' then 
				RD <= (others => '1'); -- impostiamo come RD R31 (LINK REGISTER)
				RS_2 <= (others => '1');
			else
				RD <= (others => '0');
				RS_2 <= (others => '0');
			end if;
			--unused signals
			RS_1 <= (others => '0');
			JUMP_TARGET(25 downto 0) <= IR;
			IMM <= (others => '0');
		else 
			
			RS_1 <= IR(25 downto 21);
			if I_INSTR = '1' then
				if STORE_INSTR = '1' then
					RS_2 <= IR(20 downto 16);
					RD <= (others => '0');
				else
					RS_2 <= (others => '1');
					if JAL_INSTR = '1' then 
						RD <= (others => '1');
					else
						RD <= IR(20 downto 16);
					end if;
				end if;
				IMM <= IR(15 downto 0);
			else 
				RS_2 <= IR(20 downto 16);
				RD <= IR(15 downto 11);
				IMM <= (others => '0');
			end if;
			--unused signal
			JUMP_TARGET <= (others => '0');
		end if;
	end process;
	
	imm_ext: process(J_INSTR, I_INSTR, SIGNED_UNSIGNED_n, JUMP_TARGET, IMM, STORE_INSTR)
		constant IMM_SIZE : integer := 16;
	begin
		if J_INSTR = '1' then  
		
			IMMEDIATE(31 downto 26) <= (others => JUMP_TARGET(25));
			IMMEDIATE(25 downto 0) <= JUMP_TARGET;
			
		elsif I_INSTR = '1' then
			
			if STORE_INSTR = '1' then
				IMMEDIATE(31 downto 16) <= (others => IMM(15));
			else 
				if SIGNED_UNSIGNED_n = '1' then 
					IMMEDIATE(31 downto 16) <= (others => IMM(15));
				else 
					IMMEDIATE(31 downto 16) <= (others => '0');
				end if;
			end if;
			IMMEDIATE(15 downto 0) <= IMM;
			
		else 
			IMMEDIATE <= (others => '0');
		end if;
	end process;
end architecture;