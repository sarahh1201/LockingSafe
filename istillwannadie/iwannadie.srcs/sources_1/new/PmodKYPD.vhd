library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity PmodKYPD_top is
    Port (
        clk            : in  STD_LOGIC;
        reset          : in  STD_LOGIC;
        JA             : inout STD_LOGIC_VECTOR(7 downto 0);
        an             : out STD_LOGIC_VECTOR(3 downto 0);
        seg            : out STD_LOGIC_VECTOR(6 downto 0);
        key_valid      : out STD_LOGIC;
        digit          : out STD_LOGIC_VECTOR(3 downto 0);
        passcode_flag  : out STD_LOGIC;
        correct_flag   : out STD_LOGIC;
        display_enable : in  STD_LOGIC;
        lockout_flag   : in  STD_LOGIC
    );
end PmodKYPD_top;

architecture Structural of PmodKYPD_top is
    signal Decode            : STD_LOGIC_VECTOR(3 downto 0);
    signal Col_sig           : STD_LOGIC_VECTOR(3 downto 0);
    signal key_valid_int     : STD_LOGIC;
    signal pass_flag_int     : STD_LOGIC;
    signal correct_flag_int  : STD_LOGIC;

    component Decoder is
        Port (
            clk       : in  STD_LOGIC;
            Row       : in  STD_LOGIC_VECTOR(3 downto 0);
            Col       : out STD_LOGIC_VECTOR(3 downto 0);
            DecodeOut : out STD_LOGIC_VECTOR(3 downto 0)
        );
    end component;

    component DisplayController is
        Port (
            clk            : in  STD_LOGIC;
            DispVal        : in  STD_LOGIC_VECTOR(3 downto 0);
            anode             : out STD_LOGIC_VECTOR(3 downto 0);
            segOut            : out STD_LOGIC_VECTOR(6 downto 0);
            passcode_flag  : out STD_LOGIC;
            correct_flag   : out STD_LOGIC;
            display_enable : in  STD_LOGIC;
            lockout_flag   : in  STD_LOGIC
        );
    end component;

begin
    JA(3 downto 0) <= Col_sig;

    DEC : Decoder
        port map(
            clk       => clk,
            Row       => JA(7 downto 4),
            Col       => Col_sig,
            DecodeOut => Decode
        );

    digit <= Decode;
    key_valid_int <= '1' when Decode /= "0000" else '0';
    key_valid <= key_valid_int;

    DSP : DisplayController
        port map(
            clk            => clk,
            DispVal        => Decode,
            anode             => an,
            segOut            => seg,
            passcode_flag  => pass_flag_int,
            correct_flag   => correct_flag_int,
            display_enable => display_enable,
            lockout_flag   => lockout_flag
        );

    passcode_flag <= pass_flag_int;
    correct_flag  <= correct_flag_int;
end Structural;
