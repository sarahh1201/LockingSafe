library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity safe_top is
    port(
        clk        : in  std_logic;                     -- System clock (100 MHz)
        reset      : in  std_logic;                     -- Global reset
        start_btn  : in  std_logic;                     -- physical start button
        JA         : inout std_logic_vector(7 downto 0);-- keypad pins
        an         : out std_logic_vector(3 downto 0);  -- 7-seg anode enables
        seg        : out std_logic_vector(6 downto 0);  -- 7-seg segment outputs
        servoPWM   : out std_logic;                     -- PWM to servo
        buzzer_out : out std_logic;                     -- buzzer output
        chk_lock_cmd   : out std_logic;                 -- debug
        chk_unlock_cmd : out std_logic;                 -- debug
        passcode_chk   : out std_logic                  -- debug
    );
end safe_top;

architecture Structural of safe_top is
    component PmodKYPD_top
        port (
            clk            : in  STD_LOGIC;
            reset          : in  STD_LOGIC;
            JA             : inout STD_LOGIC_VECTOR(7 downto 0);
            an             : out STD_LOGIC_VECTOR(3 downto 0);
            seg            : out STD_LOGIC_VECTOR(6 downto 0);
            key_valid      : out STD_LOGIC;              -- corrected direction
            digit          : out STD_LOGIC_VECTOR(3 downto 0);
            passcode_flag  : out STD_LOGIC;
            correct_flag   : out STD_LOGIC;
            display_enable : in  STD_LOGIC;
            lockout_flag   : in  STD_LOGIC
        );
    end component;

    component controller
        port(
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

    component servo
        port(
            clk      : in  std_logic;
            reset    : in  std_logic;
            lock     : in  std_logic;
            unlock   : in  std_logic;
            servoPWM : out std_logic;
            chk_lock   : out std_logic;
            chk_unlock : out std_logic
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

    -- Internal signals
    signal digit         : std_logic_vector(3 downto 0);
    signal pass_flag     : std_logic;
    signal crct_flag     : std_logic;
    signal alarmState_s  : std_logic;
    signal lock_cmd_s    : std_logic;
    signal unlock_cmd_s  : std_logic;
    signal key_valid_s   : std_logic;

    signal start_pulse   : std_logic := '0';
    signal prev_startbtn : std_logic := '0';
    signal done_sig      : std_logic := '0';
    signal display_en    : std_logic := '0';
    signal lockout_sig   : std_logic := '0';

begin
    -- Start pulse generator
    process(clk)
    begin
        if rising_edge(clk) then
            start_pulse   <= start_btn and not prev_startbtn;
            prev_startbtn <= start_btn;
        end if;
    end process;

    -- Keypad and Display
    U1_PmodKYPD: PmodKYPD_top
        port map(
            clk            => clk,
            reset          => reset,
            JA             => JA,
            an             => an,
            seg            => seg,
            key_valid      => key_valid_s,
            digit          => digit,
            passcode_flag  => pass_flag,
            correct_flag   => crct_flag,
            display_enable => display_en,
            lockout_flag   => lockout_sig
        );

    passcode_chk <= pass_flag;

    -- Controller FSM
    U3_controller: controller
        port map(
            clk            => clk,
            reset          => reset,
            start          => start_pulse,
            passcode_flag  => pass_flag,
            correct_flag   => crct_flag,
            done           => done_sig,
            lock_cmd       => lock_cmd_s,
            unlock_cmd     => unlock_cmd_s,
            alarmState     => alarmState_s,
            display_enable => display_en,
            lockout_flag   => lockout_sig
        );

    -- Servo Motor Module
    U4_servo: servo
        port map(
            clk        => clk,
            reset      => reset,
            lock       => lock_cmd_s,
            unlock     => unlock_cmd_s,
            servoPWM   => servoPWM,
            chk_lock   => chk_lock_cmd,
            chk_unlock => chk_unlock_cmd
        );

    -- Alarm Module
    U5_alarm: alarm
        port map(
            clk        => clk,
            reset      => reset,
            alarmState => alarmState_s,
            buzzer_out => buzzer_out
        );
end Structural;
