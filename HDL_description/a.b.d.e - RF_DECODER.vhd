library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;
use work.functions.all;

entity RF_DECODER is 
generic(M: integer := 5; --# of global registers
			N: integer := 5; --# of register in each block (IN, OUT, LOCAL)
			F: integer := 3; --# of windows
			N_bit: integer := 32); 
port(CLK : in std_logic;
	RST : in std_logic;
	RET : in std_logic;
	CALL : in std_logic;
	READ_1_ADDR : in std_logic_vector(4 downto 0);
	READ_2_ADDR : in std_logic_vector(4 downto 0);
	RD_ADDR : in std_logic_vector(4 downto 0);
	STALL_J_REG : in std_logic;
	READ_1_ADDR_OUT : out std_logic_vector(6 downto 0);
	READ_2_ADDR_OUT : out std_logic_vector(6 downto 0);
	RD_ADDR_OUT : out std_logic_vector(6 downto 0);
	FILL_SPILL_IMM : out std_logic_vector(31 downto 0);
	FILL : buffer std_logic;
	SPILL : buffer std_logic;
	TC : buffer std_logic); -- terminal count of the counter
end entity;

architecture BEHAVIORAL of RF_DECODER is 
	constant reg_num: integer := 2*N*F; -- number of physical registers without the globals
	constant tot_reg : integer := reg_num + M;
	constant pntr_dim: integer :=  log2(reg_num)+1; -- dimension of SWP and CWP
	constant spill_fill_cnt: integer := log2(2*N)+1; -- dimension of the counter used to index the fill and spill process
	
	signal CWP,SWP: std_logic_vector(pntr_dim-1 downto 0); -- the SWP points at the end of the window spilled
	signal CANRESTORE,CANSAVE: std_logic; -- signal used to detect when to spill and fill
	signal CUR_CNT: std_logic_vector(spill_fill_cnt-1 downto 0); -- counter used to index the fill and spill process 
	signal Nx2: std_logic_vector(pntr_dim-1 downto 0); -- signal with the value 2*N
begin
	
	Nx2 <= std_logic_vector(to_unsigned(2*N,pntr_dim));
	
	update: process(CLK, RST,STALL_J_REG) -- process that updates the values of CWP and SWP at each CALL and RET
		variable cwp_add,swp_add: integer; -- contains the updated value of CWP and SWP at the end of the CALL/RET 
	begin
		if RST = '0' then 	-- reset behavior
			CWP <= (others => '0');
			SWP <= (others => '0');
			CANSAVE <= '1';
			CANRESTORE <= '1';
		elsif CLK'event and CLK = '1' and STALL_J_REG = '0' then
			if CALL = '1' and RET = '0' then   -- CALL behavior
				swp_add := to_integer(unsigned(SWP));
				cwp_add := to_integer(unsigned(CWP));
				
				CANRESTORE <= '1';   -- each time we have a CALL, CANRESTORE goes to 1
				
				if CANSAVE = '1' then
					if (new_address(cwp_add +2*N,reg_num)) = 2*N*(F-2) and CANSAVE = '1' then -- update of CANSAVE
						-- update of CANRESTORE to indicate that at the next CALL a SPILL must be performed
						CANSAVE <= '0';
						--swp_add := swp_add + 2*N;
					end if;
					cwp_add := cwp_add + 2*N;
				elsif CANSAVE = '0' and TC = '1' then --update CWP and SWP at the end of the SPILL
					cwp_add := cwp_add + 2*N;
					swp_add := swp_add + 2*N;
				end if;
				-- if the new value of CWP and SWP are out of the range of the physical RF, we restart indexing from the beginning
				if cwp_add > reg_num then 
					cwp_add := 2*N*(F-1);
				end if;
				if swp_add > reg_num then
					swp_add := 2*N*(F-1);
				end if;
				
				CWP <= std_logic_vector(to_unsigned(new_address(cwp_add,reg_num),pntr_dim));
				SWP <= std_logic_vector(to_unsigned(new_address(swp_add,reg_num),pntr_dim));
				
			elsif RET = '1' and CALL = '0' then   -- RETURN behavior
				cwp_add := to_integer(unsigned(CWP));
				swp_add := to_integer(unsigned(SWP));
				CANSAVE <= '1';  -- each time we have a RET, CANSAVE goes to 1
				if cwp_add = new_address(swp_add + 2*N,reg_num) then 
					-- update of CANRESTORE to indicate that at the next RET a FILL must be performed
					CANRESTORE <= '0';
					cwp_add := cwp_add - 2*N;
				elsif CANRESTORE = '1' then -- case of a RET without a FILL
					cwp_add := cwp_add - 2*N;
				elsif CANRESTORE = '0' and TC = '1' then  --update of CWP and SWP at the end of the FILL
					cwp_add := cwp_add - 2*N;
					swp_add := swp_add - 2*N;
				end if;
				-- if the new value of CWP and SWP are out of the range of the physical RF, we restart indexing from the beginning
				if cwp_add < 0 then
					cwp_add := 2*N*(F-1);
				end if;
				if swp_add < 0 then
					swp_add := 2*N*(F-1);
				end if;
				
				CWP <= std_logic_vector(to_unsigned(cwp_add,pntr_dim));
				SWP <= std_logic_vector(to_unsigned(swp_add,pntr_dim));
				
			end if;	
		end if;	
	end process;
	
	counter: process(CLK) -- process that manages the counter used to index the registers in the fill/spill operations
	begin
		if CLK'event and CLK = '1' then
			if RST = '0' or TC = '1' then 
				CUR_CNT <= (others => '0');
			elsif (CALL = '1' and CANSAVE = '0') or (RET = '1' and CANRESTORE = '0') then
				CUR_CNT <= CUR_CNT + '1';
			end if;
		end if;
	end process;
	TC <= '1' when CUR_CNT = std_logic_vector(to_unsigned(2*N,spill_fill_cnt)) else '0';
	
	
	
	fill_spill : process(CANSAVE,CALL,TC,CANRESTORE,RET) -- process that manages the FILL and SPILL output signal
	begin
		if CANSAVE = '0' and CALL = '1' and TC = '0' then
			SPILL <= '1';
			FILL <= '0';
		elsif CANRESTORE = '0' and RET = '1' and TC = '0' then
			SPILL <= '0';
			FILL <= '1';
		else
			SPILL <= '0';
			FILL <= '0';
		end if;
	end process;
	
	read1 : process(READ_1_ADDR, CANSAVE, CALL, TC, CWP)
		variable glob_en : std_logic;
		variable read_address: integer; -- contains the address given as input in the read port of the entity
		variable address: integer; -- address used to access the global registers
	begin			
		read_address := to_integer(unsigned(READ_1_ADDR));
		if read_address > 3*N then -- check when we have to access to global registers
			address := reg_num + read_address - 3*N;
			glob_en := '1';
		elsif read_address = 0 then 
			address := 0; 
			glob_en := '1';
		else
			address := read_address;
			glob_en := '0';
		end if;
	
		if CANSAVE = '1' then --and CALL = '0' and RET = '0' then -- read without spill
			if glob_en = '1' then --read in global registers
				READ_1_ADDR_OUT <= std_logic_vector(to_unsigned(address,7));
			else	--read in physical registers starting from CWP
				READ_1_ADDR_OUT <= std_logic_vector(to_unsigned(new_address(to_integer(unsigned(CWP))+read_address,reg_num),7));
			end if;
		else 
			if CALL = '1' and TC = '0' then --SPILL
				READ_1_ADDR_OUT <= std_logic_vector(to_unsigned(0,7));
			elsif SPILL = '0' then
				if glob_en = '1' then 	--read in global registers
					READ_1_ADDR_OUT <= std_logic_vector(to_unsigned(address,7));
				else	--read in physical registers starting from CWP
					READ_1_ADDR_OUT <= std_logic_vector(to_unsigned(new_address(to_integer(unsigned(CWP))+read_address,reg_num),7));
				end if;
			else
				READ_1_ADDR_OUT <= (others => '0');
			end if;
		end if;
	end process;
	
	read2 : process(READ_2_ADDR,CWP,CANSAVE,CALL,TC,SPILL,CUR_CNT)
	variable glob_en: std_logic;
	variable read_address: integer;
	variable address: integer;
	begin				
		read_address := to_integer(unsigned(READ_2_ADDR));
		if read_address > 3*N then -- check when we have to access to global registers
			address := reg_num + read_address - 3*N;
			glob_en := '1';
		elsif read_address = 0 then 
			address := 0; 
			glob_en := '1';
		else
			address := read_address;
			glob_en := '0';
		end if;
		if CANSAVE = '0' then
			if CALL = '1' and TC = '0' then --SPILL
				READ_2_ADDR_OUT <= std_logic_vector(to_unsigned(new_address(to_integer(unsigned(CWP+CUR_CNT))+4*N+1,reg_num),7));
			elsif SPILL = '0' then
				if glob_en = '1' then 	--read in global registers
					READ_2_ADDR_OUT <= std_logic_vector(to_unsigned(address,7));
				else	--read in physical registers starting from CWP
					READ_2_ADDR_OUT <= std_logic_vector(to_unsigned(new_address(to_integer(unsigned(CWP))+read_address,reg_num),7));
				end if;
			else
				READ_2_ADDR_OUT <= (others => '0');
			end if;
		else 
			if glob_en = '1' then 	--read in global registers
				READ_2_ADDR_OUT <= std_logic_vector(to_unsigned(address,7)); 
			else	--read in physical registers starting from CWP
				READ_2_ADDR_OUT <= std_logic_vector(to_unsigned(new_address(to_integer(unsigned(CWP))+read_address,reg_num),7));
			end if;
		end if;
	end process;
	
	write_p : process(RD_ADDR,CANRESTORE,CALL,RET,CWP,TC,SWP,CUR_CNT)
	variable glob_en: std_logic;
	variable write_address: integer;
	variable address: integer;
	begin
		-- R0 hardwired to 0
		write_address := to_integer(unsigned(RD_ADDR));
		if write_address > 3*N then   -- check when we have to access to global registers
			glob_en := '1';
			address := reg_num + write_address - 3*N;
		elsif write_address = 0 then 
			address := 0;
			glob_en := '1';
		else 
			address := write_address;
			glob_en := '0';
		end if;
	
		if CANRESTORE = '1' then --and CALL = '0' and RET = '0'
		
			if glob_en = '1' then --write in global registers
				RD_ADDR_OUT <= std_logic_vector(to_unsigned(address,7));  
			else	--write in physical registers starting from CWP
				RD_ADDR_OUT <= std_logic_vector(to_unsigned(new_address(to_integer(unsigned(CWP))+write_address,reg_num),7));
			end if;
			
		else
			if RET = '1' and TC = '0' then --FILL
				RD_ADDR_OUT <= std_logic_vector(to_unsigned(new_address(to_integer(unsigned(SWP+CUR_CNT))-2*N+1,reg_num),7));
			else
				if glob_en = '1' then --write in global registers
					RD_ADDR_OUT <= std_logic_vector(to_unsigned(address,7));  
				else	--write in physical registers starting from CWP
					RD_ADDR_OUT <= std_logic_vector(to_unsigned(new_address(to_integer(unsigned(CWP))+write_address,reg_num),7));
				end if;
			end if;
			
		end if;
	end process;
	
	imm_proc : process(CANSAVE,CALL,RET,CANRESTORE,TC,CWP,CUR_CNT)
	begin
		if CANSAVE = '0' and CALL = '1' and TC = '0' then --SPILL
			FILL_SPILL_IMM <= std_logic_vector(to_unsigned(new_address(to_integer(unsigned(CWP+CUR_CNT))+4*N,reg_num),30)) & "00";
		elsif CANRESTORE = '0' and RET = '1' and TC = '0' then --FILL
			FILL_SPILL_IMM <= std_logic_vector(to_unsigned(new_address(to_integer(unsigned(SWP+CUR_CNT))-2*N,reg_num),30)) & "00";
		else 
			FILL_SPILL_IMM <= (others => '0');
		end if;
	end process;
	
	
end architecture;