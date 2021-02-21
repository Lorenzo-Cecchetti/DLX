library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.functions.all;

entity P4_CARRY_GEN is
  generic(N: integer := 32; --The whole architecture is generic when N and M are power of 2 and
          M: integer := 4); --M is a divisor of N
  port(A,B : in std_logic_vector(N-1 downto 0);
       Cin : in std_logic;
       C : out std_logic_vector(N/M-1 downto 0));
end entity P4_CARRY_GEN;

architecture structural of P4_CARRY_GEN is

  component PG_BLOCK is
    port(Gik,Pik,Gkj,Pkj : in std_logic;
         Gij,Pij : out std_logic);
  end component PG_BLOCK;

  component G_BLOCK is
    port(Gik,Pik,Gkj : in std_logic;
         Gij : out std_logic);
  end component G_BLOCK;

  component PG_NETWORK_GEN is
    generic(N : integer := 32);
    port(A,B : in std_logic_vector(N-1 downto 0);
         Cin : in std_logic;
         g,p : out std_logic_vector(N-1 downto 0));
  end component PG_NETWORK_GEN;
  
  signal G_out : std_logic_vector(N/M downto 0);
  
  type signalVector is array (N downto 1) of std_logic_vector(N downto 1);
  signal p_matrix, g_matrix : signalVector; --output of the pg an g blocks. Are indexed using i and j values.
  
  signal g_s, p_s : std_logic_vector(N downto 1);
  constant max_liv : integer := log2(N);
  
begin
 
  PG_NET: PG_NETWORK_GEN generic map(N=>N) port map(A=>A,
                                                    B=>B,
                                                    Cin=>Cin,
                                                    g=>g_s,
                                                    p=>p_s);
   
  liv: for l in 1 to max_liv generate
    row:for i in 1 to N generate
      
        G0: if (l = 1) generate --used to generate the first level of the whole structure
          
          G1: if (i mod 2 = 0) generate --used to generate a block when i is even
            G2: if ( i = 2 ) generate --used to create the generate block of the first level
              G21: G_BLOCK port map(Gik=> g_s(i),
                                    Pik=> p_s(i),
                                    Gkj=> g_s(i-1),
                                    Gij=> g_matrix(i)(i-1));
            end generate;
            G3: if (i > 2) generate --used to create the PG blocks in the first level
              PG_L1: PG_BLOCK port map(Gik=> g_s(i),
                                       Pik=> p_s(i),
                                       Gkj=> g_s(i-1),
                                       Pkj=> p_s(i-1),
                                       Gij=> g_matrix(i)(i-1),
                                       Pij=> p_matrix(i)(i-1));
            end generate;
          end generate;
          
        end generate;

        G4: if (l > 1) generate

          G5: if (i mod M = 0) generate --used to generate the G blocks in each level 
            G6: if(i <= 2**l and i > 2**(l-1)) generate
                 G_B_n: G_BLOCK port map(Gik=> g_matrix(i)(prev_exp(i,N)+1),
                                         Pik=> p_matrix(i)(prev_exp(i,N)+1),
                                         Gkj=> g_matrix(prev_exp(i,N))(1),
                                         Gij=> g_matrix(i)(1));
              end generate;
            G7: for j in 1 to N generate
              
              G8: if((i-j) > 2**(l-1) and (i-j) < 2**l and j > 2**l and (j mod 2**l) = 1) generate --used to generate the PG block in each level
                PG_B_n: PG_BLOCK port map(Gik=>g_matrix(i)(j+2**(l-1)) ,
                                          Pik=>p_matrix(i)(j+2**(l-1)) ,
                                          Gkj=>g_matrix(i-2**(l-1))(j) ,
                                          Pkj=> p_matrix(i-2**(l-1))(j),
                                          Gij=>g_matrix(i)(j) ,
                                          Pij=> p_matrix(i)(j));
              end generate;
            end generate;
            
          end generate;
        end generate;
        
      end generate;
    end generate;

   output : process (g_matrix) --Assigning the output of the entity to the output of the G blocks.
     begin
       for i in 1 to N loop
         if (i mod M = 0) then
           C((i/M)-1) <= g_matrix(i)(1);
         end if;
       end loop;
   end process output;

  
end architecture structural;


