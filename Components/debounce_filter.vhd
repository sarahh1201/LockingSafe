library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity debounce_filter is
generic (Debounce_LIMIT: integer:=20);
    Port ( i_clk : in STD_LOGIC;
           i_bouncy : in STD_LOGIC;
           o_debounced : out STD_LOGIC);
end debounce_filter;

architecture Behavioral of debounce_filter is
signal r_count:integer range 0 to Debounce_LIMIT :=0;
signal r_state: std_logic :='0';

begin
process(i_clk) 
begin 
if rising_edge(i_clk) then 

if (i_Bouncy /= r_state and r_count <Debounce_LIMIT-1) then
r_Count <= r_Count +1;

elsif r_Count = Debounce_LIMIT-1 then
r_state <= i_Bouncy;
r_Count<=0;

else 
r_Count<= 0;
end if;

end if;
end process;

o_debounced<=r_state;
end Behavioral;
