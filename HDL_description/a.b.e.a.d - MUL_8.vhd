library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity BOOTHMUL is
   port (A,B: in std_logic_vector(31 downto 0);
         P: out std_logic_vector(63 downto 0);
		 CLK : in std_logic);
         
end entity;

architecture mixed of BOOTHMUL is

	component ADDER is
		port(A,B : in std_logic_vector(63 downto 0);
			 Cin : in std_logic;
			 S : out std_logic_vector(63 downto 0));
	end component;
	
	component MUX_ENCODED is
		port(in_0,in_1,in_2,in_3,in_4: in std_logic_vector(63 downto 0);
			 sel: in std_logic_vector(2 downto 0);
			 output: out std_logic_vector(63 downto 0);
			 sel_out: out std_logic);
	end component;
	
	--constant M : integer := 4;
	
	type N_sig is array(2 downto 0) of std_logic_vector(63 downto 0);
    
	signal sel_matrix: std_logic_vector(16 downto 0);
	
	signal reg_p12, reg_p23, reg_p34, reg_p45, reg_p56, reg_p67, reg_p78 : std_logic_vector(63 downto 0);
	signal reg_A2, reg_A31, reg_A32, reg_A41, reg_A42, reg_A43, reg_A51, reg_A52, reg_A53, reg_A54, reg_A61, reg_A62, reg_A63, reg_A64, reg_A65, reg_A71, reg_A72, reg_A73, reg_A74, reg_A75, reg_A76, reg_A81, reg_A82, reg_A83, reg_A84, reg_A85, reg_A86, reg_A87 : std_logic_vector(31 downto 0);
	signal reg_B2, reg_B31, reg_B32, reg_B41, reg_B42, reg_B43, reg_B51, reg_B52, reg_B53, reg_B54, reg_B61, reg_B62, reg_B63, reg_B64, reg_B65, reg_B71, reg_B72, reg_B73, reg_B74, reg_B75, reg_B76, reg_B81, reg_B82, reg_B83, reg_B84, reg_B85, reg_B86, reg_B87 : std_logic_vector(31 downto 0);
	
	signal zero: std_logic_vector(63 downto 0);
	signal b1_ext, b2_ext, b3_ext, b4_ext, b5_ext, b6_ext, b7_ext, b8_ext : std_logic_vector(32 downto 0);
	signal s1_A, s1_2A, s1_Am, s1_2Am, s1_muxout, s1_p : N_sig;
	signal s2_A, s2_2A, s2_Am, s2_2Am, s2_muxout, s2_p : N_sig;
	signal s3_A, s3_2A, s3_Am, s3_2Am, s3_muxout, s3_p : N_sig;
	signal s4_A, s4_2A, s4_Am, s4_2Am, s4_muxout, s4_p : N_sig;
	signal s5_A, s5_2A, s5_Am, s5_2Am, s5_muxout, s5_p : N_sig;
	signal s6_A, s6_2A, s6_Am, s6_2Am, s6_muxout, s6_p : N_sig;
	signal s7_A, s7_2A, s7_Am, s7_2Am, s7_muxout, s7_p : N_sig;
	signal s8_A, s8_2A, s8_Am, s8_2Am, s8_muxout, s8_p : N_sig;
	signal s1_sel, s2_sel, s3_sel, s4_sel, s5_sel, s6_sel, s7_sel, s8_sel : std_logic_vector(2 downto 0);
	
begin

	zero <= (others => '0');
	-- cycle that generates the stages of the pipeline
	G1: for i in 0 to 7 generate
		-- 1° stage
		G2 : if ( i = 0) generate
			-- initialization of A matrix for the current stage
			s1_A(0)(31 downto 0) <= A;
			s1_A(0)(63 downto 32) <= (others => A(31));
			-- initialization of 2*A matrix for the current stage
			s1_2A(0)(63 downto 1) <= s1_A(0)(62 downto 0);
			s1_2A(0)(0) <= '0';
			-- initialization of -A matrix for the current stage 
			s1_Am(0) <= (not s1_A(0));
			-- initialization of -2*A matrix for the current stage
			s1_2Am(0) <= (not s1_2A(0));
			--initialization of b_ext
			b1_ext(0) <= '0';
			b1_ext(32 downto 1) <= B;
			
			G6: for j in 0 to 1 generate 
				G7 : if j = 0 generate 
					M1 : MUX_ENCODED port map ( in_0 => zero,
												in_1 => s1_A(0),
												in_2 => s1_2A(0),
												in_3 => s1_2Am(0),
												in_4 => s1_Am(0),
												sel => b1_ext(2 downto 0),
												output => s1_muxout(0),
												sel_out => s1_sel(0));
					ADD1 : ADDER port map (A => s1_muxout(0), B => zero, Cin => s1_sel(0), S => s1_p(0));
				end generate;
				G8 : if (j > 0) generate 
					M2 : MUX_ENCODED port map ( in_0 => zero,
												in_1 => s1_A(j),
												in_2 => s1_2A(j),
												in_3 => s1_2Am(j),
												in_4 => s1_Am(j),
												sel => b1_ext((i*2+j)*2+2 downto (i*2+j)*2),
												output => s1_muxout(j),
												sel_out => s1_sel(j));
					ADD2 : ADDER port map (A => s1_muxout(j), B => s1_p(j-1), Cin => s1_sel(j), S => s1_p(j));
				end generate;
				
				s1_A(j+1)(63 downto 2) <= s1_A(j)(61 downto 0);
				s1_A(j+1)(1 downto 0) <= "00";
				s1_2A(j+1)(63 downto 2) <= s1_2A(j)(61 downto 0);
				s1_2A(j+1)(1 downto 0) <= "00";
				s1_Am(j+1) <= not(s1_A(j+1));
				s1_2Am(j+1) <= not(s1_2A(j+1));
			end generate;	
		end generate;
		-- 2° stage
		G3 : if (i = 1) generate
			s2_A(0)(31 downto 0) <= reg_A2;
			s2_A(0)(63 downto 32) <= (others => reg_A2(31));
			-- initialization of 2*A matrix for the current stage
			s2_2A(0)(63 downto 1) <= s2_A(0)(62 downto 0);
			s2_2A(0)(0) <= '0';
			-- initialization of -A matrix for the current stage 
			s2_Am(0) <= (not s2_A(0));
			-- initialization of -2*A matrix for the current stage
			s2_2Am(0) <= (not s2_2A(0));
			--initialization of b_ext
			b2_ext(0) <= '0';
			b2_ext(32 downto 1) <= reg_B2;
			
			G9: for j in 0 to 1 generate 
				G10 : if j = 0 generate 
					M3 : MUX_ENCODED port map ( in_0 => zero,
												in_1 => s2_A(0),
												in_2 => s2_2A(0),
												in_3 => s2_2Am(0),
												in_4 => s2_Am(0),
												sel => b2_ext((i*2+j)*2+2 downto (i*2+j)*2),
												output => s2_muxout(0),
												sel_out => s2_sel(0));
					ADD3 : ADDER port map (A => s2_muxout(0), B => reg_p12, Cin => s2_sel(0), S => s2_p(0));
				end generate;
				G11 : if (j > 0) generate 
					M4 : MUX_ENCODED port map ( in_0 => zero,
												in_1 => s2_A(j),
												in_2 => s2_2A(j),
												in_3 => s2_2Am(j),
												in_4 => s2_Am(j),
												sel => b2_ext((i*2+j)*2+2 downto (i*2+j)*2),
												output => s2_muxout(j),
												sel_out => s2_sel(j));
					ADD4 : ADDER port map (A => s2_muxout(j), B => s2_p(j-1), Cin => s2_sel(j), S => s2_p(j));
				end generate;
				
				s2_A(j+1)(63 downto 2) <= s2_A(j)(61 downto 0);
				s2_A(j+1)(1 downto 0) <= "00";
				s2_2A(j+1)(63 downto 2) <= s2_2A(j)(61 downto 0);
				s2_2A(j+1)(1 downto 0) <= "00";
				s2_Am(j+1) <= not(s2_A(j+1));
				s2_2Am(j+1) <= not(s2_2A(j+1));
			end generate;	
		end generate;
		-- 3° stage
		G4 : if (i = 2) generate
			s3_A(0)(31 downto 0) <= reg_A32;
			s3_A(0)(63 downto 32) <= (others => reg_A32(31));
			-- initialization of 2*A matrix for the current stage
			s3_2A(0)(63 downto 1) <= s3_A(0)(62 downto 0);
			s3_2A(0)(0) <= '0';
			-- initialization of -A matrix for the current stage 
			s3_Am(0) <= (not s3_A(0));
			-- initialization of -2*A matrix for the current stage
			s3_2Am(0) <= (not s3_2A(0));
			--initialization of b_ext
			b3_ext(0) <= '0';
			b3_ext(32 downto 1) <= reg_B32;
			
			G12: for j in 0 to 1 generate 
				G13 : if j = 0 generate 
					M5 : MUX_ENCODED port map ( in_0 => zero,
												in_1 => s3_A(0),
												in_2 => s3_2A(0),
												in_3 => s3_2Am(0),
												in_4 => s3_Am(0),
												sel => b3_ext((i*2+j)*2+2 downto (i*2+j)*2),
												output => s3_muxout(0),
												sel_out => s3_sel(0));
					ADD5 : ADDER port map (A => s3_muxout(0), B => reg_p23, Cin => s3_sel(0), S => s3_p(0));
				end generate;
				G8 : if (j > 0) generate 
					M6 : MUX_ENCODED port map ( in_0 => zero,
												in_1 => s3_A(j),
												in_2 => s3_2A(j),
												in_3 => s3_2Am(j),
												in_4 => s3_Am(j),
												sel => b3_ext((i*2+j)*2+2 downto (i*2+j)*2),
												output => s3_muxout(j),
												sel_out => s3_sel(j));
					ADD6 : ADDER port map (A => s3_muxout(j), B => s3_p(j-1), Cin => s3_sel(j), S => s3_p(j));
				end generate;
				
				s3_A(j+1)(63 downto 2) <= s3_A(j)(61 downto 0);
				s3_A(j+1)(1 downto 0) <= "00";
				s3_2A(j+1)(63 downto 2) <= s3_2A(j)(61 downto 0);
				s3_2A(j+1)(1 downto 0) <= "00";
				s3_Am(j+1) <= not(s3_A(j+1));
				s3_2Am(j+1) <= not(s3_2A(j+1));
			end generate;	
		end generate;
		-- 4° stage
		G5: if (i = 3) generate
			s4_A(0)(31 downto 0) <= reg_A43;
			s4_A(0)(63 downto 32) <= (others => reg_A43(31));
			-- initialization of 2*A matrix for the current stage
			s4_2A(0)(63 downto 1) <= s4_A(0)(62 downto 0);
			s4_2A(0)(0) <= '0';
			-- initialization of -A matrix for the current stage 
			s4_Am(0) <= (not s4_A(0));
			-- initialization of -2*A matrix for the current stage
			s4_2Am(0) <= (not s4_2A(0));
			--initialization of b_ext
			b4_ext(0) <= '0';
			b4_ext(32 downto 1) <= reg_B43;
			
			G14: for j in 0 to 1 generate 
				G15 : if j = 0 generate 
					M7 : MUX_ENCODED port map ( in_0 => zero,
												in_1 => s4_A(0),
												in_2 => s4_2A(0),
												in_3 => s4_2Am(0),
												in_4 => s4_Am(0),
												sel => b4_ext((i*2+j)*2+2 downto (i*2+j)*2),
												output => s4_muxout(0),
												sel_out => s4_sel(0));
					ADD7 : ADDER port map (A => s4_muxout(0), B => reg_p34, Cin => s4_sel(0), S => s4_p(0));
				end generate;
				G16 : if (j > 0) generate 
					M8 : MUX_ENCODED port map ( in_0 => zero,
												in_1 => s4_A(j),
												in_2 => s4_2A(j),
												in_3 => s4_2Am(j),
												in_4 => s4_Am(j),
												sel => b4_ext((i*2+j)*2+2 downto (i*2+j)*2),
												output => s4_muxout(j),
												sel_out => s4_sel(j));
					ADD8 : ADDER port map (A => s4_muxout(j), B => s4_p(j-1), Cin => s4_sel(j), S => s4_p(j));
				end generate;
				
				s4_A(j+1)(63 downto 2) <= s4_A(j)(61 downto 0);
				s4_A(j+1)(1 downto 0) <= "00";
				s4_2A(j+1)(63 downto 2) <= s4_2A(j)(61 downto 0);
				s4_2A(j+1)(1 downto 0) <= "00";
				s4_Am(j+1) <= not(s4_A(j+1));
				s4_2Am(j+1) <= not(s4_2A(j+1));
			end generate;	
		end generate;
		-- 5° stage
		G17: if (i = 4) generate
			s5_A(0)(31 downto 0) <= reg_A54;
			s5_A(0)(63 downto 32) <= (others => reg_A54(31));
			-- initialization of 2*A matrix for the current stage
			s5_2A(0)(63 downto 1) <= s5_A(0)(62 downto 0);
			s5_2A(0)(0) <= '0';
			-- initialization of -A matrix for the current stage 
			s5_Am(0) <= (not s5_A(0));
			-- initialization of -2*A matrix for the current stage
			s5_2Am(0) <= (not s5_2A(0));
			--initialization of b_ext
			b5_ext(0) <= '0';
			b5_ext(32 downto 1) <= reg_B54;
			
			G18: for j in 0 to 1 generate 
				G19 : if j = 0 generate 
					M9 : MUX_ENCODED port map ( in_0 => zero,
												in_1 => s5_A(0),
												in_2 => s5_2A(0),
												in_3 => s5_2Am(0),
												in_4 => s5_Am(0),
												sel => b5_ext((i*2+j)*2+2 downto (i*2+j)*2),
												output => s5_muxout(0),
												sel_out => s5_sel(0));
					ADD9 : ADDER port map (A => s5_muxout(0), B => reg_p45, Cin => s5_sel(0), S => s5_p(0));
				end generate;
				G20 : if (j > 0) generate 
					M10 : MUX_ENCODED port map ( in_0 => zero,
												in_1 => s5_A(j),
												in_2 => s5_2A(j),
												in_3 => s5_2Am(j),
												in_4 => s5_Am(j),
												sel => b5_ext((i*2+j)*2+2 downto (i*2+j)*2),
												output => s5_muxout(j),
												sel_out => s5_sel(j));
					ADD10 : ADDER port map (A => s5_muxout(j), B => s5_p(j-1), Cin => s5_sel(j), S => s5_p(j));
				end generate;
				
				s5_A(j+1)(63 downto 2) <= s5_A(j)(61 downto 0);
				s5_A(j+1)(1 downto 0) <= "00";
				s5_2A(j+1)(63 downto 2) <= s5_2A(j)(61 downto 0);
				s5_2A(j+1)(1 downto 0) <= "00";
				s5_Am(j+1) <= not(s5_A(j+1));
				s5_2Am(j+1) <= not(s5_2A(j+1));
			end generate;	
		end generate;
		-- 6° stage
		G21: if (i = 5) generate
			s6_A(0)(31 downto 0) <= reg_A65;
			s6_A(0)(63 downto 32) <= (others => reg_A65(31));
			-- initialization of 2*A matrix for the current stage
			s6_2A(0)(63 downto 1) <= s6_A(0)(62 downto 0);
			s6_2A(0)(0) <= '0';
			-- initialization of -A matrix for the current stage 
			s6_Am(0) <= (not s6_A(0));
			-- initialization of -2*A matrix for the current stage
			s6_2Am(0) <= (not s6_2A(0));
			--initialization of b_ext
			b6_ext(0) <= '0';
			b6_ext(32 downto 1) <= reg_B65;
			
			G22: for j in 0 to 1 generate 
				G23 : if j = 0 generate 
					M11 : MUX_ENCODED port map ( in_0 => zero,
												in_1 => s6_A(0),
												in_2 => s6_2A(0),
												in_3 => s6_2Am(0),
												in_4 => s6_Am(0),
												sel => b6_ext((i*2+j)*2+2 downto (i*2+j)*2),
												output => s6_muxout(0),
												sel_out => s6_sel(0));
					ADD11 : ADDER port map (A => s6_muxout(0), B => reg_p56, Cin => s6_sel(0), S => s6_p(0));
				end generate;
				G24 : if (j > 0) generate 
					M12 : MUX_ENCODED port map ( in_0 => zero,
												in_1 => s6_A(j),
												in_2 => s6_2A(j),
												in_3 => s6_2Am(j),
												in_4 => s6_Am(j),
												sel => b6_ext((i*2+j)*2+2 downto (i*2+j)*2),
												output => s6_muxout(j),
												sel_out => s6_sel(j));
					ADD12 : ADDER port map (A => s6_muxout(j), B => s6_p(j-1), Cin => s6_sel(j), S => s6_p(j));
				end generate;
				
				s6_A(j+1)(63 downto 2) <= s6_A(j)(61 downto 0);
				s6_A(j+1)(1 downto 0) <= "00";
				s6_2A(j+1)(63 downto 2) <= s6_2A(j)(61 downto 0);
				s6_2A(j+1)(1 downto 0) <= "00";
				s6_Am(j+1) <= not(s6_A(j+1));
				s6_2Am(j+1) <= not(s6_2A(j+1));
			end generate;	
		end generate;
		-- 7° stage
		G25: if (i = 6) generate
			s7_A(0)(31 downto 0) <= reg_A76;
			s7_A(0)(63 downto 32) <= (others => reg_A76(31));
			-- initialization of 2*A matrix for the current stage
			s7_2A(0)(63 downto 1) <= s7_A(0)(62 downto 0);
			s7_2A(0)(0) <= '0';
			-- initialization of -A matrix for the current stage 
			s7_Am(0) <= (not s7_A(0));
			-- initialization of -2*A matrix for the current stage
			s7_2Am(0) <= (not s7_2A(0));
			--initialization of b_ext
			b7_ext(0) <= '0';
			b7_ext(32 downto 1) <= reg_B76;
			
			G26: for j in 0 to 1 generate 
				G27 : if j = 0 generate 
					M13 : MUX_ENCODED port map ( in_0 => zero,
												in_1 => s7_A(0),
												in_2 => s7_2A(0),
												in_3 => s7_2Am(0),
												in_4 => s7_Am(0),
												sel => b7_ext((i*2+j)*2+2 downto (i*2+j)*2),
												output => s7_muxout(0),
												sel_out => s7_sel(0));
					ADD13 : ADDER port map (A => s7_muxout(0), B => reg_p67, Cin => s7_sel(0), S => s7_p(0));
				end generate;
				G28 : if (j > 0) generate 
					M14 : MUX_ENCODED port map ( in_0 => zero,
												in_1 => s7_A(j),
												in_2 => s7_2A(j),
												in_3 => s7_2Am(j),
												in_4 => s7_Am(j),
												sel => b7_ext((i*2+j)*2+2 downto (i*2+j)*2),
												output => s7_muxout(j),
												sel_out => s7_sel(j));
					ADD14 : ADDER port map (A => s7_muxout(j), B => s7_p(j-1), Cin => s7_sel(j), S => s7_p(j));
				end generate;
				
				s7_A(j+1)(63 downto 2) <= s7_A(j)(61 downto 0);
				s7_A(j+1)(1 downto 0) <= "00";
				s7_2A(j+1)(63 downto 2) <= s7_2A(j)(61 downto 0);
				s7_2A(j+1)(1 downto 0) <= "00";
				s7_Am(j+1) <= not(s7_A(j+1));
				s7_2Am(j+1) <= not(s7_2A(j+1));
			end generate;	
		end generate;
		-- 8° stage
		G29: if (i = 7) generate
			s8_A(0)(31 downto 0) <= reg_A87;
			s8_A(0)(63 downto 32) <= (others => reg_A87(31));
			-- initialization of 2*A matrix for the current stage
			s8_2A(0)(63 downto 1) <= s8_A(0)(62 downto 0);
			s8_2A(0)(0) <= '0';
			-- initialization of -A matrix for the current stage 
			s8_Am(0) <= (not s8_A(0));
			-- initialization of -2*A matrix for the current stage
			s8_2Am(0) <= (not s8_2A(0));
			--initialization of b_ext
			b8_ext(0) <= '0';
			b8_ext(32 downto 1) <= reg_B87;
			
			G30: for j in 0 to 1 generate 
				G31 : if j = 0 generate 
					M15 : MUX_ENCODED port map ( in_0 => zero,
												in_1 => s8_A(0),
												in_2 => s8_2A(0),
												in_3 => s8_2Am(0),
												in_4 => s8_Am(0),
												sel => b8_ext((i*2+j)*2+2 downto (i*2+j)*2),
												output => s8_muxout(0),
												sel_out => s8_sel(0));
					ADD15 : ADDER port map (A => s8_muxout(0), B => reg_p78, Cin => s8_sel(0), S => s8_p(0));
				end generate;
				G32 : if (j > 0) generate 
					M16 : MUX_ENCODED port map ( in_0 => zero,
												in_1 => s8_A(j),
												in_2 => s8_2A(j),
												in_3 => s8_2Am(j),
												in_4 => s8_Am(j),
												sel => b8_ext((i*2+j)*2+2 downto (i*2+j)*2),
												output => s8_muxout(j),
												sel_out => s8_sel(j));
					ADD16 : ADDER port map (A => s8_muxout(j), B => s8_p(j-1), Cin => s8_sel(j), S => s8_p(j));
				end generate;
				
				s8_A(j+1)(63 downto 2) <= s8_A(j)(61 downto 0);
				s8_A(j+1)(1 downto 0) <= "00";
				s8_2A(j+1)(63 downto 2) <= s8_2A(j)(61 downto 0);
				s8_2A(j+1)(1 downto 0) <= "00";
				s8_Am(j+1) <= not(s8_A(j+1));
				s8_2Am(j+1) <= not(s8_2A(j+1));
			end generate;	
		end generate;
	end generate;
	
	P <= s8_p(1);
	
	reg_manage: process(CLK)
	begin
		if CLK = '1' and CLK'event then 
			reg_p12 <= s1_p(1);
			reg_p23 <= s2_p(1);
			reg_p34 <= s3_p(1);
			reg_p45 <= s4_p(1);
			reg_p56 <= s5_p(1);
			reg_p67 <= s6_p(1);
			reg_p78 <= s7_p(1);
			reg_A2 <= A(27 downto 0) & std_logic_vector(to_unsigned(0,4));
			reg_A31 <= A(23 downto 0) & std_logic_vector(to_unsigned(0,8));
			reg_A32 <= reg_A31;
			reg_A41 <= A(19 downto 0) & std_logic_vector(to_unsigned(0,12));
			reg_A42 <= reg_A41;
			reg_A43 <= reg_A42;
			reg_A51 <= A(15 downto 0) & std_logic_vector(to_unsigned(0,16));
			reg_A52 <= reg_A51;
			reg_A53 <= reg_A52;
			reg_A54 <= reg_A53;
			reg_A61 <= A(11 downto 0) & std_logic_vector(to_unsigned(0,20));
			reg_A62 <= reg_A61;
			reg_A63 <= reg_A62;
			reg_A64 <= reg_A63;
			reg_A65 <= reg_A64;
			reg_A71 <= A(7 downto 0) & std_logic_vector(to_unsigned(0,24));
			reg_A72 <= reg_A71;
			reg_A73 <= reg_A72;
			reg_A74 <= reg_A73;
			reg_A75 <= reg_A74;
			reg_A76 <= reg_A75;
			reg_A81 <= A(3 downto 0) & std_logic_vector(to_unsigned(0,28));
			reg_A82 <= reg_A81;
			reg_A83 <= reg_A82;
			reg_A84 <= reg_A83;
			reg_A85 <= reg_A84;
			reg_A86 <= reg_A85;
			reg_A87 <= reg_A86;
			reg_B2 <= B;
			reg_B31 <= B;
			reg_B32 <= reg_B31;
			reg_B41 <= B;
			reg_B42 <= reg_B41;
			reg_B43 <= reg_B42;
			reg_B51 <= B;
			reg_B52 <= reg_B51;
			reg_B53 <= reg_B52;
			reg_B54 <= reg_B53;
			reg_B61 <= B;
			reg_B62 <= reg_B61;
			reg_B63 <= reg_B62;
			reg_B64 <= reg_B63;
			reg_B65 <= reg_B64;
			reg_B71 <= B;
			reg_B72 <= reg_B71;
			reg_B73 <= reg_B72;
			reg_B74 <= reg_B73;
			reg_B75 <= reg_B74;
			reg_B76 <= reg_B75;
			reg_B81 <= B;
			reg_B82 <= reg_B81;
			reg_B83 <= reg_B82;
			reg_B84 <= reg_B83;
			reg_B85 <= reg_B84;
			reg_B86 <= reg_B85;
			reg_B87 <= reg_B86;
		end if;
	end process;
	
end architecture;
