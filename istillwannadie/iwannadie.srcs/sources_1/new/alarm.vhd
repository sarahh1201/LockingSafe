library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

-- General idea: Alarm that when triggered, should beep at an interval of 1 second
-- BUT instead of just toggling once per second (which is inaudible), we generate
-- a 2 kHz square wave tone and gate it with the 1 Hz blinker so the buzzer pulses.
entity alarm is port(
    clk, reset, alarmState : in STD_LOGIC;
    buzzer_out : out STD_LOGIC
);

end entity alarm;

architecture rtl of alarm is -- Using a messed-up Register Transfer Level (RTL) Architecture
    constant CLK_FREQ : integer := 100_000_000; -- Basically 1 second for the FPGA board's CLK

    -- Second counter: Needs to hold values up to 100 million, which is a 27-bit binary value
    signal second_counter : unsigned(26 downto 0) := (others => '0');
    signal blinker : STD_LOGIC := '0'; -- Does the alarm sound 'blinking', starts at HIGH and goes to LOW after, looping

    -- Tone generator: annoying audio frequency (2 kHz square wave)
    constant TONE_FREQ : integer := 2000; -- Frequency of the buzzer tone
    constant TONE_TICKS : integer := CLK_FREQ / (2 * TONE_FREQ); -- Half-period count for square wave
    signal tone_counter : unsigned(31 downto 0) := (others => '0');
    signal tone_wave : STD_LOGIC := '0'; -- The actual fast toggling signal for the buzzer

    signal buzzer_int : STD_LOGIC; -- Used to represent the actual buzzer file
begin

    -- Process 1: Slow blinker envelope (1 Hz)
    process(clk, reset)
    begin
        if reset = '1' then -- Asynchronous Reset to basically bring everything back to default
            second_counter <= (others => '0'); -- Just reset everything
            blinker <= '0'; -- Start silent at reset
        elsif rising_edge(clk) then -- Where the real work is done
            if alarmState = '1' then -- So if the alarm is on
                if second_counter = to_unsigned(CLK_FREQ - 1, second_counter'length) then  -- Basically if the two match (i.e. 1 second), flip the piezo to LOW or HIGH
                    second_counter <= (others => '0'); -- Also reset the counter to reach 100 million again
                    blinker <= not blinker;
                else
                    second_counter <= second_counter + 1;
                end if;
            else -- When alarm is inactive, keep everything in a default state
                second_counter <= (others => '0');
                blinker <= '0'; -- Necessary to keep the buzzer on LOW when not activated
            end if;
        end if;
    end process;

    -- Process 2: Fast tone generator (2 kHz square wave)
    process(clk, reset)
    begin
        if reset = '1' then -- Reset tone generator
            tone_counter <= (others => '0');
            tone_wave <= '0';
        elsif rising_edge(clk) then
            if tone_counter = to_unsigned(TONE_TICKS - 1, tone_counter'length) then
                tone_counter <= (others => '0');
                tone_wave <= not tone_wave; -- Toggle output every half-period
            else
                tone_counter <= tone_counter + 1;
            end if;
        end if;
    end process;

    -- Final buzzer output: tone gated by blinker and alarmState
    buzzer_out <= tone_wave and blinker and alarmState; -- As it's being controlled by the CLK refresh, the blinker alarm, and the fast tone

end architecture rtl;