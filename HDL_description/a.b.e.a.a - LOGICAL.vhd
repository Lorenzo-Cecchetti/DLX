library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity LOGICAL is 
	port( A, B : in std_logic_vector(31 downto 0);
		  S0, S1, S2, S3 : in std_logic;
		  Z : out std_logic_vector(31 downto 0));
end entity;

architecture BEHAVIORAL of LOGICAL is
signal A_neg, B_neg : std_logic_vector(31 downto 0);
signal L0, L1, L2, L3 : std_logic_vector(31 downto 0);

component NAND3 is 
	port(A, B, C : in std_logic;
		 Z : out std_logic);
end component;

component NAND4 is 
	port(A, B, C, D : in std_logic;
		 Z : out std_logic);
end component;

begin

A_neg <= not(A);
B_neg <= not(B);

G1: for i in 0 to 31 generate
	N0 : NAND3 port map(A => S0, B => A_neg(i), C => B_neg(i), Z => L0(i));
	N1 : NAND3 port map(A => S1, B => A_neg(i), C => B(i), Z => L1(i));
	N2 : NAND3 port map(A => S2, B => A(i), C => B_neg(i), Z => L2(i));
	N3 : NAND3 port map(A => S3, B => A(i), C => B(i), Z => L3(i));
	
	N4 : NAND4 port map(A => L0(i), B => L1(i), C => L2(i), D => L3(i), Z => Z(i));
end generate;

end architecture;