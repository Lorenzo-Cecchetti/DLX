library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity REG_GEN is 
	generic (N: integer := 32);
	port(RST,EN,CLK: in std_logic;
		IN_DATA: in std_logic_vector(N-1 downto 0);
		OUT_DATA: out std_logic_vector(N-1 downto 0));
end entity;

architecture behavioral of REG_GEN is
begin
	reg: process (CLK, RST)
    begin  -- process IR_P
      if RST = '0' then                 -- asynchronous reset (active low)
        OUT_DATA <= (others => '0');
      elsif CLK'event and CLK = '1' then  -- rising clock edge
        if (EN = '1') then
          OUT_DATA <= IN_DATA;
        end if;
      end if;
    end process;
end architecture;