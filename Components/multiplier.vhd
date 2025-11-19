-- Originally from assignment 2 made by Ivailo

library IEEE;
use IEEE.numeric_std.all;
use IEEE.std_logic_1164.all;

entity mult4x4 is -- Procedure for a 4-bit multiplier: Use the add & shift operation to accomplish it:
	port(clk, st : in bit;
		multiplier, Mcand : in unsigned (3 downto 0);
		prod : out unsigned (7 downto 0);
		Done : out bit); -- check bit
end mult4x4;

architecture behavioral of mult4x4 is
signal state : integer range 0 to 9; -- The total number of finite states this code exhibits, from 0 to 9
signal acc : unsigned (8 downto 0); -- The 8-bit accumulator input that is multiplying against each other (INCLUDES CARRY!)
alias M : std_logic is acc(0); -- You can assign the 'acc' signal to alias 'M', specifically for its state at '0'

begin
	process(clk) -- Make the system trigger every clock cycle
	begin
		if clk'event and clk = '1' then -- So every rising edge
		case state is
			when 0 =>
				if st = '1' then -- 'st' acts as a check bit to ensure the system is allowed to work
					acc(8 downto 4) <= "00000"; -- The bottom-half input, INCLUDING THE CARRY BIT!
					acc(3 downto 0) <= multiplier; -- And we load in the top-half
					State <= 1; -- Increment to the next state
				end if;
			when 1 | 3 | 5 | 7 => -- So for any odd-valued state, we add and shift bit values here
				if M = '1' then -- Check the alias bit, if '1' then you add the multiplier together
					acc(8 downto 4) <= ('0' & acc(7 downto 4)) + ('0' & Mcand); -- Set all to 0, and insert all values
					state <= state + 1; -- Increment to the next state
				else -- If no multiplier, just shift the accumulator over to the right
					acc <= '0' & acc(8 downto 1);
					state <= state + 2;
				end if;
			when 2 | 4 | 6 | 8 =>  -- Now if the state is even, we simply shift it over forcefully
				acc <= '0' & acc(8 downto 1); -- Just the default right shift operation
				state <= state + 1; -- Increment to the next state
			when 9 =>
				state <= 0; -- Sole purpose is to reset the loop back to the beginning
			end case;
		end if;
	end process;
	done <= '1' when state = 9 else '0'; -- Tells the system the loop has been succesfully completed when it hits state 9
	prod <= acc(7 downto 0);
end behavioral;
