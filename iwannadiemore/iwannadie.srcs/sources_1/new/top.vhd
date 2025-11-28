library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity safe_top is
    port(
        clk        : in  std_logic;                     -- System clock (100 MHz from FPGA board)
        reset      : in  std_logic;                     -- Global reset
        JA         : inout std_logic_vector(7 downto 0);-- PmodKYPD physical pins (rows/columns)
        an         : out std_logic_vector(3 downto 0);  -- 7-seg anode enables
        seg        : out std_logic_vector(6 downto 0);  -- 7-seg segment outputs
        servoPWM   : out std_logic;                     -- PWM signal to servo motor
        buzzer_out : out std_logic;                      -- Output to buzzer
        chk_lock_cmd : out std_logic;
        chk_unlock_cmd : out std_logic
    );
end safe_top;

architecture Structural of safe_top is

    ----------------------------------------------------------------
    -- 1. Component Declarations
    ----------------------------------------------------------------
    component PmodKYPD_top
    Port (
        clk        : in  STD_LOGIC;                     -- system clock
        reset      : in  STD_LOGIC;                     -- reset
        JA         : inout  STD_LOGIC_VECTOR(7 downto 0); -- keypad pins
        an         : out STD_LOGIC_VECTOR(3 downto 0);  -- anodes for 7-seg
        seg        : out STD_LOGIC_VECTOR(6 downto 0);  -- segments for 7-seg
        key_valid  : inout STD_LOGIC;                     -- HIGH when a key is pressed
        digit      : out STD_LOGIC_VECTOR(3 downto 0);  -- decoded digit from keypad
        passcode_flag : out STD_LOGIC                   -- HIGH when entered passcode matches
    );
    end component;

    component controller
        port(
            clk           : in  std_logic;              -- system clock
            reset         : in  std_logic;              -- reset
            start         : in  std_logic;              -- trigger to check passcode (from key_valid)
            passcode_flag : in  std_logic;              -- result of passcode check (from DisplayController)
            load          : out std_logic;              -- latch keypad digit (not used here)
            done          : out std_logic;              -- HIGH when passcode correct
            lock_cmd      : out std_logic;              -- command to lock servo
            unlock_cmd    : out std_logic;              -- command to unlock servo
            alarmState    : out std_logic               -- HIGH when wrong passcode → buzzer
        );
    end component;

    component servo
        port(
            clk      : in  std_logic;                   -- system clock
            rst      : in  std_logic;                   -- reset
            lock     : in  std_logic;                   -- lock command from FSM
            unlock   : in  std_logic;                   -- unlock command from FSM
            servoPWM : out std_logic;                    -- PWM output to servo
            chk_lock     : out  std_logic;                   -- lock command from FSM
            chk_unlock   : out  std_logic                   -- unlock command from FSM
        );
    end component;

    component alarm
        port(
            clk        : in  std_logic;                 -- system clock
            reset      : in  std_logic;                 -- reset
            alarmState : in  std_logic;                 -- HIGH when wrong passcode
            buzzer_out : out std_logic                  -- drives buzzer
        );
    end component;

    ----------------------------------------------------------------
    -- 2. Internal signals
    ----------------------------------------------------------------
    signal digit       : std_logic_vector(3 downto 0);  -- decoded digit from keypad
    signal load        : std_logic;                     -- latch signal (unused here)
    signal done        : std_logic;                     -- FSM success indicator
    signal pass_flag   : std_logic;                     -- passcode_flag from DisplayController
    signal alarmState  : std_logic;                     -- FSM alarm output
    signal lock_cmd    : std_logic;                     -- FSM lock command
    signal unlock_cmd  : std_logic;                     -- FSM unlock command
    signal key_valid   : std_logic;                     -- HIGH when a key is pressed
begin

    ----------------------------------------------------------------
    -- 3. Component Instantiations
    ----------------------------------------------------------------

    -- Keypad and Display
    -- JA connects to the physical keypad pins.
    -- Outputs: an, seg drive the 7-seg display.
    -- key_valid pulses when a key is pressed.
    -- digit is the decoded key value.
    -- passcode_flag goes HIGH when the entered passcode matches.
    U1_PmodKYPD: PmodKYPD_top
        port map(
            clk        => clk,
            reset      => reset,
            JA         => JA,
            an         => an,
            seg        => seg,
            key_valid  => key_valid,
            digit      => digit,
            passcode_flag => pass_flag
        );

    -- Controller FSM
    -- start should come from key_valid (user pressed "check" key).
    -- passcode_flag comes from DisplayController (true/false).
    -- Outputs lock_cmd/unlock_cmd drive the servo.
    -- alarmState drives the buzzer.
    U3_controller: controller
        port map(
            clk           => clk,
            reset         => reset,
            start         => key_valid,     -- FIX: use key_valid, not pass_flag
            passcode_flag => pass_flag,     -- result of passcode check
            load          => load,
            done          => done,
            lock_cmd      => lock_cmd,
            unlock_cmd    => unlock_cmd,
            alarmState    => alarmState
        );

    -- Servo Motor Module
    -- lock_cmd/unlock_cmd from FSM control servo position.
    U4_servo: servo
        port map(
            clk      => clk,
            rst      => reset,
            lock     => lock_cmd,
            unlock   => unlock_cmd,
            servoPWM => servoPWM,
            chk_lock     => chk_lock_cmd,
            chk_unlock   => chk_unlock_cmd
        );

    -- Alarm Module
    -- alarmState from FSM drives buzzer_out.
    U5_alarm: alarm
        port map(
            clk        => clk,
            reset      => reset,
            alarmState => alarmState,
            buzzer_out => buzzer_out
        );

end Structural;
