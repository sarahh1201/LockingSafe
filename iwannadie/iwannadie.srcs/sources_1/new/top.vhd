library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity safe_top is--this
    port(
        clk        : in  std_logic;
        reset      : in  std_logic;
        JA         : inout std_logic_vector(7 downto 0);
        an         : out std_logic_vector(3 downto 0);
        seg        : out std_logic_vector(6 downto 0);
        servoPWM   : out std_logic;
        buzzer_out : out std_logic
    );
end safe_top;

architecture Structural of safe_top is

    ----------------------------------------------------------------
    -- 1. Component Declarations
    ----------------------------------------------------------------
    component PmodKYPD_top
    Port (
        clk        : in  STD_LOGIC;
        reset      : in  STD_LOGIC;
        JA         : inout  STD_LOGIC_VECTOR(7 downto 0); -- Only input
        an         : out STD_LOGIC_VECTOR(3 downto 0);
        seg        : out STD_LOGIC_VECTOR(6 downto 0);
        enter_flag : out STD_LOGIC;
        clear_flag : out STD_LOGIC;
        key_valid  : inout STD_LOGIC;
        digit      : out STD_LOGIC_VECTOR(3 downto 0);
        passcode_flag : out STD_LOGIC   -- New output
    );
    end component;

    component controller
        port(
            clk           : in  std_logic;
            reset         : in  std_logic;
            start         : in  std_logic;
            passcode_flag : in  std_logic;
            load          : out std_logic;
            done          : out std_logic;
            lock_cmd      : out std_logic;
            unlock_cmd    : out std_logic;
            alarmState    : out std_logic
        );
    end component;

    component servo
        port(
            clk      : in  std_logic;
            rst      : in  std_logic;
            lock     : in  std_logic;
            unlock   : in  std_logic;
            servoPWM : out std_logic
        );
    end component;

    component alarm
        port(
            clk        : in  std_logic;
            reset      : in  std_logic;
            alarmState : in  std_logic;
            buzzer_out : out std_logic
        );
    end component;

    ----------------------------------------------------------------
    -- 2. Internal signals
    ----------------------------------------------------------------
    signal digit       : std_logic_vector(3 downto 0);
    signal load        : std_logic;
    signal done        : std_logic;
    signal pass_flag   : std_logic;
    signal alarmState  : std_logic;
    signal lock_cmd    : std_logic;
    signal unlock_cmd  : std_logic;
    signal enter_flag  : std_logic;
    signal clear_flag  : std_logic;
    signal key_valid   : std_logic;

begin

    ----------------------------------------------------------------
    -- 3. Component Instantiations
    ----------------------------------------------------------------

    -- Keypad and Display
    U1_PmodKYPD: PmodKYPD_top
        port map(
            clk        => clk,
            reset      => reset,
            JA         => JA,
            an         => an,
            seg        => seg,
            enter_flag => enter_flag,
            clear_flag => clear_flag,
            key_valid  => key_valid,
            digit      => digit,
            passcode_flag => pass_flag
        );

    -- Controller FSM
    U3_controller: controller
        port map(
            clk           => clk,
            reset         => reset,
            start         => enter_flag,
            passcode_flag => pass_flag,
            load          => load,
            done          => done,
            lock_cmd      => lock_cmd,
            unlock_cmd    => unlock_cmd,
            alarmState    => alarmState
        );

    -- Servo Motor Module
    U4_servo: servo
        port map(
            clk      => clk,
            rst      => reset,
            lock     => lock_cmd,
            unlock   => unlock_cmd,
            servoPWM => servoPWM
        );

    -- Alarm Module
    U5_alarm: alarm
        port map(
            clk        => clk,
            reset      => reset,
            alarmState => alarmState,
            buzzer_out => buzzer_out
        );

end Structural;
