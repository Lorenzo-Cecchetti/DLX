library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity FWU is 
	port(RS_1_ID_EX,RS_2_ID_EX: in std_logic_vector(6 downto 0);
		RD_1_MUL_EX_MEM : in std_logic_vector(6	downto 0);
		RD_2_MUL_EX_MEM : in std_logic_vector(6 downto 0);
		RS_2_EX_MEM : in std_logic_vector(6 downto 0);
		RD_EX_MEM : in std_logic_vector(6 downto 0);
		RD_MEM_WB : in std_logic_vector(6 downto 0);
		RD_ID_EX : in std_logic_vector(6 downto 0);
		RD_1_MUL_MEM_WB : in std_logic_vector(6 downto 0);
		RD_2_MUL_MEM_WB : in std_logic_vector(6 downto 0);
		RS_2_ID: in std_logic_vector(6 downto 0);
		RS_1_ID: in std_logic_vector(6 downto 0);
		MEM_READ_WB : in std_logic;
		JAL_INSTR_EX : in std_logic;
		FW_EX_TO_EX_A,FW_EX_TO_EX_B: out std_logic_vector(1 downto 0);
		FW_MEM_TO_EX_A,FW_MEM_TO_EX_B: out std_logic_vector(1 downto 0);
		FW_MEM_TO_MEM: out std_logic_vector(1 downto 0);
		FW_ID_TO_ID : out std_logic;
		FW_EX_TO_ID: out std_logic_vector(1 downto 0);
		FW_MEM_TO_ID : out std_logic_vector(1 downto 0);
		FW_EX_TO_ID_STACK : out std_logic;
		FW_MEM_TO_ID_STACK : out std_logic_vector(1 downto 0);
		FW_WB_TO_ID_STACK : out std_logic_vector(1 downto 0));
end entity;

architecture behavioral of FWU is 
begin

	FU_Proc: process(RS_1_ID_EX,RS_2_ID_EX,RD_1_MUL_EX_MEM,RD_2_MUL_EX_MEM,RD_EX_MEM,RD_1_MUL_MEM_WB,RD_2_MUL_MEM_WB,RD_MEM_WB,RS_1_ID,MEM_READ_WB,JAL_INSTR_EX)
	begin
		-- FORWARDING DURING EXECUTE: OP -> OP (PIPELINE EX/MEM)
		if RS_1_ID_EX = RD_1_MUL_EX_MEM  and RS_1_ID_EX /= "0000000" then --last condition added to exclude the case of the STORE instruction that has RD = 0
			FW_EX_TO_EX_A <= "10";
		elsif RS_1_ID_EX = RD_2_MUL_EX_MEM and RS_1_ID_EX /= "0000000" then
			FW_EX_TO_EX_A <= "01";
		elsif RS_1_ID_EX = RD_EX_MEM and RS_1_ID_EX /= "0000000" and MEM_READ_WB = '0' then 
			FW_EX_TO_EX_A <= "11";
		else
			FW_EX_TO_EX_A <= "00";
		end if;
	
		if RS_2_ID_EX = RD_1_MUL_EX_MEM and RS_2_ID_EX /= "0000000" then
			FW_EX_TO_EX_B <= "10";
		elsif RS_2_ID_EX = RD_2_MUL_EX_MEM and RS_2_ID_EX /= "0000000" then
			FW_EX_TO_EX_B <= "01";
		elsif RS_2_ID_EX = RD_EX_MEM and RS_2_ID_EX /= "0000000" and MEM_READ_WB = '0' then -- MEM_READ_WB condition added to avoid forwarding in execute when we have a LOAD followed by an OP 
			FW_EX_TO_EX_B <= "11";
		else
			FW_EX_TO_EX_B <= "00";
		end if;
	
	-- FORWARDING DURING EXECUTE: OP -> OP (PIPELINE MEM/WB)
		if RS_1_ID_EX = RD_1_MUL_MEM_WB and RS_1_ID_EX /= "0000000" then
			FW_MEM_TO_EX_A <= "10";
		elsif RS_1_ID_EX = RD_2_MUL_MEM_WB and RS_1_ID_EX /= "0000000" then
			FW_MEM_TO_EX_A <= "01";
		elsif RS_1_ID_EX = RD_MEM_WB and RS_1_ID_EX /= "0000000" then 
			FW_MEM_TO_EX_A <= "11";
		else
			FW_MEM_TO_EX_A <= "00";
		end if;
	
		if RS_2_ID_EX = RD_1_MUL_MEM_WB and RS_2_ID_EX /= "0000000" then
			FW_MEM_TO_EX_B <= "10";
		elsif RS_2_ID_EX = RD_2_MUL_MEM_WB and RS_2_ID_EX /= "0000000" then
			FW_MEM_TO_EX_B <= "01";
		elsif RS_2_ID_EX = RD_MEM_WB and RS_2_ID_EX /= "0000000" then 
			FW_MEM_TO_EX_B <= "11";
		else
			FW_MEM_TO_EX_B <= "00";
		end if;
	
	-- FORWARDING DURING EXECUTE: LOAD -> STORE (PIPELINE MEMORY/WRITEBACK)
		if RS_2_EX_MEM = RD_1_MUL_MEM_WB then
			FW_MEM_TO_MEM <= "10";
		elsif RS_2_EX_MEM = RD_2_MUL_MEM_WB then
			FW_MEM_TO_MEM <= "01";
		elsif RS_2_EX_MEM = RD_MEM_WB then 
			FW_MEM_TO_MEM <= "11";
		else
			FW_MEM_TO_MEM <= "00";
		end if;
	
	-- FORWARDING FOR JR, JALR AND BRANCHES
		
		if RS_1_ID = RD_ID_EX and RS_1_ID = "1000111" and JAL_INSTR_EX = '1' then
			FW_ID_TO_ID <= '1';
		else 
			FW_ID_TO_ID <= '0';
		end if;
		
		if RS_1_ID = RD_1_MUL_EX_MEM and RS_1_ID /= "0000000" then
			FW_EX_TO_ID <= "10";
		elsif RS_1_ID = RD_2_MUL_EX_MEM and RS_1_ID /= "0000000" then
			FW_EX_TO_ID <= "01";
		elsif RS_1_ID = RD_EX_MEM and RS_1_ID /= "0000000" then 
			FW_EX_TO_ID <= "11";
		else
			FW_EX_TO_ID <= "00";
		end if;
		
		if RS_1_ID = RD_1_MUL_MEM_WB and RS_1_ID /= "0000000" then
			FW_MEM_TO_ID <= "10";
		elsif RS_1_ID = RD_2_MUL_MEM_WB and RS_1_ID /= "0000000" then
			FW_MEM_TO_ID <= "01";
		elsif RS_1_ID = RD_MEM_WB and RS_1_ID /= "0000000" then 
			FW_MEM_TO_ID <= "11";
		else
			FW_MEM_TO_ID <= "00";
		end if;
		
		--FORWARD TO STACK
		
		if RS_2_ID = RD_ID_EX and RS_2_ID = "1000111" then 
			FW_EX_TO_ID_STACK <= '1';
		else
			FW_EX_TO_ID_STACK <= '0';
		end if;
		
		if RS_2_ID = RD_1_MUL_EX_MEM and RS_2_ID = "1000111" then -- the binary number is 71 (link register after decoded)
			FW_MEM_TO_ID_STACK <= "10";
		elsif RS_2_ID = RD_2_MUL_EX_MEM and RS_2_ID = "1000111" then
			FW_MEM_TO_ID_STACK <= "01";
		elsif RS_2_ID = RD_EX_MEM and RS_2_ID = "1000111" then 
			FW_MEM_TO_ID_STACK <= "11";
		else
			FW_MEM_TO_ID_STACK <= "00";
		end if;
		
		if RS_2_ID = RD_1_MUL_MEM_WB and RS_2_ID = "1000111" then -- the binary number is 71 (link register after decoded)
			FW_WB_TO_ID_STACK <= "10";
		elsif RS_2_ID = RD_2_MUL_MEM_WB and RS_2_ID = "1000111" then
			FW_WB_TO_ID_STACK <= "01";
		elsif RS_2_ID = RD_MEM_WB and RS_2_ID = "1000111" then 
			FW_WB_TO_ID_STACK <= "11";
		else
			FW_WB_TO_ID_STACK <= "00";
		end if;
		
	end process;
end architecture;