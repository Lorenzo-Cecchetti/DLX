library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;
use work.functions.all;

entity WRF is 
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
end entity WRF;

architecture behavioral of WRF is
	constant reg_num: integer := 2*N*F+M; -- number of physical registers without the globals
	type reg_type is array (reg_num-1 downto 0) of std_logic_vector(N_bit-1 downto 0);
	
	signal phy_reg: reg_type; -- physical RF without globals
	
begin
	
	READ_1 <= phy_reg(to_integer(unsigned(READ_1_ADDR)));
	READ_2 <= phy_reg(to_integer(unsigned(READ_2_ADDR)));
	
	write_p: process(CLK,RST)
	begin
		-- R0 hardwired to 0
		if RST = '0' then
			phy_reg <= (others => (others => '0'));
		elsif CLK'event and CLK = '1' then
			phy_reg(0) <= (others => '0');
			if WRITE_1_EN = '1' and WRITE_1_ADDR /= std_logic_vector(to_unsigned(0,7)) then 
				phy_reg(to_integer(unsigned(WRITE_1_ADDR))) <= WRITE_1;
			end if;
			if WRITE_2_EN = '1' and WRITE_2_ADDR /= std_logic_vector(to_unsigned(0,7)) then 
				phy_reg(to_integer(unsigned(WRITE_2_ADDR))) <= WRITE_2(63 downto 32);
				phy_reg(to_integer(unsigned(WRITE_2_ADDR))+1) <= WRITE_2(31 downto 0);
			end if;
		end if;
	end process;

end architecture behavioral;