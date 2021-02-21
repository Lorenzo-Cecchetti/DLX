library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.my_package.all;
use work.functions.all;

entity DATAPATH is
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
		DIMENSION : in std_logic_vector(1 downto 0);
		SIGN_UNSIGN_n : in std_logic;
		MEM_READ : in std_logic;
		--MEM/WB
		MEM_WB_PIPE_EN : in std_logic;
		--WRITE BACK
		RF_WR_1_EN : in std_logic;
		RF_WR_2_EN : in std_logic;
		MEM_ALU_n : in std_logic;
		SEL_PC_WB : in std_logic);
end entity;

architecture structural of DATAPATH is 

	component REG_GEN is 
		generic (N: integer := 32);
		port(RST,EN,CLK: in std_logic;
			IN_DATA: in std_logic_vector(N-1 downto 0);
			OUT_DATA: out std_logic_vector(N-1 downto 0));
	end component;
	
	component REG_BIT is
		port(RST,EN,CLK: in std_logic;
		IN_DATA: in std_logic;
		OUT_DATA: out std_logic);
	end component;
	
	-- FETCH
	
	--BTB
	component BTB is
		port(	
			CLK : in std_logic;
			RESET : in std_logic;
			STALL : in std_logic;
			WRITE_DELETE : in std_logic_vector(1 downto 0);
			BR_INSTR : in std_logic;
			PC_CHECK : in std_logic_vector(31 downto 0); -- mi serve per accedere all'entry giusta usndo gli LSB,
														 -- per verificare che il PC contenuto dentro l'entry corrisponda a quello in ingresso 					   
			PC_WRITE : in std_logic_vector(31 downto 0); -- per aggiornare il pc di una entry nel caso il branch sia taken
			TARGET : in std_logic_vector(31 downto 0);  -- nuovo PC che viene mandato dalla ALU che devo inserire all'interno dell'entry se il branch risult taken
			NEW_PC : out std_logic_vector(31 downto 0);
			FOUND : out std_logic);
	end component;
	
	--PC ADDER
	component ADDER_PC is
		port(	PC : in std_logic_vector(31 downto 0);
				NEW_PC : out std_logic_vector(31 downto 0));
	end component;
	
	signal PC_BUS : std_logic_vector(31 downto 0);
	signal PC : std_logic_vector(31 downto 0);
	signal PC_ADD4 : std_logic_vector(31 downto 0);
	signal PC_BTB : std_logic_vector(31 downto 0);
	signal PC_GUESS_IF : std_logic_vector(31 downto 0);
	signal BTB_FOUND_IF : std_logic;
	signal BTB_WRITE_DELETE : std_logic_vector(1 downto 0);
	signal OPCODE_IF: std_logic_vector(5 downto 0);	--sent to the CU
	signal BR_INSTR_IF : std_logic;
	
	-- PIPELINE FETCH-DECODE
	
	signal PC_IF_ID : std_logic_vector(31 downto 0);
	signal PC_ADD4_IF_ID : std_logic_vector(31 downto 0);
	signal BTB_FOUND_ID : std_logic;
	signal IR_IF_ID: std_logic_vector(25 downto 0);
	signal OPCODE_IF_ID : std_logic_vector(5 downto 0);
	signal BR_INSTR_IF_ID : std_logic;
	-- DECODE
	
	component STACK is 
	port(
		RST : in std_logic;
		CLK : in std_logic;
		DATA_IN : in std_logic_vector(31 downto 0);
		CALL : in std_logic;
		RET : in std_logic;
		FILL : in std_logic;
		SPILL : in std_logic;
		STALL_J_REG : in std_logic;
		PREV_CALL : out std_logic;
		DATA_OUT : out std_logic_vector(31 downto 0));
	end component;
		
	-- ADDER FOR JUMP AND BRANCHES
	component JUMP_ADDER is
		port(
			A : in std_logic_vector( 31 downto 0);
			B : in std_logic_vector( 31 downto 0);
			S : out std_logic_vector( 31 downto 0));
	end component;
	
	-- COMPARATOR FOR BRANCHES
	component JUMP_COMPARATOR is
	port( 
		A : in std_logic_vector(31 downto 0);
		BR_INSTR : in std_logic;
		EQ_NEQ_n: in std_logic;
		COND : out std_logic);
	end component;
	
	--WINDOWED REGISTER FILE
	component WRF is 
	generic(M: integer := 5; --# of global registers
				N: integer := 5; --# of register in each block (IN, OUT, LOCAL)
				F: integer := 3; --# of windows
				N_bit: integer := 32);
		port(WRITE_1: in std_logic_vector(N_bit-1 downto 0);
			 WRITE_2: in std_logic_vector(2*N_bit-1 downto 0);
			 WRITE_1_EN, WRITE_2_EN: in std_logic;
			 READ_1_ADDR,READ_2_ADDR,WRITE_1_ADDR, WRITE_2_ADDR: in std_logic_vector(6 downto 0);
			 RST: in std_logic;
			 CLK: in std_logic; 
			 READ_1,READ_2: out std_logic_vector(N_bit-1 downto 0));
	end component;
	
	--REGISTER FILE DECODER ADDRESS
	component RF_DECODER is 
	generic(M: integer := 5; --# of global registers
				N: integer := 5; --# of register in each block (IN, OUT, LOCAL)
				F: integer := 3; --# of windows
				N_bit: integer := 32); 
	port(CLK : in std_logic;
		RST : in std_logic;
		RET : in std_logic;
		CALL : in std_logic;
		READ_1_ADDR : in std_logic_vector(4 downto 0);
		READ_2_ADDR : in std_logic_vector(4 downto 0);
		RD_ADDR : in std_logic_vector(4 downto 0);
		STALL_J_REG : in std_logic;
		READ_1_ADDR_OUT : out std_logic_vector(6 downto 0);
		READ_2_ADDR_OUT : out std_logic_vector(6 downto 0);
		RD_ADDR_OUT : out std_logic_vector(6 downto 0);
		FILL : buffer std_logic;
		SPILL : buffer std_logic;
		FILL_SPILL_IMM : out std_logic_vector(31 downto 0);
		TC : buffer std_logic);
	end component;
	
	-- DECODE INSTRUCTION + IMMEDIATE EXTENCTION
	component DECODE_IMM_EXT is
		port (
			J_INSTR : in std_logic;
			I_INSTR : in std_logic;
			JAL_INSTR : in std_logic;
			IR : in std_logic_vector(25 downto 0);
			SIGNED_UNSIGNED_n : in std_logic;
			STORE_INSTR : in std_logic;
			
			RS_1, RS_2, RD : out std_logic_vector(4 downto 0);
			IMMEDIATE : out std_logic_vector(31 downto 0));
	end component; 
	
	--HAZARD DETECTION UNIT
	component HAZARD_UNIT is
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
	end component;
	
	signal BRANCH_COND : std_logic;
	signal PC_JUMP_ADDER : std_logic_vector(31 downto 0);
	signal PC_REG_JUMP_ID : std_logic_vector(31 downto 0);
	signal PC_CORRECTION_ID : std_logic_vector(31 downto 0);
	signal PC_CORRECT_ID : std_logic_vector(31 downto 0);
	signal PC_JUMP_ID : std_logic_vector(31 downto 0);
	signal IMMEDIATE_ID: std_logic_vector(31 downto 0);
	signal BRANCH_COND_ID: std_logic;
	signal RF_OUT_1_ID: std_logic_vector(31 downto 0);
	signal RF_OUT_2_ID: std_logic_vector(31 downto 0);
	signal STALL: std_logic;
	signal RS_1_ID: std_logic_vector(4 downto 0);
	signal RS_2_ID: std_logic_vector(4 downto 0);
	signal RD_ID: std_logic_vector(4 downto 0);
	signal FUNC_ID: std_logic_vector(10 downto 0);
	signal RET_ID: std_logic;
	signal RF_SPILL_ID: std_logic;
	signal RF_FILL_ID: std_logic;
	signal FW_J_REG_PC : std_logic_vector(31 downto 0);
	signal MISPREDICTION : std_logic;
	signal OPCODE_ID : std_logic_vector(5 downto 0);
	signal IR_ID : std_logic_vector(25 downto 0);
	signal A_PIPE_INPUT : std_logic_vector(31 downto 0);
	signal B_PIPE_INPUT : std_logic_vector(31 downto 0);	
	signal STALL_IF_ID : std_logic;
	signal LAST_STALL : std_logic;
	signal RF_READ_ADDR_1_DEC : std_logic_vector(6 downto 0);
	signal RF_READ_ADDR_2_DEC : std_logic_vector(6 downto 0);
	signal RF_RD_ADDR_DEC : std_logic_vector(6 downto 0);
	signal RF_DEC_TC : std_logic;
	signal FILL_SPILL_IMM : std_logic_vector(31 downto 0);
	signal IMMEDIATE_IR : std_logic_vector(31 downto 0);
	signal STACK_OUT_ID : std_logic_vector(31 downto 0);
	signal RF_WB_WR1_EN : std_logic;
	signal STACK_DATA_IN : std_logic_vector(31 downto 0);
	signal PREV_CALL : std_logic;
	signal STALL_J_REG : std_logic;

	-- PIPELINE DECODE-EXECUTE
	
	signal RD_ID_EX: std_logic_vector(6 downto 0);
	signal RF_OUT_1_ID_EX : std_logic_vector(31 downto 0);
	signal RF_OUT_2_ID_EX : std_logic_vector(31 downto 0);
	signal IMMEDIATE_ID_EX : std_logic_vector(31 downto 0);
	signal RS_1_ID_EX : std_logic_vector(6 downto 0);
	signal RS_2_ID_EX : std_logic_vector(6 downto 0);
	signal PC_ADD4_ID_EX : std_logic_vector(31 downto 0);
	signal RET_ID_EX : std_logic;
	signal FILL_ID_EX : std_logic;
	signal SPILL_ID_EX : std_logic;
	signal STACK_OUT_ID_EX : std_logic_vector(31 downto 0);
	signal JAL_INSTR_ID_EX : std_logic;
	
	-- EXECUTE
	
	component FWU is 
		port(RS_1_ID_EX,RS_2_ID_EX: in std_logic_vector(6 downto 0);
			RD_1_MUL_EX_MEM : in std_logic_vector(6 downto 0);
			RD_2_MUL_EX_MEM : in std_logic_vector(6 downto 0);
			RS_2_EX_MEM : in std_logic_vector(6 downto 0);
			RD_EX_MEM : in std_logic_vector(6 downto 0);
			RD_MEM_WB : in std_logic_vector(6 downto 0);
			RD_ID_EX : in std_logic_vector(6 downto 0);
			RD_1_MUL_MEM_WB : in std_logic_vector(6 downto 0);
			RD_2_MUL_MEM_WB : in std_logic_vector(6 downto 0);
			RS_1_ID: in std_logic_vector(6 downto 0);
			RS_2_ID: in std_logic_vector(6 downto 0);
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
	end component;

	--ALU
	component ALU is    
		port(A,B: in std_logic_vector(31 downto 0);
			clk: in std_logic;
			ALU_EN : in std_logic;
			func: in std_logic_vector(4 downto 0);
			SW: out std_logic_vector(1 downto 0); -- STATUS WORD SW(0) => C; SW(1) => O;
			O_32: out std_logic_vector(31 downto 0);
			O_64: out std_logic_vector(63 downto 0));
	end component;
	
	signal RD_1_MUL_PIPE_EX: mul_pipe_t;
	signal RD_2_MUL_PIPE_EX: mul_pipe_t;
	signal RD_EX: std_logic_vector(6 downto 0);
	signal ALU_IN_1_EX : std_logic_vector(31 downto 0);
	signal ALU_IN_2_EX : std_logic_vector(31 downto 0);
	signal ALU_OUT_32_EX : std_logic_vector(31 downto 0);
	signal ALU_OUT_64_EX : std_logic_vector(63 downto 0);
	signal ALU_SW_EX : std_logic_vector(1 downto 0);
	signal FW_EX_TO_EX_A,FW_EX_TO_EX_B: std_logic_vector(1 downto 0);
	signal FW_MEM_TO_EX_A,FW_MEM_TO_EX_B: std_logic_vector(1 downto 0);
	signal FW_MEM_TO_MEM: std_logic_vector(1 downto 0);
	signal FW_ID_TO_ID : std_logic;
	signal FW_EX_TO_ID: std_logic_vector(1 downto 0);
	signal FW_MEM_TO_ID : std_logic_vector(1 downto 0);
	signal FW_EX_TO_ID_STACK : std_logic;
	signal FW_MEM_TO_ID_STACK : std_logic_vector(1 downto 0);
	signal FW_WB_TO_ID_STACK : std_logic_vector(1 downto 0);
	signal RD_2_MUL_MUX_IN : std_logic_vector(6 downto 0);
	signal RD_1_MUL_MUX_OUT : std_logic_vector(6 downto 0);
	signal RD_2_MUL_MUX_OUT : std_logic_vector(6 downto 0);
	signal LHI_RESULT : std_logic_vector(31 downto 0);
	signal DATA_OUT_EX : std_logic_vector(31 downto 0);
	signal MUL_DELAY_EX : std_logic_vector(6 downto 0);
	signal STORE_DATA_EX : std_logic_vector(31 downto 0);
			
	-- PIPELINE EXECUTE-MEMORY
	signal DRAM_ADDRESS_EX_MEM : std_logic_vector(31 downto 0);
	signal RD_EX_MEM: std_logic_vector(6 downto 0);
	signal RD_1_MUL_EX_MEM: std_logic_vector(6 downto 0);
	signal RD_2_MUL_EX_MEM: std_logic_vector(6 downto 0);
	signal DATA_OUT_EX_MEM: std_logic_vector(31 downto 0);
	signal DATA_MUL_OUT_EX_MEM: std_logic_vector(63 downto 0);
	signal STORE_DATA_EX_MEM: std_logic_vector(31 downto 0);
	signal PC_ADD4_EX_MEM : std_logic_vector(31 downto 0);
	signal RS_2_EX_MEM : std_logic_vector(6 downto 0);
	signal RET_EX_MEM : std_logic;
	signal JAL_INSTR_EX_MEM : std_logic;
	
	-- MEMORY
	
	component LHU is 
		port(MEM_OUT: in std_logic_vector (31 downto 0);
			DIMENSION : in std_logic_vector(1 downto 0);
			SIGN_UNSIGN_n: in std_logic;
			LHU_OUT: out std_logic_vector (31 downto 0));
	end component;
	
	signal LOAD_DATA_MEM: std_logic_vector(31 downto 0);
	signal DRAM_OUT_MEM: std_logic_vector(31 downto 0);
	signal MUL_DELAY_MEM : std_logic_vector(6 downto 0);
	
	-- PIPELINE MEMORY-WRITEBACK
	signal RD_MEM_WB: std_logic_vector(6 downto 0);
	signal RD_1_MUL_MEM_WB: std_logic_vector(6 downto 0);
	signal RD_2_MUL_MEM_WB: std_logic_vector(6 downto 0);
	signal DATA_OUT_MEM_WB: std_logic_vector(31 downto 0);
	signal DATA_MUL_OUT_MEM_WB: std_logic_vector(63 downto 0);
	signal DATA_LOAD_MEM_WB: std_logic_vector(31 downto 0);
	signal PC_ADD4_MEM_WB : std_logic_vector(31 downto 0);
	signal MEM_READ_MEM_WB : std_logic;
	signal RET_MEM_WB : std_logic;
	
	-- WRITEBACK
	signal DATA_OUT_WB: std_logic_vector(31 downto 0);
	signal PIPE_RF_WRITE_2_EN : std_logic_vector(6 downto 0);
	signal MEM_ALU_WB : std_logic_vector(31 downto 0);
	
begin
	-- FETCH	
	-- pc register
	pc_reg : REG_GEN generic map(N => 32) port map(RST => RST, CLK => CLK, EN => '1', IN_DATA => PC_BUS, OUT_DATA => PC);
	
	-- adder pc+4
	add_pc : ADDER_PC port map(PC => PC, NEW_PC => PC_ADD4);
	
	-- logic used to detect a branch instruction in fetch in order to correctly write in the BTB during the decode stage (in this way we have avoided to write in the EX stage)
	check_opcd: process(IRAM_DATA)
	begin
		if IRAM_DATA(31 downto 26) = "000100" or IRAM_DATA(31 downto 26) = "000101" then 
			BR_INSTR_IF <= '1';
		else 
			BR_INSTR_IF <= '0';
		end if;
	end process;
	
	-- btb
	BTB_WRITE_DELETE(0) <= '1' when BTB_FOUND_ID = '1' and BRANCH_COND_ID = '0' else '0';
	BTB_WRITE_DELETE(1) <= '1' when BTB_FOUND_ID = '0' and BRANCH_COND_ID = '1' else '0';
	btb_inst : BTB port map(CLK => CLK, RESET => RST, STALL => STALL, WRITE_DELETE => BTB_WRITE_DELETE, BR_INSTR => BR_INSTR_IF_ID, PC_CHECK => PC, TARGET => PC_JUMP_ADDER, PC_WRITE => PC_IF_ID, FOUND => BTB_FOUND_IF, NEW_PC => PC_BTB); 
	
	-- mux between btb and adder+4
	PC_GUESS_IF <= PC_BTB when BTB_FOUND_IF = '1' else PC_ADD4;
	
	--input to the IRAM
	IRAM_ADDRESS <= PC;
	
	-- mux to manage the flush of the pipeline in case of branch misprediction. In this way we are going to change the cw to a nop instruction.
	MISPREDICTION <= (BTB_FOUND_ID XOR BRANCH_COND_ID) AND BRANCH_INSTR;
	OPCODE_ID <= (others => '0') when (MISPREDICTION or J_REG_INSTR or J_INSTR) = '1' else IRAM_DATA(31 downto 26);
	IR_ID <= (others => '0') when (MISPREDICTION or J_REG_INSTR or J_INSTR) = '1' else IRAM_DATA(25 downto 0);
	
	-- PIPELINE FETCH - DECODE
	
	STALL_IF_ID <= not(STALL) or LAST_STALL;
	
	br_instr_reg: REG_BIT port map(CLK => CLK, RST => RST, EN => STALL_IF_ID, IN_DATA => BR_INSTR_IF, OUT_DATA => BR_INSTR_IF_ID);
	found_inst : REG_BIT port map(CLK => CLK, RST => RST, EN => STALL_IF_ID, IN_DATA => BTB_FOUND_IF, OUT_DATA => BTB_FOUND_ID);
	pc_pipe : REG_GEN generic map(N => 32) port map(CLK => CLK, RST => RST, EN => STALL_IF_ID, IN_DATA => PC, OUT_DATA => PC_IF_ID); --CW : IF_ID_PIPE_EN
	pc_4_pipe : REG_GEN generic map(N => 32) port map(CLK => CLK, RST => RST, EN => STALL_IF_ID, IN_DATA => PC_ADD4, OUT_DATA => PC_ADD4_IF_ID);
	IR: REG_GEN generic map(N => 26) port map(CLK => CLK, RST => RST, EN => STALL_IF_ID, IN_DATA => IR_ID, OUT_DATA => IR_IF_ID);
	opcd: REG_GEN generic map(N => 6) port map(CLK => CLK, RST => RST, EN => STALL_IF_ID, IN_DATA => OPCODE_ID, OUT_DATA => OPCODE);
	-- DECODE
	
	-- send the func bits to the cu
	FUNC <= IR_IF_ID(10 downto 0);
	
	--adder/subtractor and comparator for branch instructions
	jump_add: JUMP_ADDER port map(A => PC_ADD4_IF_ID, B => IMMEDIATE_ID, S => PC_JUMP_ADDER);
	jump_comp: JUMP_COMPARATOR port map(A => FW_J_REG_PC,EQ_NEQ_n => BR_EQ_NEQ_n, BR_INSTR => BRANCH_INSTR, COND => BRANCH_COND_ID);
	
	mux_jump_pc: process(FW_EX_TO_ID, FW_MEM_TO_ID, RF_OUT_1_ID, DATA_OUT_WB, DATA_MUL_OUT_MEM_WB, DATA_MUL_OUT_EX_MEM, DATA_OUT_EX_MEM,
						PC_ADD4_EX_MEM,PC_ADD4_ID_EX,JAL_INSTR_EX_MEM,FW_ID_TO_ID)
						
		variable out_mux_mem: std_logic_vector(31 downto 0);
		variable out_mux_ex : std_logic_vector(31 downto 0);
	begin
		case FW_MEM_TO_ID is
			when "00" => out_mux_mem := RF_OUT_1_ID;
			when "01" => out_mux_mem := DATA_MUL_OUT_MEM_WB(31 downto 0);
			when "10" => out_mux_mem := DATA_MUL_OUT_MEM_WB(63 downto 32);
			when others => out_mux_mem := DATA_OUT_WB;
		end case;
		
		case FW_EX_TO_ID is 
			when "00" => out_mux_ex := out_mux_mem;
			when "01" => out_mux_ex := DATA_MUL_OUT_EX_MEM(31 downto 0);
			when "10" => out_mux_ex := DATA_MUL_OUT_EX_MEM(63 downto 32);
			when others => 	if JAL_INSTR_EX_MEM = '1' then
								out_mux_ex := PC_ADD4_EX_MEM;
							else
								out_mux_ex := DATA_OUT_EX_MEM;
							end if;
		end case;
		
		case FW_ID_TO_ID is 
			when '0' => FW_J_REG_PC <= out_mux_ex;
			when '1' => FW_J_REG_PC <= PC_ADD4_ID_EX;
			when others => null;
		end case;
	end process;
	
	jmp_manage: process(J_INSTR,J_REG_INSTR,BRANCH_INSTR,BTB_FOUND_ID,BRANCH_COND_ID,PC_JUMP_ADDER,PC_ADD4,FW_J_REG_PC,PC_ADD4_IF_ID,STALL,LAST_STALL,PC_GUESS_IF,RET_ID,
						STACK_OUT_ID, PREV_CALL)
	begin
		if STALL = '0' or LAST_STALL = '1' then
			if J_INSTR = '1' then
				PC_BUS <= PC_JUMP_ADDER;
			elsif J_REG_INSTR = '1' then
				if RET_ID = '1' and PREV_CALL = '0' then
					PC_BUS <= STACK_OUT_ID;
				else
					PC_BUS <= FW_J_REG_PC;
				end if;
			elsif BRANCH_INSTR = '1' then
				if BTB_FOUND_ID = '1' and BRANCH_COND_ID = '0' then
					PC_BUS <= PC_ADD4_IF_ID;
				elsif BTB_FOUND_ID = '0' and BRANCH_COND_ID = '1' then
					PC_BUS <= PC_JUMP_ADDER;
				else
					PC_BUS <= PC_GUESS_IF;
				end if;
			else
				PC_BUS <= PC_GUESS_IF;
			end if;
		else
			PC_BUS <= PC;
		end if;
	end process;
	
	-- FUNC_ID must be sent to the CU
	decode_IR: DECODE_IMM_EXT port map(J_INSTR => J_INSTR, I_INSTR => I_INSTR_ID, JAL_INSTR => JAL_INSTR, IR => IR_IF_ID, SIGNED_UNSIGNED_n => SIGNED_UNSIGNED_n_ID, 
										STORE_INSTR => STORE_INSTR, RS_1 => RS_1_ID, RS_2 => RS_2_ID, RD => RD_ID, IMMEDIATE => IMMEDIATE_IR);
	
	rf_dec: RF_DECODER generic map( M=>8, N=>8, F=>4, N_bit=>32) port map(CLK => CLK, RST => RST, RET => RET_ID, CALL => JAL_INSTR, READ_1_ADDR => RS_1_ID, 
																			READ_2_ADDR => RS_2_ID, RD_ADDR => RD_ID, READ_1_ADDR_OUT => RF_READ_ADDR_1_DEC, 
																			READ_2_ADDR_OUT => RF_READ_ADDR_2_DEC, RD_ADDR_OUT => RF_RD_ADDR_DEC, STALL_J_REG => STALL_J_REG,
																			FILL => RF_FILL_ID, SPILL => RF_SPILL_ID, TC => RF_DEC_TC, FILL_SPILL_IMM => FILL_SPILL_IMM);
																			
	FILL <= RF_FILL_ID;
	SPILL <= RF_SPILL_ID;
	TC <= RF_DEC_TC;
	
	reg_file: WRF generic map(M => 8, N => 8, F => 4, N_bit =>32) port map(WRITE_1 => DATA_OUT_WB, WRITE_2 => DATA_MUL_OUT_MEM_WB, WRITE_1_EN => RF_WB_WR1_EN, 
																	WRITE_2_EN => PIPE_RF_WRITE_2_EN(6), READ_1_ADDR => RF_READ_ADDR_1_DEC, READ_2_ADDR => RF_READ_ADDR_2_DEC,
																	WRITE_1_ADDR => RD_MEM_WB, WRITE_2_ADDR => RD_1_MUL_MEM_WB, RST => RST, CLK => CLK,
																	READ_1 => RF_OUT_1_ID, READ_2 => RF_OUT_2_ID);
																	
	-- signal used to enable the RF also when we have a RET (RET is a JR that doesn't write in the RF by default)
	RF_WB_WR1_EN <= RF_WR_1_EN or RET_MEM_WB;
	
	mux_stack: process(FW_MEM_TO_ID_STACK,RF_OUT_2_ID,DATA_MUL_OUT_MEM_WB,DATA_OUT_WB,DATA_OUT_EX_MEM,FW_EX_TO_ID_STACK,DATA_MUL_OUT_EX_MEM,JAL_INSTR_EX_MEM,FW_WB_TO_ID_STACK,
						PC_ADD4_EX_MEM,JAL_INSTR_ID_EX,PC_ADD4_ID_EX,DATA_OUT_EX)
	variable stk_data_wb: std_logic_vector(31 downto 0);
	variable stk_data_mem: std_logic_vector(31 downto 0);
	begin
		case FW_WB_TO_ID_STACK is
			when "00" => stk_data_wb := RF_OUT_2_ID;
			when "01" => stk_data_wb := DATA_MUL_OUT_MEM_WB(31 downto 0);
			when "10" => stk_data_wb := DATA_MUL_OUT_MEM_WB(63 downto 32);
			when "11" => stk_data_wb := DATA_OUT_WB;
			when others => null;
		end case;
		
		case FW_MEM_TO_ID_STACK is
			when "00" => stk_data_mem := stk_data_wb;
			when "01" => stk_data_mem := DATA_MUL_OUT_EX_MEM(31 downto 0);
			when "10" => stk_data_mem := DATA_MUL_OUT_EX_MEM(63 downto 32);
			when "11" => 	if JAL_INSTR_EX_MEM = '1' then --if added to forward the correct data in case the previous instruction is a JAL or a normal one that modifies r31
								stk_data_mem := PC_ADD4_EX_MEM;
							else 
								stk_data_mem := DATA_OUT_EX_MEM;
							end if;
			when others => null;
		end case;
		
		case FW_EX_TO_ID_STACK is
			when '0' => STACK_DATA_IN <= stk_data_mem;
			when '1' => if JAL_INSTR_ID_EX = '1' then --if added to forward the correct data in case the previous instruction is a JAL or a normal one that modifies r31
							STACK_DATA_IN <= PC_ADD4_ID_EX;
						else 
							STACK_DATA_IN <= DATA_OUT_EX;
						end if;
			when others => null;
		end case;
	end process;
	
	stack_inst : STACK port map(CLK => CLK, RST => RST, DATA_IN => STACK_DATA_IN, CALL => JAL_INSTR, RET => RET_ID, DATA_OUT => STACK_OUT_ID,
								FILL => RF_FILL_ID, SPILL => RF_SPILL_ID, PREV_CALL => PREV_CALL, STALL_J_REG => STALL_J_REG);
	
	-- CW: JR_INSTR(decode) 
	return_signal: process(JR_INSTR,RS_1_ID)
	begin
		if JR_INSTR = '1' then
			if RS_1_ID = "11111" then 
				RET_ID <= '1';
			else 
				RET_ID <= '0';
			end if;
		else 
			RET_ID <= '0';
		end if;
	end process;
	
	-- CW: RF_WR_1_EN(write back) 
	
					
	--logic to manage a read and write that happen simultaneously, in this way we are able to read the new value instead of the old one				
	rf_out: process(PIPE_RF_WRITE_2_EN(6), RF_WB_WR1_EN, RF_READ_ADDR_1_DEC, RD_MEM_WB, RF_READ_ADDR_2_DEC, RD_1_MUL_MEM_WB, RD_2_MUL_MEM_WB, RF_OUT_2_ID, DATA_OUT_WB,RF_OUT_1_ID, DATA_MUL_OUT_MEM_WB)
	begin
		if PIPE_RF_WRITE_2_EN(6) = '0'  and RF_WB_WR1_EN = '1' then
		
			if RF_READ_ADDR_1_DEC = RD_MEM_WB then 
				A_PIPE_INPUT <= DATA_OUT_WB;
			else
				A_PIPE_INPUT <= RF_OUT_1_ID;
			end if;
			
			if RF_READ_ADDR_2_DEC = RD_MEM_WB then
				B_PIPE_INPUT <= DATA_OUT_WB;
			else
				B_PIPE_INPUT <= RF_OUT_2_ID;
			end if;
		elsif PIPE_RF_WRITE_2_EN(6) = '1'  and RF_WB_WR1_EN = '0' then
			if RF_READ_ADDR_1_DEC = RD_1_MUL_MEM_WB then 
				A_PIPE_INPUT <= DATA_MUL_OUT_MEM_WB(63 downto 32);
			elsif RF_READ_ADDR_1_DEC = RD_2_MUL_MEM_WB then 
				A_PIPE_INPUT <= DATA_MUL_OUT_MEM_WB(31 downto 0);
			else
				A_PIPE_INPUT <= RF_OUT_1_ID;
			end if;
			
			if RF_READ_ADDR_2_DEC = RD_1_MUL_MEM_WB then 
				B_PIPE_INPUT <= DATA_MUL_OUT_MEM_WB(63 downto 32);
			elsif RF_READ_ADDR_2_DEC = RD_2_MUL_MEM_WB then 
				B_PIPE_INPUT <= DATA_MUL_OUT_MEM_WB(31 downto 0);
			else
				B_PIPE_INPUT <= RF_OUT_2_ID;
			end if;
		elsif PIPE_RF_WRITE_2_EN(6) = '1'  and RF_WB_WR1_EN = '1' then
			if RF_READ_ADDR_1_DEC = RD_1_MUL_MEM_WB then 
				A_PIPE_INPUT <= DATA_MUL_OUT_MEM_WB(63 downto 32);
			elsif RF_READ_ADDR_1_DEC = RD_2_MUL_MEM_WB then 
				A_PIPE_INPUT <= DATA_MUL_OUT_MEM_WB(31 downto 0);
			elsif RF_READ_ADDR_1_DEC = RD_MEM_WB then 
				A_PIPE_INPUT <= DATA_OUT_WB;
			else
				A_PIPE_INPUT <= RF_OUT_1_ID;
			end if;
			
			if RF_READ_ADDR_2_DEC = RD_1_MUL_MEM_WB then 
				B_PIPE_INPUT <= DATA_MUL_OUT_MEM_WB(63 downto 32);
			elsif RF_READ_ADDR_2_DEC = RD_2_MUL_MEM_WB then 
				B_PIPE_INPUT <= DATA_MUL_OUT_MEM_WB(31 downto 0);
			elsif RF_READ_ADDR_2_DEC = RD_MEM_WB then
				B_PIPE_INPUT <= DATA_OUT_WB;
			else
				B_PIPE_INPUT <= RF_OUT_2_ID;
			end if;
		else 
			A_PIPE_INPUT <= RF_OUT_1_ID;
			B_PIPE_INPUT <= RF_OUT_2_ID;
		end if;
	end process;
	
	-- CW: R_INSTR(decode) MEM_READ_HAZARD(memory)
	hdu: HAZARD_UNIT port map(J_REG_INSTR => J_REG_INSTR,MUL_INSTR => MUL_INSTR, MUL_INSTR_ID => MUL_INSTR_ID, STORE_INSTR => STORE_INSTR, BRANCH_INSTR => BRANCH_INSTR, RD_ID => RF_RD_ADDR_DEC, RD_ID_EX => RD_ID_EX,
								RD_1_MUL_PIPE => RD_1_MUL_PIPE_EX, RD_2_MUL_PIPE => RD_2_MUL_PIPE_EX, MEM_READ => MEM_READ_HAZARD, R_INSTR => R_INSTR,
								I_INSTR => I_INSTR_ID, FILL => RF_FILL_ID, SPILL => RF_SPILL_ID, RS_1 => RF_READ_ADDR_1_DEC, RS_2 => RF_READ_ADDR_2_DEC, STALL => STALL,
								LAST_STALL => LAST_STALL, STALL_J_REG_OUT => STALL_J_REG);
								
	STALL_OUT <= STALL;
	LAST_STALL_OUT <= LAST_STALL;
	
	IMMEDIATE_ID <= IMMEDIATE_IR when (RF_FILL_ID = '0' and RF_SPILL_ID = '0') else FILL_SPILL_IMM;
	-- PIPELINE DECODE - EXECUTE
	
	-- CW : ID_EX_PIPE_EN
	fill_reg_id_ex : REG_BIT port map(CLK => CLK, RST => RST, EN => ID_EX_PIPE_EN, IN_DATA => RF_FILL_ID, OUT_DATA => FILL_ID_EX);
	spill_reg_id_ex : REG_BIT port map(CLK => CLK, RST => RST, EN => ID_EX_PIPE_EN, IN_DATA => RF_SPILL_ID, OUT_DATA => SPILL_ID_EX);
	a_reg: REG_GEN generic map(N => 32) port map(RST => RST, CLK => CLK, EN => ID_EX_PIPE_EN, IN_DATA => A_PIPE_INPUT, OUT_DATA => RF_OUT_1_ID_EX);
	b_reg: REG_GEN generic map(N => 32) port map(RST => RST, CLK => CLK, EN => ID_EX_PIPE_EN, IN_DATA => B_PIPE_INPUT, OUT_DATA => RF_OUT_2_ID_EX);
	imm_reg: REG_GEN generic map(N => 32) port map(RST => RST, CLK => CLK, EN => ID_EX_PIPE_EN, IN_DATA => IMMEDIATE_ID, OUT_DATA => IMMEDIATE_ID_EX);
	rd_reg: REG_GEN generic map(N => 7) port map(RST => RST, CLK => CLK, EN => ID_EX_PIPE_EN, IN_DATA => RF_RD_ADDR_DEC, OUT_DATA => RD_ID_EX);
	rs1_reg: REG_GEN generic map(N => 7) port map(RST => RST, CLK => CLK, EN => ID_EX_PIPE_EN, IN_DATA => RF_READ_ADDR_1_DEC, OUT_DATA => RS_1_ID_EX);
	rs2_reg: REG_GEN generic map(N => 7) port map(RST => RST, CLK => CLK, EN => ID_EX_PIPE_EN, IN_DATA => RF_READ_ADDR_2_DEC, OUT_DATA => RS_2_ID_EX);
	pc4_reg_ex: REG_GEN generic map(N => 32) port map(RST => RST, CLK => CLK, EN => ID_EX_PIPE_EN, IN_DATA => PC_ADD4_IF_ID, OUT_DATA => PC_ADD4_ID_EX);
	stack_out_reg : REG_GEN generic map(N => 32) port map(RST => RST, CLK => CLK, EN => ID_EX_PIPE_EN, IN_DATA => STACK_OUT_ID, OUT_DATA => STACK_OUT_ID_EX);
	ret_id_ex_reg : REG_BIT port map(CLK => CLK, RST => RST, EN => ID_EX_PIPE_EN, IN_DATA => RET_ID, OUT_DATA => RET_ID_EX);
	jal_id_ex_reg : REG_BIT port map(CLK => CLK, RST => RST, EN => ID_EX_PIPE_EN, IN_DATA => JAL_INSTR, OUT_DATA => JAL_INSTR_ID_EX);
	
	-- EXECUTE
	
	LHI_RESULT <= IMMEDIATE_ID_EX(15 downto 0) & x"0000";
	
	mux_a_alu: process(FW_EX_TO_EX_A, FW_MEM_TO_EX_A, RF_OUT_1_ID_EX, DATA_OUT_WB, 
						DATA_MUL_OUT_MEM_WB, DATA_MUL_OUT_EX_MEM, DATA_OUT_EX_MEM, 
						SPILL_ID_EX, FILL_ID_EX)
		variable ALU_A_MEM_FW: std_logic_vector(31 downto 0);
	begin
		if SPILL_ID_EX = '1' or FILL_ID_EX = '1' then
			ALU_IN_1_EX <= std_logic_vector(to_unsigned(1020,32));
		else
			case FW_MEM_TO_EX_A is
				when "00" => ALU_A_MEM_FW := RF_OUT_1_ID_EX;
				when "01" => ALU_A_MEM_FW := DATA_MUL_OUT_MEM_WB(31 downto 0);
				when "10" => ALU_A_MEM_FW := DATA_MUL_OUT_MEM_WB(63 downto 32);
				when others => ALU_A_MEM_FW := DATA_OUT_WB;
			end case;
			
			case FW_EX_TO_EX_A is 
				when "00" => ALU_IN_1_EX <= ALU_A_MEM_FW;
				when "01" => ALU_IN_1_EX <= DATA_MUL_OUT_EX_MEM(31 downto 0);
				when "10" => ALU_IN_1_EX <= DATA_MUL_OUT_EX_MEM(63 downto 32);
				when others => ALU_IN_1_EX <= DATA_OUT_EX_MEM;
			end case;
		end if;
	end process;
	
	-- CW: I_INSTR
	mux_b_alu: process(FW_MEM_TO_EX_B, FW_EX_TO_EX_B, RF_OUT_2_ID_EX, DATA_OUT_WB, DATA_MUL_OUT_MEM_WB, I_INSTR_EX, IMMEDIATE_ID_EX, DATA_MUL_OUT_EX_MEM, DATA_OUT_EX_MEM, SPILL_ID_EX, FILL_ID_EX)
		variable ALU_B_MEM_FW: std_logic_vector(31 downto 0);
	begin
		if I_INSTR_EX = '1' then 
			ALU_IN_2_EX <= IMMEDIATE_ID_EX;
		else 
			case FW_MEM_TO_EX_B is
				when "00" => ALU_B_MEM_FW := RF_OUT_2_ID_EX;
				when "01" => ALU_B_MEM_FW := DATA_MUL_OUT_MEM_WB(31 downto 0); 
				when "10" => ALU_B_MEM_FW := DATA_MUL_OUT_MEM_WB(63 downto 32); 
				when others => ALU_B_MEM_FW := DATA_OUT_WB; 
			end case;
			
			case FW_EX_TO_EX_B is 
				when "00" => ALU_IN_2_EX <= ALU_B_MEM_FW;
				when "01" => ALU_IN_2_EX <= DATA_MUL_OUT_EX_MEM(31 downto 0); 
				when "10" => ALU_IN_2_EX <= DATA_MUL_OUT_EX_MEM(63 downto 32); 
				when others => ALU_IN_2_EX <= DATA_OUT_EX_MEM; 
			end case;
		end if;
	end process;
	
	mux_store_data: process(FW_MEM_TO_EX_B, FW_EX_TO_EX_B, RF_OUT_2_ID_EX, DATA_OUT_WB, DATA_MUL_OUT_MEM_WB, DATA_MUL_OUT_EX_MEM, DATA_OUT_EX_MEM)
		variable ALU_B_MEM_FW: std_logic_vector(31 downto 0);
	begin
		case FW_MEM_TO_EX_B is
			when "00" => ALU_B_MEM_FW := RF_OUT_2_ID_EX;
			when "01" => ALU_B_MEM_FW := DATA_MUL_OUT_MEM_WB(31 downto 0); 
			when "10" => ALU_B_MEM_FW := DATA_MUL_OUT_MEM_WB(63 downto 32); 
			when others => ALU_B_MEM_FW := DATA_OUT_WB; 
		end case;
		
		case FW_EX_TO_EX_B is 
			when "00" => STORE_DATA_EX <= ALU_B_MEM_FW;
			when "01" => STORE_DATA_EX <= DATA_MUL_OUT_EX_MEM(31 downto 0); 
			when "10" => STORE_DATA_EX <= DATA_MUL_OUT_EX_MEM(63 downto 32); 
			when others => STORE_DATA_EX <= DATA_OUT_EX_MEM; 
		end case;
	end process;
	
	
	-- CW : ALU_FUNC(execute, 5 bit), ALU_EN(execute)
	alu_inst : ALU port map( clk => CLK, A => ALU_IN_1_EX, B => ALU_IN_2_EX,ALU_EN => ALU_EN, func => ALU_FUNC, SW => ALU_SW_EX, O_32 => ALU_OUT_32_EX, O_64 => ALU_OUT_64_EX);
	
	
	-- mux that selects the value to be stored in the ex/mem pipeline register
	mux_data_out_ex: process(LHI_INSTR,LHI_RESULT,RET_ID_EX,STACK_OUT_ID_EX,ALU_OUT_32_EX)
	begin
		if LHI_INSTR = '1' then
			DATA_OUT_EX <= LHI_RESULT;
		else
			if RET_ID_EX = '1' then
				DATA_OUT_EX <= STACK_OUT_ID_EX;
			else
				DATA_OUT_EX <= ALU_OUT_32_EX;
			end if;
		end if;
	end process;
	
	RD_2_MUL_MUX_IN <= std_logic_vector(unsigned(RD_ID_EX)+ to_unsigned(1,7));
	
	-- mux to select the signal in input to the pipes of rd mul registers		CW: MUL_INSTR(execute)
	RD_1_MUL_MUX_OUT <= RD_ID_EX when MUL_INSTR = '1' else "0000000";
	RD_2_MUL_MUX_OUT <= RD_2_MUL_MUX_IN when MUL_INSTR = '1' else "0000000";
	RD_EX <= RD_ID_EX when MUL_INSTR = '0' else "0000000";
	
	-- rd mul pipe 1
	mul_pipe1: process(CLK, RST) 
	begin
		if RST = '0' then 
			RD_1_MUL_PIPE_EX <= (others => (others => '0'));
		elsif CLK = '1' and CLK'event then
			for i in 1 to 6 loop
					RD_1_MUL_PIPE_EX(i) <= RD_1_MUL_PIPE_EX(i-1);
			end loop;
			RD_1_MUL_PIPE_EX(0) <= RD_1_MUL_MUX_OUT;
		end if;
	end process;
	
	-- rd mul pipe 2
	mul_pipe2: process(CLK, RST) 
	begin
		if RST = '0' then
			RD_2_MUL_PIPE_EX <= (others => (others => '0'));
		elsif CLK = '1' and CLK'event then
			for i in 1 to 6 loop
					RD_2_MUL_PIPE_EX(i) <= RD_2_MUL_PIPE_EX(i-1);
			end loop;
			RD_2_MUL_PIPE_EX(0) <= RD_2_MUL_MUX_OUT;
		end if;
	end process;
	--chain to delay the enable for the pipeline registers dedicated for the mul instruction
	mul_ctrl_sig_pipe_ex: process(CLK, RST)
	begin
		if RST = '0' then
			MUL_DELAY_EX <= (others => '0');
		elsif CLK = '1' and CLK'event then
			for i in 1 to 6 loop
					MUL_DELAY_EX(i) <= MUL_DELAY_EX(i-1);
			end loop;
			
			if MUL_INSTR = '1' then 
				MUL_DELAY_EX(0) <= EX_MEM_PIPE_EN;
			else
				MUL_DELAY_EX(0) <= '0';
			end if;
		end if;
	end process;
	
	fwu_inst: FWU port map(JAL_INSTR_EX => JAL_INSTR_ID_EX,RD_ID_EX => RD_ID_EX,RS_2_ID => RF_READ_ADDR_2_DEC,RS_1_ID_EX => RS_1_ID_EX, RS_2_ID_EX => RS_2_ID_EX, RD_1_MUL_EX_MEM => RD_1_MUL_EX_MEM, MEM_READ_WB => MEM_READ_MEM_WB,
				RD_2_MUL_EX_MEM => RD_2_MUL_EX_MEM, RD_EX_MEM => RD_EX_MEM, RS_2_EX_MEM => RS_2_EX_MEM, RD_MEM_WB => RD_MEM_WB, RD_1_MUL_MEM_WB => RD_1_MUL_MEM_WB, 
				RD_2_MUL_MEM_WB => RD_2_MUL_MEM_WB, RS_1_ID => RF_READ_ADDR_1_DEC, FW_EX_TO_EX_A => FW_EX_TO_EX_A, FW_EX_TO_EX_B => FW_EX_TO_EX_B, FW_MEM_TO_EX_A => FW_MEM_TO_EX_A,
				FW_MEM_TO_EX_B => FW_MEM_TO_EX_B, FW_MEM_TO_MEM => FW_MEM_TO_MEM, FW_EX_TO_ID => FW_EX_TO_ID, FW_MEM_TO_ID => FW_MEM_TO_ID,
				FW_EX_TO_ID_STACK => FW_EX_TO_ID_STACK, FW_MEM_TO_ID_STACK => FW_MEM_TO_ID_STACK, FW_ID_TO_ID => FW_ID_TO_ID, FW_WB_TO_ID_STACK => FW_WB_TO_ID_STACK);
	
	-- PIPELINE EXECUTE-MEMORY					CW: EX_MEM_PIPE_EN
	
	rd_ex_mem_inst: REG_GEN generic map(N => 7) port map(RST => RST, CLK => CLK, EN => EX_MEM_PIPE_EN, IN_DATA => RD_EX, OUT_DATA => RD_EX_MEM);
	rd_1_mul_ex_mem_inst: REG_GEN generic map(N => 7) port map(RST => RST, CLK => CLK, EN => MUL_DELAY_EX(6), IN_DATA => RD_1_MUL_PIPE_EX(6), OUT_DATA => RD_1_MUL_EX_MEM);
	rd_2_mul_ex_mem_inst: REG_GEN generic map(N => 7) port map(RST => RST, CLK => CLK, EN => MUL_DELAY_EX(6), IN_DATA => RD_2_MUL_PIPE_EX(6), OUT_DATA => RD_2_MUL_EX_MEM);
	data_out_ex_mem_inst: REG_GEN generic map(N => 32) port map(RST => RST, CLK => CLK, EN => EX_MEM_PIPE_EN, IN_DATA => DATA_OUT_EX, OUT_DATA => DATA_OUT_EX_MEM);
	data_mul_out_ex_mem_inst: REG_GEN generic map(N => 64) port map(RST => RST, CLK => CLK, EN => MUL_DELAY_EX(6), IN_DATA => ALU_OUT_64_EX, OUT_DATA => DATA_MUL_OUT_EX_MEM);
	store_data_ex_mem_inst: REG_GEN generic map(N => 32) port map(RST => RST, CLK => CLK, EN => EX_MEM_PIPE_EN, IN_DATA => STORE_DATA_EX, OUT_DATA => STORE_DATA_EX_MEM);
	rs_2_ex_mem_inst: REG_GEN generic map(N => 7) port map(RST => RST, CLK => CLK, EN => EX_MEM_PIPE_EN, IN_DATA => RS_2_ID_EX, OUT_DATA => RS_2_EX_MEM);
	pc4_reg_ex_mem: REG_GEN generic map(N => 32) port map(RST => RST, CLK => CLK, EN => EX_MEM_PIPE_EN, IN_DATA => PC_ADD4_ID_EX, OUT_DATA => PC_ADD4_EX_MEM);
	ret_reg_ex_mem : REG_BIT port map(CLK => CLK, RST => RST, EN => EX_MEM_PIPE_EN, IN_DATA => RET_ID_EX, OUT_DATA => RET_EX_MEM);
	jal_reg_ex_mem : REG_BIT port map(CLK => CLK, RST => RST, EN => EX_MEM_PIPE_EN, IN_DATA => JAL_INSTR_ID_EX, OUT_DATA => JAL_INSTR_EX_MEM);
	dram_addr_ex_mem: REG_GEN generic map(N => 32) port map(RST => RST, CLK => CLK, EN => EX_MEM_PIPE_EN, IN_DATA => ALU_OUT_32_EX, OUT_DATA => DRAM_ADDRESS_EX_MEM);
	
	-- MEMORY
	
	DRAM_ADDRESS <= DRAM_ADDRESS_EX_MEM;
	mux_dram_in : process(FW_MEM_TO_MEM, STORE_DATA_EX_MEM, DATA_MUL_OUT_MEM_WB, DATA_OUT_WB)
	begin
		case FW_MEM_TO_MEM is
			when "00" => DRAM_DATA_IN <= STORE_DATA_EX_MEM;
			when "01" => DRAM_DATA_IN <= DATA_MUL_OUT_MEM_WB(31 downto 0);
			when "10" => DRAM_DATA_IN <= DATA_MUL_OUT_MEM_WB(63 downto 32);
			when others => DRAM_DATA_IN <= DATA_OUT_WB;
		end case;
	end process;
	
	-- CW LHU_EN(memory), HW_BYTE_n(memory), SIGN_UNSIGN_n(memory)
	lhu_inst: LHU port map(MEM_OUT => DRAM_DATA_OUT, DIMENSION => DIMENSION, SIGN_UNSIGN_n => SIGN_UNSIGN_n, LHU_OUT => LOAD_DATA_MEM);
	
	--chain to delay the enable for the pipeline registers dedicated for the mul instruction
	mul_ctrl_sig_pipe_mem: process(CLK, RST) 
	begin
		if RST = '0' then
			MUL_DELAY_MEM <= (others => '0');
		elsif CLK = '1' and CLK'event then
			for i in 1 to 6 loop
					MUL_DELAY_MEM(i) <= MUL_DELAY_MEM(i-1);
			end loop;
			MUL_DELAY_MEM(0) <= MEM_WB_PIPE_EN;
		end if;
	end process;
	
	-- PIPELINE MEMORY-WRITEBACK			CW: MEM_WB_PIPE_EN
	
	rd_mem_wb_inst: REG_GEN generic map(N => 7) port map(RST => RST, CLK => CLK, EN => MEM_WB_PIPE_EN, IN_DATA => RD_EX_MEM, OUT_DATA => RD_MEM_WB);
	rd_1_mul_mem_wb_inst: REG_GEN generic map(N => 7) port map(RST => RST, CLK => CLK, EN => MUL_DELAY_MEM(6), IN_DATA => RD_1_MUL_EX_MEM, OUT_DATA => RD_1_MUL_MEM_WB);
	rd_2_mul_mem_wb_inst: REG_GEN generic map(N => 7) port map(RST => RST, CLK => CLK, EN => MUL_DELAY_MEM(6), IN_DATA => RD_2_MUL_EX_MEM, OUT_DATA => RD_2_MUL_MEM_WB);
	data_out_mem_wb_inst: REG_GEN generic map(N => 32) port map(RST => RST, CLK => CLK, EN => MEM_WB_PIPE_EN, IN_DATA => DATA_OUT_EX_MEM, OUT_DATA => DATA_OUT_MEM_WB);
	data_mul_out_mem_wb_inst: REG_GEN generic map(N => 64) port map(RST => RST, CLK => CLK, EN => MUL_DELAY_MEM(6), IN_DATA => DATA_MUL_OUT_EX_MEM, OUT_DATA => DATA_MUL_OUT_MEM_WB);
	data_load_mem_wb_inst: REG_GEN generic map(N => 32) port map(RST => RST, CLK => CLK, EN => MEM_WB_PIPE_EN, IN_DATA => LOAD_DATA_MEM, OUT_DATA => DATA_LOAD_MEM_WB);
	mem_read_inst : REG_BIT port map(CLK => CLK, RST => RST, EN => MEM_WB_PIPE_EN, IN_DATA => MEM_READ, OUT_DATA => MEM_READ_MEM_WB);
	pc4_reg_mem_wb: REG_GEN generic map(N => 32) port map(RST => RST, CLK => CLK, EN => MEM_WB_PIPE_EN, IN_DATA => PC_ADD4_EX_MEM, OUT_DATA => PC_ADD4_MEM_WB);
	ret_reg_mem_wb : REG_BIT port map(CLK => CLK, RST => RST, EN => MEM_WB_PIPE_EN, IN_DATA => RET_EX_MEM, OUT_DATA => RET_MEM_WB);
	
	-- WRITE BACK
	-- CW: MEM_ALU_n(WB)
	MEM_ALU_WB <= DATA_LOAD_MEM_WB when MEM_ALU_n = '1' else DATA_OUT_MEM_WB;
	DATA_OUT_WB <= PC_ADD4_MEM_WB when SEL_PC_WB = '1' else MEM_ALU_WB;
	-- CW : RF_WR_2_EN(WB)
	wr2_en_pipe: process(CLK)
	begin
		if RST = '0' then
			for i in 0 to 6 loop
				PIPE_RF_WRITE_2_EN(i) <= '0';
			end loop;
		elsif CLK = '1' and CLK'event then
			for i in 1 to 6 loop
				PIPE_RF_WRITE_2_EN(i) <= PIPE_RF_WRITE_2_EN(i-1);
			end loop;
			PIPE_RF_WRITE_2_EN(0) <= RF_WR_2_EN;
		end if;
	end process;
	
end architecture;