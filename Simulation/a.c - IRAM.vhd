library ieee;
use ieee.std_logic_1164.all;
use std.textio.all;
use ieee.std_logic_textio.all;
use ieee.numeric_std.all;

entity IRAM is 
port(
	RST : in std_logic;
	ADDRESS_READ : in std_logic_vector(31 downto 0);
	DATA_OUT : out std_logic_vector(31 downto 0));
end entity;

architecture BEHAVIORAL of IRAM is

	type mem is array(1023 downto 0) of std_logic_vector(7 downto 0);
	signal IRAM_MEM : mem;
	
begin

	behav: process(RST, ADDRESS_READ)
		file mem_fp: text;
		variable file_line : line;
		variable index : integer := 0;
		variable tmp_data_u : std_logic_vector(31 downto 0);
		variable clean_addr : std_logic_vector(31 downto 0);
		variable address : integer;
	begin
		clean_addr := ADDRESS_READ(31 downto 2) & "00";
		address := to_integer(unsigned(clean_addr));
		
		if RST = '0' then 
			file_open(mem_fp,"factorial_func.asm.mem",READ_MODE);
			while (not endfile(mem_fp)) loop
				readline(mem_fp,file_line);
				hread(file_line,tmp_data_u);
				IRAM_MEM(index+3)   <=  tmp_data_u(7 downto 0);
				IRAM_MEM(index+2) <=  tmp_data_u(15 downto 8);
				IRAM_MEM(index+1) <=  tmp_data_u(23 downto 16);
				IRAM_MEM(index) <=  tmp_data_u(31 downto 24); 
				index := index + 4;
			end loop;
			
			for i in index to 1023 loop
				IRAM_MEM(i) <= (others =>'0');
			end loop;
		else
			DATA_OUT <= IRAM_MEM(address) & IRAM_MEM(address+1) & IRAM_MEM(address+2) & IRAM_MEM(address+3);
		end if;
	end process;

end architecture;