library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- Servo driver for continuous rotation hobby servo
-- Generates a 20 ms PWM frame with 1.0 ms (lock), 1.5 ms (neutral), or 2.0 ms (unlock) pulse widths
-- Includes debug outputs (chk_lock, chk_unlock) to mirror the lock/unlock inputs for LED checks

entity servo is
    port(
        clk        : in  std_logic;  -- 100 MHz FPGA system clock
        reset      : in  std_logic;  -- synchronous reset
        lock       : in  std_logic;  -- command to rotate in lock direction
        unlock     : in  std_logic;  -- command to rotate in unlock direction
        servoPWM   : out std_logic;  -- PWM output to servo
        chk_lock   : out std_logic;  -- debug/check output: mirrors lock input
        chk_unlock : out std_logic   -- debug/check output: mirrors unlock input
    );
end entity;

architecture Behavioral of servo is
    -- Timing constants
    constant clockFreq    : integer := 100_000_000; -- 100 MHz
    constant frameTicks   : integer := 2_000_000;   -- 20 ms frame = 2,000,000 clock cycles
    constant neutralTicks : integer := 150_000;     -- 1.5 ms pulse = stop (neutral)
    constant lockTicks    : integer := 100_000;     -- 1.0 ms pulse = rotate one way
    constant unlockTicks  : integer := 200_000;     -- 2.0 ms pulse = rotate the other way

    -- Auto-stop duration: after 2 seconds return to neutral
    constant maxDuration  : integer := clockFreq * 2;

    -- Internal counters
    signal counter          : integer range 0 to frameTicks-1 := 0; -- counts within each 20 ms frame
    signal highLim          : integer := neutralTicks;              -- current pulse width limit
    signal duration_counter : integer := 0;                         -- counts how long lock/unlock has been active
    signal prev_cmd         : std_logic_vector(1 downto 0) := "00"; -- track previous command
begin
    process(clk, reset)
    begin
        if reset = '1' then
            -- Reset everything to neutral
            counter          <= 0;
            servoPWM         <= '0';
            highLim          <= neutralTicks;
            duration_counter <= 0;
            prev_cmd         <= "00";

        elsif rising_edge(clk) then
            -- Mirror inputs to debug outputs for LED checks
            chk_lock   <= lock;
            chk_unlock <= unlock;

            -- Choose pulse width based on lock/unlock inputs
            if (lock = '1' and unlock = '0') then
                -- If switching command, reset duration counter
                if prev_cmd /= "10" then
                    duration_counter <= 0;
                end if;
                prev_cmd <= "10";

                if duration_counter < maxDuration then
                    highLim          <= lockTicks;    -- drive lock pulse
                    duration_counter <= duration_counter + 1;
                else
                    highLim <= neutralTicks;          -- auto-stop after 2 seconds
                end if;

            elsif (unlock = '1' and lock = '0') then
                if prev_cmd /= "01" then
                    duration_counter <= 0;
                end if;
                prev_cmd <= "01";

                if duration_counter < maxDuration then
                    highLim          <= unlockTicks;  -- drive unlock pulse
                    duration_counter <= duration_counter + 1;
                else
                    highLim <= neutralTicks;          -- auto-stop after 2 seconds
                end if;

            else
                -- No command or both asserted: hold neutral and reset duration counter
                highLim          <= neutralTicks;
                duration_counter <= 0;
                prev_cmd         <= "00";
            end if;

            -- Frame counter: cycles through 20 ms period
            if counter < frameTicks - 1 then
                counter <= counter + 1;
            else
                counter <= 0;
            end if;

            -- PWM output: high for highLim ticks, low otherwise
            if counter < highLim then
                servoPWM <= '1';
            else
                servoPWM <= '0';
            end if;
        end if;
    end process;
end architecture;
