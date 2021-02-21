library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity REG_BIT is
	port(RST,EN,CLK: in std_logic;
	IN_DATA: in std_logic;
	OUT_DATA: out std_logic);
end entity;

architecture BEHAVIORAL of REG_BIT is
begin
	reg: process (CLK, RST)
    begin  
      if RST = '0' then -- asynchronous reset (active low)
        OUT_DATA <= '0';
      elsif CLK'event and CLK = '1' then  
        if (EN = '1') then
          OUT_DATA <= IN_DATA;
        end if;
      end if;
    end process;
end architecture;
