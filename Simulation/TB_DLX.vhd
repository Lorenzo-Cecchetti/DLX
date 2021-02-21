library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.my_package.all;
use work.functions.all;

entity TB is
end entity;

architecture BEHAVIORAL of TB is
	component DLX is
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
	end component;
	
	component DRAM is
	port(
		CLK : in std_logic;
		ADDRESS : in std_logic_vector(31 downto 0);
		DATA_IN : in std_logic_vector(31 downto 0);
		RST : in std_logic;
		ENABLE : in std_logic;
		READ_WRITE_n : in std_logic;
		ALIGN_CHECK : in std_logic_vector(1 downto 0); -- 01 byte -- 10 half -- 11 word 
		DATA_OUT : out std_logic_vector(31 downto 0));
	end component;
	
	component IRAM is 
	port(
		RST : in std_logic;
		ADDRESS_READ : in std_logic_vector(31 downto 0);
		DATA_OUT : out std_logic_vector(31 downto 0));
	end component;
	
	constant IR_SIZE_tb : integer := 32;
	constant PC_SIZE_tb : integer := 32;
	constant DATA_SIZE_tb : integer := 32;
	constant OPCODE_SIZE_tb : integer := 6;
	constant FUNC_SIZE_tb : integer := 11;
	constant REG_ADDR_SIZE_tb : integer := 5;
	constant DEPTH_tb : integer := 1024;
	
	signal CLK_tb :  std_logic:= '0';
	signal RST_tb :  std_logic;
	signal IRAM_ADDRESS_tb :  std_logic_vector(31 downto 0);
	signal IRAM_DATA_tb :  std_logic_vector(31 downto 0);
	signal DRAM_ADDRESS_tb :  std_logic_vector(31 downto 0);
	signal DRAM_DATA_IN_tb :  std_logic_vector(31 downto 0);
	signal DRAM_DATA_OUT_tb :  std_logic_vector(31 downto 0);
	signal DRAM_ENABLE_tb : std_logic;
	signal DRAM_READ_WRITE_n_tb : std_logic;
	signal ALIGN_CHECK_tb :  std_logic_vector(1 downto 0); 
	
begin
	
	dlx_inst: DLX port map(
							CLK => CLK_tb,
							RST => RST_tb,
							IRAM_ADDRESS => IRAM_ADDRESS_tb,
							IRAM_DATA => IRAM_DATA_tb,
							DRAM_ADDRESS => DRAM_ADDRESS_tb,
							DRAM_ENABLE => DRAM_ENABLE_tb,
							DRAM_READ_WRITE_n => DRAM_READ_WRITE_n_tb,
							DRAM_DATA_IN => DRAM_DATA_IN_tb,
							DRAM_DATA_OUT => DRAM_DATA_OUT_tb,
							ALIGN_CHECK => ALIGN_CHECK_tb);
							
	iram_inst : IRAM port map(
								RST => RST_tb,
								ADDRESS_READ => IRAM_ADDRESS_tb,
								DATA_OUT => IRAM_DATA_tb);
	
	dram_inst : DRAM port map(
								CLK => CLK_tb,
								RST => RST_tb,
								ADDRESS => DRAM_ADDRESS_tb, 
								DATA_IN => DRAM_DATA_IN_tb,
								ENABLE => DRAM_ENABLE_tb,
								READ_WRITE_n => DRAM_READ_WRITE_n_tb,
								ALIGN_CHECK => ALIGN_CHECK_tb,
								DATA_OUT => DRAM_DATA_OUT_tb);
	PCLOCK : process(CLK_tb)
	begin
		CLK_tb <= not(CLK_tb) after 0.5 ns;	
	end process;
	
	test: process
	begin
		RST_tb <= '0';
		wait for 1.5 ns;
		RST_tb <= '1';
		wait for 500 ns;
	end process;
										
end architecture;
