library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ALU is
	port(A,B: in std_logic_vector(31 downto 0);
		clk: in std_logic;
		ALU_EN : in std_logic;
		func: in std_logic_vector(4 downto 0);
		SW: out std_logic_vector(1 downto 0); -- STATUS WORD SW(0) => C; SW(1) => O;
		O_32: out std_logic_vector(31 downto 0);
		O_64: out std_logic_vector(63 downto 0));
end entity ALU;

architecture structural of ALU is 

	component P4_ADDER_GEN is
		generic(N : integer := 32;  --number of bit of the whole adder
			M : integer := 4);  --number of bit of the carry select block
		port(A,B : in std_logic_vector(N-1 downto 0);
			sub_add_n: in std_logic;
			SIGN_UNSIGN_n: in std_logic;
			S : out std_logic_vector(N-1 downto 0);
			C : out std_logic;
			O : out std_logic);
	end component;
	
	component COMPARATOR is
		port(
			A,B: in std_logic_vector(31 downto 0);
			SIGN_UNSIGN_n: in std_logic;
			AGB,BGA,AEB,AGEB,BGEA,ANEB: out std_logic);
	end component COMPARATOR;
	
	component LOGICAL is 
		port( A, B : in std_logic_vector(31 downto 0);
			  S0, S1, S2, S3 : in std_logic;
			  Z : out std_logic_vector(31 downto 0));
	end component;
	
	component BOOTHMUL is
	   port (A,B: in std_logic_vector(31 downto 0);
			 P: out std_logic_vector(63 downto 0);
			 CLK : in std_logic);
	end component;
	
	component SHIFTER is 
		port(	A, B : in std_logic_vector(31 downto 0);
				MODE : in std_logic_vector(1 downto 0);
				Z : out std_logic_vector(31 downto 0));
	end component;
	
	signal AGB_s,BGA_s,AEB_s,AGEB_s,BGEA_s,ANEB_s : std_logic;
	signal A_add,B_add,A_comp,B_comp,A_log,B_log,A_mul,B_mul,A_sh,B_sh: std_logic_vector(31 downto 0);
	signal O_add,O_log,O_sh: std_logic_vector(31 downto 0);
	signal sub_add_n,sign_unsign_n_add,sign_unsign_n_comp: std_logic;
	signal mode: std_logic_vector(1 downto 0);
	signal sel: std_logic_vector(3 downto 0);
begin

	
	in_mux: process(ALU_EN, func, A, B)
	begin
		sub_add_n <= '0';
		sign_unsign_n_add <= '0';
		sign_unsign_n_comp <= '0';
		A_add <= (others => '0');
		B_add <= (others => '0');
		A_comp <= (others => '0');
		B_comp <= (others => '0');
		A_log <= (others => '0');
		B_log <= (others => '0');
		A_mul <= (others => '0');
		B_mul <= (others => '0');
		A_sh <= (others => '0');
		B_sh <= (others => '0');
		mode <= (others => '0');
		sel <= (others => '0');
		
		if ALU_EN = '1' then
			case func is
				when "00000" => -- ADD SIGNED
					A_add <= A;
					B_add <= B;
					sub_add_n <= '0';
					sign_unsign_n_add <= '1';
				when "00001" => -- SUB SIGNED
					A_add <= A;
					B_add <= B;
					sub_add_n <= '1';
					sign_unsign_n_add <= '1';
				when "00010" => -- ADD UNSIGNED
					A_add <= A;
					B_add <= B;
					sub_add_n <= '0';
					sign_unsign_n_add <= '0';
				when "00011" => -- SUB UNSIGNED
					A_add <= A;
					B_add <= B;
					sub_add_n <= '1';
					sign_unsign_n_add <= '0';
				when "00100" => -- SGT
					A_comp <= A;
					B_comp <= B;
					sign_unsign_n_comp <= '1';
				when "00101" => -- SGTU
					A_comp <= A;
					B_comp <= B;	
					sign_unsign_n_comp <= '0';
				when "00110" => -- SLT
					A_comp <= A;
					B_comp <= B;
					sign_unsign_n_comp <= '1';
				when "00111" => -- SLTU
					A_comp <= A;
					B_comp <= B;
					sign_unsign_n_comp <= '0';
				when "01000" => -- SEQ
					A_comp <= A;
					B_comp <= B;
					sign_unsign_n_comp <= '1';
				when "01010" => -- SGE
					A_comp <= A;
					B_comp <= B;
					sign_unsign_n_comp <= '1';
				when "01011" => -- SGEU
					A_comp <= A;
					B_comp <= B;
					sign_unsign_n_comp <= '0';
				when "01100" => -- SLE
					A_comp <= A;
					B_comp <= B;
					sign_unsign_n_comp <= '1';
				when "01101" => -- SLEU
					A_comp <= A;
					B_comp <= B;
					sign_unsign_n_comp <= '0';
				when "01110" => -- SNE
					A_comp <= A;
					B_comp <= B;
					sign_unsign_n_comp <= '1';
				when "10000" => -- SRA
					A_sh <= A;
					B_sh <= B;
					mode <= "01";
				when "10001" => -- LSL
					A_sh <= A;
					B_sh <= B;
					mode <= "10";
				when "10010" => -- LSR
					A_sh <= A;
					B_sh <= B;
					mode <= "00";
				when "10011" => -- MUL
					A_mul <= A;
					B_mul <= B;
				when "10100" => -- AND
					A_log <= A;
					B_log <= B;
					sel <= "0001";
				when "10101" => -- NAND
					A_log <= A;
					B_log <= B;
					sel <= "1110";
				when "10110" => -- OR
					A_log <= A;
					B_log <= B;
					sel <= "0111";
				when "10111" => -- NOR
					A_log <= A;
					B_log <= B;
					sel <= "1000";
				when "11000" => -- XOR
					A_log <= A;
					B_log <= B;
					sel <= "0110";
				when "11001" => -- XNOR
					A_log <= A;
					B_log <= B;
					sel <= "1001";
				when others =>
					null;
			end case;
		end if;
	end process;
	
	out_mux: process(O_add,O_log,O_sh,func, AGB_s, BGA_s, AEB_s, AGEB_S, BGEA_s, ANEB_s)
	begin
		case to_integer(unsigned(func)) is 
			when 0 to 3 =>
				O_32 <= O_add;
			when 4 to 5 =>
				O_32(31 downto 1) <= (others => '0');
				O_32(0) <= AGB_s;
			when 6 to 7 =>
				O_32(31 downto 1) <= (others => '0');
				O_32(0) <= BGA_s;
			when 8 =>
				O_32(31 downto 1) <= (others => '0');
				O_32(0) <= AEB_s;
			when 10 to 11 =>
				O_32(31 downto 1) <= (others => '0');
				O_32(0) <= AGEB_s;
			when 12 to 13 =>
				O_32(31 downto 1) <= (others => '0');
				O_32(0) <= BGEA_s;
			when 14 =>
				O_32(31 downto 1) <= (others => '0');
				O_32(0) <= ANEB_s;
			when 16 to 18 =>
				O_32 <= O_sh;
			when 20 to 25 =>
				O_32 <= O_log;
			when others =>
				O_32 <= (others => '0');
		end case;
	end process;
	
	sub_add: P4_ADDER_GEN generic map(N => 32, M => 4) port map(A => A_add, B => B_add, sub_add_n => sub_add_n, SIGN_UNSIGN_n => sign_unsign_n_add, S => O_add, C => SW(0), O => SW(1));
	comp: COMPARATOR port map(A => A_comp, B => B_comp, SIGN_UNSIGN_n => sign_unsign_n_comp, AGB => AGB_s,BGA => BGA_s,AEB => AEB_s,AGEB => AGEB_S,BGEA => BGEA_s,ANEB => ANEB_s);
	logic: LOGICAL port map(A => A_log, B => B_log, S0 => sel(3), S1 => sel(2), S2 => sel(1), S3 => sel(0), Z => O_log);
	mul: BOOTHMUL port map(A => A_mul, B => B_mul, CLK => clk, P => O_64);
	shift: SHIFTER port map(A => A_sh, B => B_sh, MODE => mode, Z => O_sh);
	
end architecture;