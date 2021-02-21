library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.my_package.all;
use work.functions.all;

entity CU is 
port(
	CLK : in std_logic;
	RST : in std_logic;
	STALL : in std_logic;
	LAST_STALL : in std_logic;
	FILL : in std_logic;
	SPILL : in std_logic;
	TC : in std_logic;
	FUNC : in std_logic_vector(10 downto 0);
	OPCODE : in std_logic_vector(5 downto 0);
	--IF/ID
	IF_ID_PIPE_EN : out std_logic;
	--DECODE
	J_REG_INSTR : out std_logic;
	BRANCH_INSTR : out std_logic;
	BR_EQ_NEQ_n : out std_logic;
	J_INSTR : out std_logic;
	I_INSTR_ID : out std_logic;
	JAL_INSTR : out std_logic;
	SIGNED_UNSIGNED_n_ID : out std_logic;
	STORE_INSTR : out std_logic;
	JR_INSTR : out std_logic;
	R_INSTR : out std_logic;
	MUL_INSTR_ID : out std_logic;
	--ID/EX
	ID_EX_PIPE_EN : out std_logic;
	--EXECUTE
	I_INSTR_EX : out std_logic;
	ALU_EN : out std_logic;
	ALU_FUNC : out std_logic_vector(4 downto 0);
	MUL_INSTR : out std_logic;
	LHI_INSTR : out std_logic;
	MEM_READ_HAZARD : out std_logic;
	--EX/MEM
	EX_MEM_PIPE_EN : out std_logic;
	--MEMORY
	DIMENSION : out std_logic_vector(1 downto 0);
	SIGN_UNSIGN_n : out std_logic;
	MEM_EN : out std_logic;
	MEM_READ_WRITE_n : out std_logic;
	ALIGN_CHECK : out std_logic_vector(1 downto 0); -- 01 byte -- 10 half -- 11 word 
	--MEM/WB
	MEM_WB_PIPE_EN : out std_logic;
	--WRITE BACK
	RF_WR_1_EN : out std_logic;
	RF_WR_2_EN : out std_logic;
	MEM_ALU_n : out std_logic;
	SEL_PC_WB : out std_logic);
end entity;

architecture BEHAVIORAL of CU is
	signal cw : std_logic_vector(33 downto 0);
	signal ID_EX : std_logic_vector(21 downto 0);
	signal EX_MEM : std_logic_vector(11 downto 0);
	signal MEM_WB : std_logic_vector(3 downto 0);
begin

	cw_gen: process(OPCODE, FUNC, RST)
	begin
		if RST = '0' then 
			cw <= (others => '0');
		else
			case OPCODE is
				when R_TYPE_OPCODE => 
									case FUNC is
										when SLL_R => cw <= "0000000001010110001001000000011000";
										when SRL_R => cw <= "0000000001010110010001000000011000";
										when SRA_R => cw <= "0000000001010110000001000000011000";
										when ADD_R => cw <= "0000000001010100000001000000011000";
										when ADDU_R => cw<= "0000000001010100010001000000011000";
										when SUB_R => cw <= "0000000001010100001001000000011000";
										when SUBU_R => cw<= "0000000001010100011001000000011000";
										when AND_R => cw <= "0000000001010110100001000000011000";
										when OR_R => cw  <= "0000000001010110110001000000011000";
										when XOR_R => cw <= "0000000001010111000001000000011000";
										when NAND_R => cw<= "0000000001010110101001000000011000"; -- ADD TO COMPILER
										when NOR_R  => cw<= "0000000001010110111001000000011000"; -- ADD TO COMPILER
										when XNOR_R => cw<= "0000000001010111001001000000011000"; -- ADD TO COMPILER
										when SEQ_R => cw <= "0000000001010101000001000000011000";
										when SNE_R => cw <= "0000000001010101110001000000011000";
										when SLT_R => cw <= "0000000001010100110001000000011000";
										when SGT_R => cw <= "0000000001010100100001000000011000";
										when SLE_R => cw <= "0000000001010101100001000000011000";
										when SGE_R => cw <= "0000000001010101010001000000011000";
										when SLTU_R => cw<= "0000000001010100111001000000011000";
										when SGTU_R => cw<= "0000000001010100101001000000011000";
										when SLEU_R => cw<= "0000000001010101101001000000011000";
										when SGEU_R => cw<= "0000000001010101011001000000011000";
										when MUL_R => cw <= "0000000001110110011101000000010100"; -- ADD TO COMPILER
										when others =>cw <= "0000000000010000000001000000010000";
									end case;
				when J =>    cw <= "0001001000010000000001000000010000";
				when JAL =>  cw <= "0001011000010000000001000000011001";
				when BEQZ => cw <= "0110101000011000000001000000010000";
				when BNEZ => cw <= "0100101000011000000001000000010000";
				when ADDI => cw <= "0000101000011100000001000000011000"; 
				when ADDUI =>cw <= "0000100000011100010001000000011000"; 
				when SUBI => cw <= "0000101000011100001001000000011000"; 
				when SUBUI =>cw <= "0000100000011100011001000000011000"; 
				when ANDI => cw <= "0000101000011110100001000000011000"; 
				when ORI =>  cw <= "0000101000011110110001000000011000"; 
				when XORI => cw <= "0000101000011111000001000000011000"; 
				when NANDI =>cw <= "0000101000011110101001000000011000"; 
				when NORI => cw <= "0000101000011110111001000000011000"; 
				when XNORI =>cw <= "0000101000011111001001000000011000"; 
				when LHI =>  cw <= "0000100000011000000011000000011000"; 
				when JR =>   cw <= "1000100010011000000001000000010000"; 
				when JALR => cw <= "1000110000011000000001000000011001"; 
				when SLLI => cw <= "0000101000011110001001000000011000"; 
				when NOP =>  cw <= "0000000000010000000001000000010000"; 
				when SRLI => cw <= "0000101000011110010001000000011000"; 
				when SRAI => cw <= "0000101000011110000001000000011000"; 
				when SEQI => cw <= "0000101000011101000001000000011000"; 
				when SNEI => cw <= "0000101000011101110001000000011000"; 
				when SLTI => cw <= "0000101000011100110001000000011000";
				when SGTI => cw <= "0000101000011100100001000000011000";
				when SLEI => cw <= "0000101000011101100001000000011000";
				when SGEI => cw <= "0000101000011101010001000000011000"; 
				when LB =>   cw <= "0000101000011100000001011110111010"; 
				when LH =>   cw <= "0000101000011100000001101111011010"; 
				when LW =>   cw <= "0000101000011100000001110111111010"; 
				when LBU =>  cw <= "0000100000011100000001010110111010"; 
				when LHU =>  cw <= "0000100000011100000001100111011010"; 
				when SB =>   cw <= "0000101100011100000001000100110000"; 
				when SH =>   cw <= "0000101100011100000001000101010000"; 
				when SW =>   cw <= "0000101100011100000001000101110000"; 
				when SLTUI =>cw <= "0000101000011100111001000000011000"; 
				when SGTUI =>cw <= "0000101000011100101001000000011000"; 
				when SLEUI =>cw <= "0000101000011101101001000000011000"; 
				when SGEUI =>cw <= "0000101000011101011001000000011000"; 
				when MULI => cw <= "0000101000111110011101000000010100";
				when others =>cw<= "0000000000010000000001000000010000"; 
			end case;
		end if;
	end process;
	
	pipe_manage: process(CLK, RST)
	begin
		if RST = '0' then 
			ID_EX <= (others => '0');
			EX_MEM <= (others => '0');
			MEM_WB <= (others => '0');
		elsif CLK'event and CLK = '1' then 
			if STALL = '0' or LAST_STALL = '1' then 
				ID_EX <= cw(21 downto 0);
			elsif FILL = '1' and TC = '0' then
				ID_EX <= "1100011001110111111010";
			elsif SPILL = '1' and TC = '0' then
				ID_EX <= "1100011001110101110000";
			else 
				ID_EX <= (others => '0');
			end if;
			EX_MEM <= ID_EX(11 downto 0);
			MEM_WB <= EX_MEM(3 downto 0);
		end if;
	end process;
	
	MEM_READ_HAZARD <= ID_EX(7);
	
	--IF_ID
	IF_ID_PIPE_EN <= '1';
	--DECODE
	J_REG_INSTR <= cw(33);
	BRANCH_INSTR <= cw(32);
	BR_EQ_NEQ_n <= cw(31);
	J_INSTR <= cw(30);                          
	I_INSTR_ID <= cw(29);
	JAL_INSTR <= cw(28);
	SIGNED_UNSIGNED_n_ID <= cw(27);
	STORE_INSTR <= cw(26);
	JR_INSTR <= cw(25);
	R_INSTR <= cw(24);
	MUL_INSTR_ID <= cw(23);
	--ID_EX
	ID_EX_PIPE_EN <= cw(22);
	--EXECUTE
	I_INSTR_EX <= ID_EX(21);
	ALU_EN <= ID_EX(20);
	ALU_FUNC <= ID_EX(19 downto 15); 			
	MUL_INSTR <= ID_EX(14);
	LHI_INSTR <= ID_EX(13);
	--EX_MEM
	EX_MEM_PIPE_EN <= ID_EX(12);
	--MEMORY
	DIMENSION <= EX_MEM(11 downto 10);
	SIGN_UNSIGN_n <= EX_MEM(9);
	MEM_EN <= EX_MEM(8);
	MEM_READ_WRITE_n <= EX_MEM(7);
	ALIGN_CHECK <= EX_MEM(6 downto 5); -- 01 byte -- 10 half -- 11 word 
	--MEM_WB
	MEM_WB_PIPE_EN <= EX_MEM(4);
	--WRITE BACK
	RF_WR_1_EN <= MEM_WB(3);
	RF_WR_2_EN <= MEM_WB(2);
	MEM_ALU_n <= MEM_WB(1);
	SEL_PC_WB <= MEM_WB(0);
	
	
end architecture;