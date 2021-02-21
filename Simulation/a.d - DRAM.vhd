library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity DRAM is
port(
	CLK : in std_logic;
	ADDRESS : in std_logic_vector(31 downto 0);
	DATA_IN : in std_logic_vector(31 downto 0);
	RST : in std_logic;
	ENABLE : in std_logic;
	READ_WRITE_n : in std_logic;
	ALIGN_CHECK : in std_logic_vector(1 downto 0); -- 01 byte -- 10 half -- 11 word 
	
	DATA_OUT : out std_logic_vector(31 downto 0));
end entity;

architecture BEHAVIORAL of DRAM is
	
	type mem is array(1023 downto 0) of std_logic_vector(7 downto 0);
	signal DRAM_MEM : mem;
	
begin
	write_p: process(CLK, RST)
		variable clean_addr : std_logic_vector(31 downto 0);
		variable address_var : integer;
	begin
		if RST = '0' then
			for i in 0 to 1023 loop
				DRAM_MEM(i) <= std_logic_vector(to_unsigned(i mod 256,8));
			end loop;
		elsif CLK'event and CLK = '1' then
			if ENABLE = '1' then
				if READ_WRITE_n = '0' then
					if ALIGN_CHECK = "10" then 
					
						clean_addr := ADDRESS(31 downto 1) & '0';
						address_var := to_integer(unsigned(clean_addr));
						DRAM_MEM(address_var) <= DATA_IN(15 downto 8);
						DRAM_MEM(address_var+1) <= DATA_IN(7 downto 0);

					elsif ALIGN_CHECK = "11" then 
					
						clean_addr := ADDRESS(31 downto 2) & "00";
						address_var := to_integer(unsigned(clean_addr));
						DRAM_MEM(address_var) <= DATA_IN(31 downto 24);
						DRAM_MEM(address_var+1) <= DATA_IN(23 downto 16);
						DRAM_MEM(address_var+2) <= DATA_IN(15 downto 8);
						DRAM_MEM(address_var+3) <= DATA_IN(7 downto 0);
						
					elsif ALIGN_CHECK = "01" then
					
						clean_addr := ADDRESS;
						address_var := to_integer(unsigned(clean_addr));
						DRAM_MEM(address_var) <= DATA_IN(7 downto 0);
						
					end if;
				end if;
			end if;
		end if;
	end process;
	
	read_p: process(ADDRESS, READ_WRITE_n, ALIGN_CHECK,DRAM_MEM,ENABLE)
		variable clean_addr : std_logic_vector(31 downto 0);
		variable address_var : integer;
	begin
		if ENABLE = '1' and READ_WRITE_n = '1' then
			if ALIGN_CHECK = "10" then 
				clean_addr := ADDRESS(31 downto 1) & '0';
				address_var := to_integer(unsigned(clean_addr));
			elsif ALIGN_CHECK = "11" then 
				clean_addr := ADDRESS(31 downto 2) & "00";
				address_var := to_integer(unsigned(clean_addr));
			elsif ALIGN_CHECK = "01" then
				clean_addr := ADDRESS;
				address_var := to_integer(unsigned(clean_addr));
			else
				address_var := to_integer(unsigned(ADDRESS));
			end if;
			
			DATA_OUT <= DRAM_MEM(address_var) & DRAM_MEM(address_var+1) & DRAM_MEM(address_var+2) & DRAM_MEM(address_var+3);
		end if;
	end process;

end architecture;