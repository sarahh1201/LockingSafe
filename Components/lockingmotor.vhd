-- Locking Safe Motor Mechanism, maybe modular idk
library IEEE;
use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_1164.ALL;

entity servo is
	port(
		clk, rst, lock, unlock : in STD_LOGIC; -- All signals going in are simple logics
		servoPWM : out STD_LOGIC -- And the single signal going out needs to be PWM-modulated
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
begin
	signalStates : process(clk, rst) -- The classic
	begin
		if rst = '1' then -- Case 1: The resets witch is ON: It's literally just defaults to the 'closed' state
			hLim <= Closer_ticker;
		end if;
		if rising_edge(clk) then -- Should only operate so long as the clock is-a ticking
			if lock = '1' then -- Case 2: the 'LOCK' signal is on, it takes precedence over 'UNLOCK'
				hLim <= Closer_ticker;	
			elsif unlock = '1' then -- Case 3: the 'UNLOCK' signal is on, it can finally open if the above two cases fail
				hLim <= Opener_ticker;	
			else -- And if nothing applies, then just tell the servo to hold its current state
				hLim <= hLim;
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