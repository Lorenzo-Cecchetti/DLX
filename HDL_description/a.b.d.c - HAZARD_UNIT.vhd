library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.my_package.all;

entity HAZARD_UNIT is
port(
	MUL_INSTR : in std_logic;
	MUL_INSTR_ID : in std_logic;
	STORE_INSTR : in std_logic;
	BRANCH_INSTR : in std_logic;
	J_REG_INSTR : in std_logic;
	RD_ID : in std_logic_vector(6 downto 0);
	RD_ID_EX : in std_logic_vector(6 downto 0);
	RD_1_MUL_PIPE : in mul_pipe_t; --type defined in my_package as an array(6 downto 0) of std_logic_vector(4 downto 0)
	RD_2_MUL_PIPE : in mul_pipe_t; --type defined in my_package as an array(6 downto 0) of std_logic_vector(4 downto 0)
	MEM_READ : in std_logic; -- connetterlo al bit della CW corrispondente all'enable in lettura della DATA_MEMORY contenuto nel registro di pipeline ID/EX
							 -- questo perchè al momento del check la LOAD sarà in execute e l'istruzione da stallare in ID (guardare immagine pipeline per capire meglio)
	R_INSTR : in std_logic;
	I_INSTR : in std_logic;
	FILL : in std_logic;
	SPILL : in std_logic;
	RS_1 : in std_logic_vector(6 downto 0);
	RS_2 : in std_logic_vector(6 downto 0);
	STALL : out std_logic;
	STALL_J_REG_OUT : out std_logic;
	LAST_STALL : out std_logic);
end entity;

architecture BEHAVIORAL of HAZARD_UNIT is

	signal STALL_J_REG : std_logic;
	signal STALL_MUL : std_logic;
	signal STALL_RF : std_logic;
	signal STALL_BRANCH : std_logic;
	signal STALL_LOAD : std_logic; -- segnale che gestisce stalli causati da JR, JALR e BRANCHES
	signal present : std_logic_vector(15 downto 0);
	signal present_waw : std_logic_vector(7 downto 0);
	signal STALL_WAW : std_logic;
	
begin
	
	mul: process(R_INSTR, I_INSTR, RS_1, RS_2, RD_1_MUL_PIPE, RD_2_MUL_PIPE, present, RD_ID_EX, MUL_INSTR)
	variable num : integer;
	variable RD_2_ID_EX : std_logic_vector(6 downto 0);
	begin
		num := to_integer(unsigned(RD_ID_EX))+1;
		RD_2_ID_EX := std_logic_vector(to_unsigned(num,7));
			if R_INSTR = '1' then
			
				if MUL_INSTR = '1' and (RS_1 = RD_ID_EX or RS_1 = RD_2_ID_EX) and RS_1 /= "0000000" then 
					present(0) <= '1';
				else 
					present(0) <= '0';
				end if;
				
				if MUL_INSTR = '1' and (RS_2 = RD_ID_EX or RS_2 = RD_2_ID_EX) and RS_2 /= "0000000" then 
					present(8) <= '1';
				else 
					present(8) <= '0';
				end if;
				
				for i in 0 to 6 loop
					if (RS_1 = RD_1_MUL_PIPE(i) or RS_1 = RD_2_MUL_PIPE(i)) and RS_1 /= "0000000" then 
						present(i+1) <= '1';
					else 
						present(i+1) <= '0';
					end if;
					if (RS_2 = RD_1_MUL_PIPE(i) or RS_2 = RD_2_MUL_PIPE(i)) and RS_2 /= "0000000" then 
						present(i+9) <= '1';
					else 
						present(i+9) <= '0';
					end if;
				end loop;
				
			elsif I_INSTR = '1' then
				
				if MUL_INSTR = '1' and (RS_1 = RD_ID_EX or RS_1 = RD_2_ID_EX) and RS_1 /= "0000000" then 
					present(0) <= '1';
				else 
					present(0) <= '0';
				end if;
				
				for i in 0 to 6 loop
					if (RS_1 = RD_1_MUL_PIPE(i) or RS_1 = RD_2_MUL_PIPE(i)) and RS_1 /= "0000000" then 
						present(i+1) <= '1';
					else 
						present(i+1) <= '0';
					end if;
				end loop;
				
				for i in 8 to 15 loop
					present(i) <= '0';
				end loop;
				
			else 
				for i in 0 to 15 loop
					present(i) <= '0';
				end loop;
			end if;
	end process;
	
	waw: process(MUL_INSTR_ID, STORE_INSTR, MEM_READ,MUL_INSTR, RD_ID,RD_ID_EX, RD_1_MUL_PIPE, RD_2_MUL_PIPE)
		variable num : integer;
		variable RD_2_ID_EX : std_logic_vector(6 downto 0);
	begin
		num := to_integer(unsigned(RD_ID_EX))+1;
		RD_2_ID_EX := std_logic_vector(to_unsigned(num,7));
		
		if MUL_INSTR_ID = '0' and STORE_INSTR = '0' and MEM_READ = '0' then
			if MUL_INSTR = '1' and (RD_ID = RD_ID_EX or RD_ID = RD_2_ID_EX) and RD_ID /= "0000000" then 
				present_waw(0) <= '1';
			else 
				present_waw(0) <= '0';
			end if;
			
			for i in 0 to 6 loop
				if (RD_ID = RD_1_MUL_PIPE(i) or RD_ID = RD_2_MUL_PIPE(i)) and RD_ID /= "0000000" then
					present_waw(i+1) <= '1';	
				else 
					present_waw(i+1) <= '0';
				end if;
			end loop;
		else
			present_waw <= (others => '0');
		end if;
		
	end process;
	
	load: process(MEM_READ, RS_1, RS_2, I_INSTR, R_INSTR, RD_ID_EX)
	begin
		if MEM_READ = '1' then 
			if R_INSTR = '1' then 
				if (RD_ID_EX = RS_1 or RD_ID_EX = RS_2) and RD_ID_EX /= "0000000" then
					STALL_LOAD <= '1';
				else 
					STALL_LOAD <= '0';
				end if;
			elsif I_INSTR = '1' then 
				if RD_ID_EX = RS_1 and RD_ID_EX /= "0000000" then
					STALL_LOAD <= '1';
				else 
					STALL_LOAD <= '0';
				end if;
			else 
				STALL_LOAD <= '0';
			end if;
		else 
			STALL_LOAD <= '0';
		end if;
	end process load;
	
	br_stall: process(BRANCH_INSTR,RD_ID_EX,RS_1)
	begin
		if BRANCH_INSTR = '1' then
			if RD_ID_EX = RS_1 and RD_ID_EX /= "0000000" then
				STALL_BRANCH <= '1';
			else 
				STALL_BRANCH <= '0';
			end if;
		else
			STALL_BRANCH <= '0';
		end if;
	end process;
	
	jr_stall : process(J_REG_INSTR,RS_1,RD_ID_EX)
	begin
		if J_REG_INSTR = '1' then 
			if RS_1 = RD_ID_EX and RD_ID_EX /= "0000000" then
				STALL_J_REG <= '1';
			else
				STALL_J_REG <= '0';
			end if;
		else
			STALL_J_REG <= '0';
		end if;
	end process;
	
	STALL_RF <= SPILL OR FILL;
	
	STALL_MUL <= present(0) or present(1) or present(2) or present(3) or present(4) or present(5) or present(6)
				or present(7) or present(8) or present(9) or present(10) or present(11) or present(12) or present(13) or present(14) or present(15);
	STALL_WAW <= present_waw(0) or present_waw(1) or present_waw(2) or present_waw(3) or present_waw(4) or present_waw(5) or present_waw(6) or present_waw(7);
	
	STALL <= STALL_LOAD or STALL_MUL or STALL_RF or STALL_WAW or STALL_BRANCH or STALL_J_REG;
	LAST_STALL <= present(7) or present(15) or present_waw(7);
	STALL_J_REG_OUT <= STALL_J_REG;
end architecture;