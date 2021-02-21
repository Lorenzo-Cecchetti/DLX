library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity CSB_GEN is
	generic(N :integer := 4);
	port(A,B : in std_logic_vector(N-1 downto 0);
       Cin : in std_logic;
       S : out std_logic_vector(N-1 downto 0));
end entity CSB_GEN;

architecture structural of CSB_GEN is
	signal S_0,S_1 : std_logic_vector(N-1 downto 0);
	
begin
  
  --instantiation of the two RCA
  -- RCA_0 has Cin at 0 while RCA_1 has Cin at 1

	csa: process(A,B)
	begin
		S_0 <= std_logic_vector(unsigned(A) + unsigned(B));
		S_1 <= std_logic_vector(unsigned(A) + unsigned(B) + to_unsigned(1,N));
	end process;
	
	mux: process(S_0,S_1,Cin)
	begin
		if Cin = '1'  then
			S <= S_1;
		else
			S <= S_0;
		end if;
	end process;

end architecture structural;
