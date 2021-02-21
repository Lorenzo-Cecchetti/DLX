library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

package functions is
  
  function log2 (n:integer) return integer;
  function liv (i,j,n:integer) return integer;
  function prev_exp(i,n:integer) return integer;
  function new_address(addr,max:integer) return integer; 
  

end package;

package body functions is

  function log2 (n: integer) return integer is --function to calculate the log2 of the number of bits
  begin										   --it is used to set the number of levels in the architecture

    if n <= 2 then
      return 1;
    else
      return 1 + log2(n/2);
    end if;
  end log2;

  function liv (i,j,n:integer) return integer is --function to retreive the actual level according to the values
    variable k: integer := 0;					 --of i and j
    variable max_liv: integer := log2(n);
  begin

    k := i-j;

    for x in 1 to max_liv loop

      if (k < 2**x) then
        return x;
      end if;
    end loop;

  end liv;

  function prev_exp(i,n: integer) return integer is --function used to calculate the closest power of 2 to the actual i
    variable max_liv: integer := log2(n);           --value. It is used while creating the generate blocks.
  begin

    for x in max_liv downto 1 loop

      if(i > 2**x) then
        return 2**x;
      end if;
      
    end loop;

  end prev_exp;
  
  function new_address(addr,max:integer) return integer is
	begin
		if addr >= max then
			return addr - max;
		end if;
		return addr;
  end new_address;
  
end functions;
