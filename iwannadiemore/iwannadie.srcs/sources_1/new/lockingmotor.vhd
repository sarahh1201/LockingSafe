-- Locking Safe Motor Mechanism, maybe modular idk
library IEEE;
use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_1164.ALL;

entity servo is
	port(
		clk, rst, lock, unlock : in STD_LOGIC; -- All signals going in are simple logics
		servoPWM : out STD_LOGIC; -- And the single signal going out needs to be PWM-modulated
		chk_lock, chk_unlock : out STD_LOGIC
	);
end entity;

architecture behavioral of servo is
	-- The FPGA board uses a 100 MHz clock input, so we need to define a few parameters here:
	constant clockFreq : integer := 100_000_000; -- Should be 100 MHz
	constant frame : integer := 20; -- How often the PWM should operate actually, in this case 20 ms
	constant frameTick : integer := clockFreq / 1000 * frame; -- And our new, messed up 'clock' this servo will work under

	constant Closer_ms : real := 1.0; -- 1 ms is intended to signify that the servo should 'close'
	constant Opener_ms : real := 2.0; -- Otherwse, 2 ms should signify for the servo to open
	
	constant Closer_ticker : integer := integer(Closer_ms * real(clockFreq) / 1000.0); -- And translate these numbers into the tick rate
	constant Opener_ticker : integer := integer(Opener_ms * real(clockFreq) / 1000.0);
	
	signal frameCounter : integer range 0 to frameTick := 0; -- Should represent how many ticks it takes for the servo to open/close, defaulted at 0
	signal hLim : integer := Closer_ticker; -- The 'HIGH' limit
	signal react : std_logic := '1'; -- Should just react once

	-- Second counter: Needs to hold values up to 100 million, which is a 27-bit binary value
	signal turn_counter : unsigned(26 downto 0) := (others => '0');
	
begin
	signalStates : process(clk, rst) -- The classic
	begin
		if rst = '1' then -- Case 1: The resets witch is ON: It's literally just defaults to the 'closed' state
			hLim <= Closer_ticker;
		end if;
		if rising_edge(clk) then -- Should only operate so long as the clock is-a ticking
		chk_lock <= lock; -- Do some LED check stuff
		chk_unlock <= unlock;
			if lock = '1' then -- Case 2: the 'LOCK' signal is on, it takes precedence over 'UNLOCK'
			   if react = '1' then -- First: Go through our initial state go-around
			      turn_counter <= (others => '0'); -- Reset the counter
			      react <= '0'; -- And disable the first state check
			   elsif turn_counter /= to_unsigned(clockFreq, turn_counter'length) then -- Basically the bounds will be 1 second
				  hLim <= Closer_ticker; -- Will rotate the servo CLOSED
				  turn_counter <= turn_counter + 1; -- Hopefully for 1 second
			   else
			      hLim <= 0; -- Disables the motor
			   end if;	
			elsif unlock = '1' then -- Case 3: the 'UNLOCK' signal is on, it can finally open if the above two cases fail
			   if react = '1' then -- First: Go through our initial state go-around
			      turn_counter <= (others => '0'); -- Reset the counter
			      react <= '0'; -- And disable the first state check
			   elsif turn_counter /= to_unsigned(clockFreq, turn_counter'length) then
				  hLim <= Opener_ticker; -- Will rotate the servo OPEN
				  turn_counter <= turn_counter + 1; -- Hopefully for 1 second
			   else
			      hLim <= 0; -- Disables the motor
			   end if;				
			   else -- And if nothing applies, then just tell the servo to hold its current state
				hLim <= 0;
				react <= '1'; -- So when it's doing nothing, essentially 'prime' its first state go-around
			end if;
		end if;
	end process signalStates;

	tickManager : process(clk, rst) -- Process 2: Just operates the whole 'ticking' system
	begin
		if rst = '1' then -- Case 1: Reset pin's on, reset the ticker altogether with NO respect to the clock
			frameCounter <= 0;
			servoPWM <= '0';
		elsif rising_edge(clk) then -- Case 2: For every clock cycle:
			if frameCounter < frameTick - 1 then -- First: if just before its limit, count up once more
				frameCounter <= frameCounter + 1;
			else
				frameCounter <= 0; -- Otherwise, default back to '0'
			end if;

			if frameCounter < hLim then -- Now: to finally operate the servo, we check the hLim
				servoPWM <= '1'; -- if on, turn the servo either to a locking or unlocking state
			else
				servoPWM <= '0'; -- if otherwise, just hold the current position
			end if;
		end if;
	end process tickManager;
end architecture;