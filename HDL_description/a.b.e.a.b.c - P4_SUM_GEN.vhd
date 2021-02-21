library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity P4_SUM_GEN is
	generic(N : integer := 32;  --number of bit of the whole adder
		M : integer := 4);  --number of bit of the carry select block
	port(A,B : in std_logic_vector(N downto 0);
		Cin : in std_logic_vector(N/M-1 downto 0);
		SIGN_UNSIGN_n: std_logic;
		S : out std_logic_vector(N-1 downto 0);
		C : out std_logic;
		O : out std_logic);
end entity P4_SUM_GEN;

architecture structural of P4_SUM_GEN is

  component CSB_GEN is
    generic(N :integer := 4);
	port(A,B : in std_logic_vector(N-1 downto 0);
		Cin : in std_logic;
		S : out std_logic_vector(N-1 downto 0));
  end component CSB_GEN;

  component CSB_OVF_GEN is
		generic(N : integer :=4);
		port(A,B : in std_logic_vector(N downto 0);
			Cin : in std_logic;
			SIGN_UNSIGN_n: in std_logic;
			S : out std_logic_vector(N-1 downto 0);
			C: out std_logic;
			O: out std_logic);
  end component CSB_OVF_GEN; 
    
begin
  G1: for I in 1 to N/M generate
      G2: if( I = N/M ) generate -- instantiation of the CSB block with overflow for the MSBs 
           CSB_ovf: CSB_OVF_GEN generic map(N=>M) port map(A=>A(I*M downto (I-1)*M),B=>B(I*M downto (I-1)*M),Cin=>Cin(I-1),S=>S(I*M-1 downto (I-1)*M),O=>O,SIGN_UNSIGN_n=>SIGN_UNSIGN_n,C=>C);
      end generate;

      G3: if( I < N/M) generate -- instantiation of all the other CSB blocks
          CSB_i: CSB_GEN generic map(N=>M) port map(A=>A(I*M-1 downto (I-1)*M),B=>B(I*M-1 downto (I-1)*M),Cin=>Cin(I-1),S=>S(I*M-1 downto (I-1)*M));
      end generate;
  end generate;
  
end architecture structural;
