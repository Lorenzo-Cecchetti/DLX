library ieee;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.functions.all;


entity P4_ADDER_GEN is
	generic(N : integer := 32;  --number of bit of the whole adder
		M : integer := 4);  --number of bit of the carry select block
	port(A,B : in std_logic_vector(N-1 downto 0);
		sub_add_n: in std_logic;
		SIGN_UNSIGN_n: in std_logic;
		S : out std_logic_vector(N-1 downto 0);
		C : out std_logic;
		O : out std_logic);
end entity;

architecture structural of P4_ADDER_GEN is

  component P4_SUM_GEN is
    generic(N : integer := 32;  --number of bit of the whole adder
		M : integer := 4);  --number of bit of the carry select block
	port(A,B : in std_logic_vector(N downto 0);
		Cin : in std_logic_vector(N/M-1 downto 0);
		SIGN_UNSIGN_n: std_logic;
		S : out std_logic_vector(N-1 downto 0);
		C : out std_logic;
		O : out std_logic);
  end component;

  component P4_CARRY_GEN is
    generic(N: integer := 32;
            M: integer := 4);
    port(A,B : in std_logic_vector(N-1 downto 0);
         Cin : in std_logic;
         C : out std_logic_vector(N/M-1 downto 0));
  end component;

  signal C_CG,C_SG: std_logic_vector(N/M-1 downto 0);
  signal sub_b: std_logic_vector(N-1 downto 0);
  signal ext_a,ext_b,ext_sub_b: std_logic_vector(N downto 0);
begin

	ext_A <= '0' & A when SIGN_UNSIGN_n = '0' else
				A(N-1) & A;
	ext_B <= '0' & B when SIGN_UNSIGN_n = '0' else
				B(N-1) & B;
	ext_sub_b <= NOT ext_B when sub_add_n = '1' else
			ext_B;
	sub_b <= NOT B when sub_add_n = '1' else
			B;
  --instantiation of the carry generator and the sum generator. The output of the first is connected to the signal C
  --that is than left shifted to insert as a LSB the Cin of the whole adder. The bit that is shifted out is connected to
  --the Cout of the structure
  
  carry_gen: P4_CARRY_GEN generic map(N=>N,M=>M) port map(A=>A,B=>sub_b,Cin=>sub_add_n,C=>C_CG);
  sum_gen: P4_SUM_GEN generic map(N=>N,M=>M) port map(A=>ext_A,B=>ext_sub_b,Cin=>C_SG,S=>S,O=>O,SIGN_UNSIGN_n=>SIGN_UNSIGN_n,C=>C); --
  
  C_SG(N/M-1 downto 1) <= C_CG(N/M-2 downto 0);
  C_SG(0) <= sub_add_n;
  
  --C <= C_CG(N/M-1);

end architecture structural;
