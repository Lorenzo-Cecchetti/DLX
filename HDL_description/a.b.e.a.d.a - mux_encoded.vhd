library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity MUX_ENCODED is
	port(in_0,in_1,in_2,in_3,in_4: in std_logic_vector(63 downto 0);
		 sel: in std_logic_vector(2 downto 0);
		 output: out std_logic_vector(63 downto 0);
		 sel_out: out std_logic);
end entity;

architecture BEHAVIORAL of MUX_ENCODED is

begin
		--the component mixes the behaviour of the mux with the one of the encoder,
		--therefore the output is selected according to the Booth's encoding
		output <= in_0 when sel = "000" else
			   in_1 when sel = "001" else
			   in_1 when sel = "010" else
			   in_2 when sel = "011" else
			   in_3 when sel = "100" else
			   in_4 when sel = "101" else
			   in_4 when sel = "110" else
			   in_0;
		
		--signal that gives an ouput when a negative branch has to be selected
		--it is used to add 1 and complete the CA2
		sel_out <= '1' when sel = "100" else
				   '1' when sel = "101" else
				   '1' when sel = "110" else
				   '0';

end architecture BEHAVIORAL;
