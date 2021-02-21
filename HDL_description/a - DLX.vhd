library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.my_package.all;
use work.functions.all;

entity DLX is
port(
	CLK : in std_logic;
	RST : in std_logic;
	IRAM_ADDRESS : out std_logic_vector(31 downto 0);
	IRAM_DATA : in std_logic_vector(31 downto 0);
	DRAM_ADDRESS : out std_logic_vector(31 downto 0);
	DRAM_DATA_IN : out std_logic_vector(31 downto 0);
	DRAM_DATA_OUT : in std_logic_vector(31 downto 0);
	ALIGN_CHECK : out std_logic_vector(1 downto 0);
	DRAM_ENABLE : out std_logic;
	DRAM_READ_WRITE_n : out std_logic);
end entity;

architecture STRUCTURAL of DLX is
	component DATAPATH is
		port(CLK,RST: in std_logic;
			OPCODE					: out std_logic_vector(5 downto 0);
			FUNC					: out std_logic_vector(10 downto 0);
			STALL_OUT 				: out std_logic;
			LAST_STALL_OUT 			: out std_logic;
			FILL 					: out std_logic;
			SPILL 					: out std_logic;
			TC 						: out std_logic;
			IRAM_ADDRESS			: out std_logic_vector(31 downto 0);
			IRAM_DATA				: in std_logic_vector(31 downto 0);

			DRAM_ADDRESS			: out std_logic_vector(31 downto 0);
			DRAM_DATA_IN			: out std_logic_vector(31 downto 0);
			DRAM_DATA_OUT			: in std_logic_vector(31 downto 0);
			--IF/ID
			IF_ID_PIPE_EN : in std_logic;
			--DECODE
			J_REG_INSTR : in std_logic;
			BRANCH_INSTR : in std_logic;
			BR_EQ_NEQ_n : in std_logic;
			J_INSTR : in std_logic;
			I_INSTR_ID : in std_logic;
			JAL_INSTR : in std_logic;
			SIGNED_UNSIGNED_n_ID : in std_logic;
			STORE_INSTR : in std_logic;
			JR_INSTR : in std_logic;
			R_INSTR : in std_logic;
			MUL_INSTR_ID : in std_logic;
			--ID/EX
			ID_EX_PIPE_EN : in std_logic;
			--EXECUTE
			I_INSTR_EX : in std_logic;
			ALU_EN : in std_logic;
			ALU_FUNC : in std_logic_vector(4 downto 0);
			MUL_INSTR : in std_logic;
			LHI_INSTR : in std_logic;
			MEM_READ_HAZARD : in std_logic;
			--EX/MEM
			EX_MEM_PIPE_EN : in std_logic;
			--MEMORY
			MEM_READ : in std_logic;
			DIMENSION : in std_logic_vector(1 downto 0);
			SIGN_UNSIGN_n : in std_logic;
			--MEM/WB
			MEM_WB_PIPE_EN : in std_logic;
			--WRITE BACK
			RF_WR_1_EN : in std_logic;
			RF_WR_2_EN : in std_logic;
			MEM_ALU_n : in std_logic;
			SEL_PC_WB : in std_logic);
	end component;
	
	component CU is 
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
	end component;
	
	signal STALL_s : std_logic;
	signal LAST_STALL_s : std_logic;
	signal FUNC_s : std_logic_vector(10 downto 0);
	signal OPCODE_s : std_logic_vector(5 downto 0);
	signal IF_ID_PIPE_EN_s : std_logic;
	signal J_REG_INSTR_s :  std_logic;
	signal BRANCH_INSTR_s :  std_logic;
	signal BR_EQ_NEQ_n_s :  std_logic;
	signal J_INSTR_s :  std_logic;
	signal I_INSTR_ID_s :  std_logic;
	signal JAL_INSTR_s :  std_logic;
	signal SIGNED_UNSIGNED_n_ID_s :  std_logic;
	signal STORE_INSTR_s :  std_logic;
	signal JR_INSTR_s :  std_logic;
	signal R_INSTR_s :  std_logic;
	signal MUL_INSTR_ID_s : std_logic;
	signal ID_EX_PIPE_EN_s :  std_logic;
	signal I_INSTR_EX_s :  std_logic;
	signal ALU_EN_s :  std_logic;
	signal ALU_FUNC_s :  std_logic_vector(4 downto 0);
	signal MUL_INSTR_s :  std_logic;
	signal LHI_INSTR_s :  std_logic;
	signal MEM_READ_HAZARD_s : std_logic;
	signal EX_MEM_PIPE_EN_s :  std_logic;
	signal DIMENSION_s : std_logic_vector(1 downto 0);
	signal SIGN_UNSIGN_n_s :  std_logic;
	signal MEM_EN_s :  std_logic;
	signal MEM_READ_WRITE_n_s : std_logic;
	signal ALIGN_CHECK_s :  std_logic_vector(1 downto 0); -- 01 byte -- 10 half -- 11 word 
	signal MEM_WB_PIPE_EN_s :  std_logic;
	signal RF_WR_1_EN_s :  std_logic;
	signal RF_WR_2_EN_s :  std_logic;
	signal MEM_ALU_n_s :  std_logic;
	signal SEL_PC_WB_s :  std_logic;
	signal FILL_s : std_logic;
	signal SPILL_s : std_logic;
	signal TC_s : std_logic;
begin
	
	
	
	cu_inst : CU port map (	CLK => CLK,
							RST => RST,
							STALL => STALL_s,
							LAST_STALL => LAST_STALL_s,
							FILL => FILL_s,
							SPILL => SPILL_s,
							TC => TC_s,
							FUNC => FUNC_s,
							OPCODE => OPCODE_s,
							IF_ID_PIPE_EN => IF_ID_PIPE_EN_s,
							J_REG_INSTR => J_REG_INSTR_s,
							BRANCH_INSTR => BRANCH_INSTR_s,
							BR_EQ_NEQ_n => BR_EQ_NEQ_n_s,
							J_INSTR => J_INSTR_s,
							I_INSTR_ID => I_INSTR_ID_s,
							JAL_INSTR => JAL_INSTR_s,
							SIGNED_UNSIGNED_n_ID => SIGNED_UNSIGNED_n_ID_s,
							STORE_INSTR => STORE_INSTR_s,
							JR_INSTR => JR_INSTR_s,
							R_INSTR => R_INSTR_s,
							MUL_INSTR_ID => MUL_INSTR_ID_s,
							ID_EX_PIPE_EN => ID_EX_PIPE_EN_s,
							I_INSTR_EX => I_INSTR_EX_s,
							ALU_EN => ALU_EN_s,
							ALU_FUNC => ALU_FUNC_s,
							MUL_INSTR => MUL_INSTR_s,
							LHI_INSTR => LHI_INSTR_s,
							MEM_READ_HAZARD => MEM_READ_HAZARD_s,
							EX_MEM_PIPE_EN => EX_MEM_PIPE_EN_s,
							DIMENSION => DIMENSION_s,
							SIGN_UNSIGN_n => SIGN_UNSIGN_n_s,
							MEM_EN => MEM_EN_s,
							MEM_READ_WRITE_n => MEM_READ_WRITE_n_s,
							ALIGN_CHECK => ALIGN_CHECK_s,
							MEM_WB_PIPE_EN => MEM_WB_PIPE_EN_s,
							RF_WR_1_EN => RF_WR_1_EN_s,
							RF_WR_2_EN => RF_WR_2_EN_s,
							MEM_ALU_n => MEM_ALU_n_s,
							SEL_PC_WB => SEL_PC_WB_s);
							
	datapath_inst : DATAPATH port map(
									CLK => CLK,
									RST => RST,
									OPCODE => OPCODE_s,
									FUNC => FUNC_s,					
									STALL_OUT => STALL_s,	
									LAST_STALL_OUT => LAST_STALL_s,
									FILL => FILL_s,
									SPILL => SPILL_s,
									TC => TC_s,
									IRAM_ADDRESS => IRAM_ADDRESS,			
									IRAM_DATA => IRAM_DATA,				
									DRAM_ADDRESS => DRAM_ADDRESS,			
									DRAM_DATA_IN => DRAM_DATA_IN,			
									DRAM_DATA_OUT => DRAM_DATA_OUT,			
									IF_ID_PIPE_EN => IF_ID_PIPE_EN_s,
									J_REG_INSTR => J_REG_INSTR_s,
									BRANCH_INSTR => BRANCH_INSTR_s,
									BR_EQ_NEQ_n => BR_EQ_NEQ_n_s,
									J_INSTR => J_INSTR_s,
									I_INSTR_ID => I_INSTR_ID_s,
									JAL_INSTR => JAL_INSTR_s,
									SIGNED_UNSIGNED_n_ID => SIGNED_UNSIGNED_n_ID_s,
									STORE_INSTR => STORE_INSTR_s,
									JR_INSTR => JR_INSTR_s,
									R_INSTR => R_INSTR_s,
									MUL_INSTR_ID => MUL_INSTR_ID_s,
									ID_EX_PIPE_EN => ID_EX_PIPE_EN_s,
									I_INSTR_EX => I_INSTR_EX_s,
									ALU_EN => ALU_EN_s,
									ALU_FUNC => ALU_FUNC_s,
									MUL_INSTR => MUL_INSTR_s,
									LHI_INSTR => LHI_INSTR_s,
									MEM_READ_HAZARD => MEM_READ_HAZARD_s,
									EX_MEM_PIPE_EN => EX_MEM_PIPE_EN_s,
									MEM_READ => MEM_READ_WRITE_n_s,
									DIMENSION => DIMENSION_s,
									SIGN_UNSIGN_n => SIGN_UNSIGN_n_s,
									MEM_WB_PIPE_EN => MEM_WB_PIPE_EN_s,
									RF_WR_1_EN => RF_WR_1_EN_s,
									RF_WR_2_EN => RF_WR_2_EN_s,
									MEM_ALU_n => MEM_ALU_n_s,
									SEL_PC_WB => SEL_PC_WB_s);
									
	ALIGN_CHECK <= ALIGN_CHECK_s;
	DRAM_ENABLE <= MEM_EN_s;
	DRAM_READ_WRITE_n <= MEM_READ_WRITE_n_s;
end architecture;
