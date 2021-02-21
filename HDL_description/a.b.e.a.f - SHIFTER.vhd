library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- 100000
entity SHIFTER is 
	port(	A, B : in std_logic_vector(31 downto 0);
			MODE : in std_logic_vector(1 downto 0);
			Z : out std_logic_vector(31 downto 0));
end entity;

architecture BEHAVIORAL of SHIFTER is 
	
	type mask_set is array (3 downto 0) of std_logic_vector(39 downto 0);
	signal mask_LL, mask_RL, mask_RA : mask_set;
	signal idx, shift : integer;
	signal output : std_logic_vector(31 downto 0);
begin
	mask_gen : process(A)
	begin
	-- generation of the masks for the logical left shift
		G1: for i in 0 to 3 loop
			mask_LL(i)(7 downto 0) <= (others => '0');
			mask_RL(i)(39 downto 32) <= (others => '0');
			mask_RA(i)(39 downto 32) <= (others => A(31));
			if (i > 0) then
				mask_LL(i)(7+i*8 downto 8) <= (others => '0');
				mask_RL(i)(31 downto 32-i*8) <= (others => '0');
				mask_RA(i)(31 downto 32-i*8) <= (others => A(31));
			end if;
			mask_LL(i)(39 downto 8+i*8) <= A(31-i*8 downto 0);
			mask_RL(i)(31-i*8 downto 0) <= A(31 downto i*8);
			mask_RA(i)(31-i*8 downto 0) <= A(31 downto i*8);
		end loop;
	end process;
	
	idx <= to_integer(unsigned(B(5 downto 3)));
	shift <= to_integer(unsigned(B(2 downto 0)));
	
	behav: process(MODE, mask_LL, mask_RA, mask_RL, idx, shift)
	begin
		if (idx = 4) then 
			output <= (others => '0');
		else
			if MODE = "00" then -- logical shift right
				case shift is 
				when 0 => output <= mask_RL(idx)(31 downto 0);
				when 1 => output <= mask_RL(idx)(32 downto 1);
				when 2 => output <= mask_RL(idx)(33 downto 2);
				when 3 => output <= mask_RL(idx)(34 downto 3);
				when 4 => output <= mask_RL(idx)(35 downto 4);
				when 5 => output <= mask_RL(idx)(36 downto 5);
				when 6 => output <= mask_RL(idx)(37 downto 6);
				when 7 => output <= mask_RL(idx)(38 downto 7);
				when others => output <= (others => '0');
				end case;
			elsif MODE = "01" then -- arithmetic shift right 
				case shift is 
				when 0 => output <= mask_RA(idx)(31 downto 0);
				when 1 => output <= mask_RA(idx)(32 downto 1);
				when 2 => output <= mask_RA(idx)(33 downto 2);
				when 3 => output <= mask_RA(idx)(34 downto 3);
				when 4 => output <= mask_RA(idx)(35 downto 4);
				when 5 => output <= mask_RA(idx)(36 downto 5);
				when 6 => output <= mask_RA(idx)(37 downto 6);
				when 7 => output <= mask_RA(idx)(38 downto 7);
				when others => output <= (others => '0');
				end case;
				
			elsif MODE = "10" then --logical shift left
				case shift is 
				when 0 => output <= mask_LL(idx)(39 downto 8);
				when 1 => output <= mask_LL(idx)(38 downto 7);
				when 2 => output <= mask_LL(idx)(37 downto 6);
				when 3 => output <= mask_LL(idx)(36 downto 5);
				when 4 => output <= mask_LL(idx)(35 downto 4);
				when 5 => output <= mask_LL(idx)(34 downto 3);
				when 6 => output <= mask_LL(idx)(33 downto 2);
				when 7 => output <= mask_LL(idx)(32 downto 1);
				when others => output <= (others => '0');
				end case;
			else 
				output <= (others => '0');
			end if;
		end if;
	end process;
	
	Z <= output;

end BEHAVIORAL;