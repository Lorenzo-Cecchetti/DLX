library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.my_package.all;

entity STACK is 
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
end entity;

architecture BEHAVIORAL of STACK is
	signal stack_mem : stack_t;
	signal address : integer; 
	signal stop_call, stop_ret : std_logic; --inserted to avoid incrementing the counter during the stalls caused by the fill/spill
begin
	write_p: process(RST,CLK,STALL_J_REG)
	begin
		if RST = '0' then
			stack_mem <= (others =>(others => '0'));
		elsif CLK = '1' and CLK'event and STALL_J_REG = '0' then
			if CALL = '1' and stop_call = '0' and SPILL = '0' then -- enable the stack only when there is no spill active (when it is active, do the operation soon after)
				stack_mem(address) <= DATA_IN;
				PREV_CALL <= '1';
			elsif RET = '1' and stop_ret = '0' and FILL = '0' then
				PREV_CALL <= '0';
			end if;
		end if;
	end process;
	
	read_p: process(RET,stop_ret,FILL,stack_mem,address)
	begin
		if RET = '1' and stop_ret = '0' and FILL = '0' then
			DATA_OUT <= stack_mem(address);
		else
			DATA_OUT <= (others => '0');
		end if;
	end process;
	
	offset: process(CLK,RST,STALL_J_REG) 
	begin
		if RST = '0' then
			address <= 0;
			stop_call <= '0';
			stop_ret <= '0';
		elsif CLK'event and CLK = '1' and STALL_J_REG = '0' then 
			if CALL = '1' and stop_call = '0' and SPILL = '0' then
				address <= address +1;
				stop_call <= '1';
				stop_ret <= '0';
			elsif RET = '1' and stop_ret = '0' and FILL = '0' then 
				address <= address -1;
				stop_call <= '0';
				stop_ret <= '1';
			elsif CALL = '0' and RET = '0' then 
				stop_call <= '0';
				stop_ret <= '0';
			end if;
		end if;
	end process;
end architecture;