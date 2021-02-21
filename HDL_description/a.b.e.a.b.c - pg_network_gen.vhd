library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity PG_NETWORK_GEN is
  generic(N : integer := 32);
  port(A,B : in std_logic_vector(N-1 downto 0);
       Cin : in std_logic;
       g,p : out std_logic_vector(N-1 downto 0));
end entity PG_NETWORK_GEN;

architecture behavioral of PG_NETWORK_GEN is
begin

  g(N-1 downto 1) <= A(N-1 downto 1) and B(N-1 downto 1);
  p <= A xor B;
  g(0) <= (A(0) and B(0)) or ((A(0) xor B(0)) and Cin);
  
end architecture behavioral;
