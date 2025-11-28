library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity PmodKYPD_top is
    Port (
        clk        : in  STD_LOGIC;
        reset      : in  STD_LOGIC;
        JA         : inout  STD_LOGIC_VECTOR(7 downto 0); -- Only input
        an         : out STD_LOGIC_VECTOR(3 downto 0);
        seg        : out STD_LOGIC_VECTOR(7 downto 0);
        enter_flag : out STD_LOGIC;
        clear_flag : out STD_LOGIC;
        key_valid  : inout STD_LOGIC;
        digit      : out STD_LOGIC_VECTOR(3 downto 0);
        passcode_flag : out STD_LOGIC   -- New output
    );
end PmodKYPD_top;

architecture Structural of PmodKYPD_top is

    -- Internal signals
    signal Decode : STD_LOGIC_VECTOR(3 downto 0);
    signal Col_sig : STD_LOGIC_VECTOR(3 downto 0);
    signal load_digit : STD_LOGIC;

    -- Component declarations
    component Decoder is
        Port (
            clk        : in  STD_LOGIC;
            Row        : in  STD_LOGIC_VECTOR(3 downto 0);
            Col        : out STD_LOGIC_VECTOR(3 downto 0);
            DecodeOut  : out STD_LOGIC_VECTOR(3 downto 0);
            enter_flag : out STD_LOGIC;
            clear_flag : out STD_LOGIC;
            input_flag : out STD_LOGIC
        );
    end component;

    component DisplayController is
        Port (
            DispVal : in  STD_LOGIC_VECTOR(3 downto 0);
            anode   : out STD_LOGIC_VECTOR(3 downto 0);
            segOut  : out STD_LOGIC_VECTOR(6 downto 0)
        );
    end component;

    component passcode_checker is
        Port (
            clk           : in  STD_LOGIC;
            reset         : in  STD_LOGIC;
            load          : in  STD_LOGIC;
            digit_in      : in  STD_LOGIC_VECTOR(3 downto 0);
            passcode_flag : out STD_LOGIC
        );
    end component;

begin

    -- Drive columns of the keypad
    JA(3 downto 0) <= Col_sig;

    -- Decoder instantiation
    DEC : Decoder
        port map(
            clk        => clk,
            Row        => JA(7 downto 4),
            Col        => Col_sig,
            DecodeOut  => Decode,
            enter_flag => enter_flag,
            clear_flag => clear_flag,
            input_flag => key_valid
        );

    -- Load digit on key press
    load_digit <= key_valid;

    -- Passcode checker instantiation
    PASSCHK : passcode_checker
        port map(
            clk           => clk,
            reset         => reset,
            load          => load_digit,
            digit_in      => Decode,
            passcode_flag => passcode_flag
        );

    -- Output the current digit
    digit <= Decode;

    -- Display controller
    DSP : DisplayController
        port map(
            DispVal => Decode,
            anode   => an,
            segOut  => seg
        );

end Structural;
