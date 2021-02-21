library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity CSB_OVF_GEN is
	generic(N : integer :=4);
	port(A,B : in std_logic_vector(N downto 0);
		Cin : in std_logic;
		SIGN_UNSIGN_n: in std_logic;
		S : out std_logic_vector(N-1 downto 0);
		C: out std_logic;
        O: out std_logic);
end entity CSB_OVF_GEN;

architecture structural of CSB_OVF_GEN is
	signal ext_A,ext_B: std_logic_vector(N downto 0);
	signal S_0,S_1 : std_logic_vector(N downto 0);
	signal S_out: std_logic_vector(N-1 downto 0);
begin
	
	-- sign_extension: process(A,B,SIGN_UNSIGN_n)
	-- begin
		-- if SIGN_UNSIGN_n = '1' then
			-- ext_A <= A(N-1) & A;
			-- ext_B <= B(N-1) & B;
		-- else
			-- ext_A <= '0' & A;
			-- ext_B <= '0' & B;
		-- end if;
	-- end process;
	
	csa: process(A,B)--csa: process(ext_A,ext_B)
	begin
		S_0 <= std_logic_vector(unsigned(A) + unsigned(B));
		S_1 <= std_logic_vector(unsigned(A) + unsigned(B) + to_unsigned(1,N+1));
	end process;
	
	mux: process (S_0, S_1,Cin)
	begin
		if Cin = '1' then
			S_out <= S_1(N-1 downto 0);
			C <= S_1(N);
		else
			S_out <= S_0(N-1 downto 0);
			C <= S_0(N);
		end if;
	end process;
	
	O <= (S_out(N-1) XOR A(N-1)) AND (A(N-1) XNOR B(N-1));
	S <= S_out;
  
end architecture structural;
