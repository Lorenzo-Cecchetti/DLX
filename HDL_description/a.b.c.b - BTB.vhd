library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity BTB is
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
end entity;

architecture BEHAVIORAL of BTB is 
	type addr is array(255 downto 0) of std_logic_vector(31 downto 0);
	signal address : addr;
	signal jump_addr : addr;
	signal full_empty_n : std_logic_vector(255 downto 0);
begin
	read_p : process(RESET, WRITE_DELETE, PC_CHECK, PC_WRITE, TARGET, BR_INSTR,full_empty_n, address)  --CHECK_WRITE_n, PC_TARGET, ENABLE
	variable entry_idx : integer;
	begin
		entry_idx := to_integer(unsigned(PC_CHECK(9 downto 2)));
		if full_empty_n(entry_idx) = '1' and address(entry_idx) = PC_CHECK then --check if the branch is in the BTB 
			NEW_PC <= jump_addr(entry_idx);
			FOUND <= '1';
		else
			NEW_PC <= (others => '0');
			FOUND <= '0';
		end if;
	end process;
	
	write_p: process(CLK,RESET) 
		variable write_entry_idx : integer;
	begin
		if RESET = '0' then 
			full_empty_n <= (others => '0');
		elsif CLK'event and CLK = '1' then 
			if BR_INSTR = '1' and STALL = '0' then 
				write_entry_idx := to_integer(unsigned(PC_WRITE(9 downto 2)));
				if WRITE_DELETE = "10" then --write a new entry
					address(write_entry_idx) <= PC_WRITE;
					jump_addr(write_entry_idx) <= TARGET;
					full_empty_n(write_entry_idx) <= '1';
				elsif WRITE_DELETE = "01" then --delete a entry
					full_empty_n(write_entry_idx) <= '0';
				end if;
			end if;
		end if;
	end process;
	
	
	
	
	
	
	
	

end BEHAVIORAL;
