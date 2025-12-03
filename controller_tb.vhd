library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity controller_tb is
end entity;

architecture sim of controller_tb is
    -- DUT signals
    signal clk            : std_logic := '0';
    signal reset          : std_logic := '0';
    signal start          : std_logic := '0';
    signal passcode_flag  : std_logic := '0';
    signal correct_flag   : std_logic := '0';

    signal done           : std_logic;
    signal lock_cmd       : std_logic;
    signal unlock_cmd     : std_logic;
    signal alarmState     : std_logic;
    signal display_enable : std_logic;
    signal lockout_flag   : std_logic;

    -- Clock period
    constant clk_period : time := 100 ps; -- for simluation purposes 

    component controller is
        port (
            clk            : in  std_logic;
            reset          : in  std_logic;
            start          : in  std_logic;
            passcode_flag  : in  std_logic;
            correct_flag   : in  std_logic;

            done           : out std_logic;
            lock_cmd       : out std_logic;
            unlock_cmd     : out std_logic;
            alarmState     : out std_logic;
            display_enable : out std_logic;
            lockout_flag   : out std_logic
        );
    end component;
begin

    -- DUT instantiation
    DUT: controller
        port map (
            clk            => clk,
            reset          => reset,
            start          => start,
            passcode_flag  => passcode_flag,
            correct_flag   => correct_flag,
            done           => done,
            lock_cmd       => lock_cmd,
            unlock_cmd     => unlock_cmd,
            alarmState     => alarmState,
            display_enable => display_enable,
            lockout_flag   => lockout_flag
        );

    -- Clock generation
    clk_process: process
    begin
        while true loop
            clk <= '0';
            wait for clk_period/2;
            clk <= '1';
            wait for clk_period/2;
        end loop;
    end process;

    -- Stimulus
    stim_proc: process
    begin
        -- Reset and startup check
        reset <= '1';
        wait for 5*clk_period;
        reset <= '0';
        wait for 2*clk_period;

        -- Scenario 1: Correct passcode attempt -> should unlock
        passcode_flag <= '1'; correct_flag <= '1';
        wait for 2*clk_period;
        passcode_flag <= '0'; correct_flag <= '0';
        wait for 2*clk_period;

        assert unlock_cmd = '1' and done = '1'
            report "ERROR: Unlock not asserted after correct passcode"
            severity error;

        -- Reset back to LOCKED quickly
        reset <= '1'; wait for 2*clk_period; reset <= '0';
        wait for 2*clk_period;

        -- Scenario 2: Three wrong attempts -> should lockout
        for i in 1 to 3 loop
            passcode_flag <= '1'; correct_flag <= '0';
            wait for 2*clk_period;
            passcode_flag <= '0';
            wait for 2*clk_period;
        end loop;

        wait for 2*clk_period;
        assert lockout_flag = '1'
            report "ERROR: Lockout flag not asserted"
            severity error;
        assert alarmState = '1'
            report "ERROR: Alarm not active during lockout"
            severity error;

        -- End simulation
        wait for 5*clk_period;
        assert false report "Simulation finished" severity failure;
    end process;
end architecture;
