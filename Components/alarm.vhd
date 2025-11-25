library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

-- General idea: Alarm that when triggered, should beep at an interval of 1 second
entity alarm is port(
	clk, reset, alarmState : in STD_LOGIC;
	buzzer_out : out STD_LOGIC
);

end entity alarm;

architecture rtl of alarm is -- Using a messed-up Register Transfer Level (RTL) Architecture
	constant CLK_FREQ : integer := 100_000_000; -- Basically 1 second for the FPGA board's CLK
	-- Second counter: Needs to hold values up to 100 million, which is a 27-bit binary value
	signal second_counter : unsigned(26 downto 0) := (others => '0');
	signal blinker : STD_LOGIC := '1'; -- Does the alarm sound 'blinking', starts at HIGH and goes to LOW after, looping
	signal buzzer_int : STD_LOGIC; -- Used to represent the actual buzzer file
begin

	process(clk, reset)
	begin
		if reset = '1' then -- Asynchronous Reset to basically bring everything back to default
			second_counter <= (others => '0'); -- Just reset everything
			blinker <= '1';
		elsif rising_edge(clk) then -- Where the real work is done
			if alarmState = '1' then -- So if the alarm is on
				if second_counter = to_unsigned(CLK_FREQ, second_counter'length) then -- Basically if the two match (i.e. 1 second), flip the piezo to LOW or HIGH
					second_counter <= (others => '0'); -- Also reset the counter to reach 100 million again
					blinker <= not blinker;
				else
					second_counter <= second_counter + 1;
				end if;
			else -- When alarm is inactive, keep everything in a default state
				second_counter <= (others => '0');
				blinker	<= '0'; -- Necessary to keep the buzzer on LOW when not activated, but leads to a 1 second delay after the flag is entered
			end if;
		end if;
	end process;
	
	buzzerInstance : entity work.buzzer_controller -- The component code
		port map (
			clk => clk, -- Gotta do this redundant signal parsing
			reset => reset,
			buzzer_out => buzzer_int -- We assign the piezo buzzer an 'int' signal instead
		);
		
	buzzer_out <= buzzer_int and blinker; -- As it's being controlled by the CLK refresh AND the blinker alarm
end architecture rtl;
		