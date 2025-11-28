library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity passcode_checker is
    port(
        clk        : in std_logic;
        reset      : in std_logic;
        load       : in std_logic;  -- load digit from decoder
        digit_in   : in std_logic_vector(3 downto 0);
        passcode_flag : out std_logic
    );
end passcode_checker;

architecture Behavioral of passcode_checker is

    type state_type is (D0, D1, D2, D3);
    signal state : state_type := D0;

    -- correct passcode = 1 2 3 4
    constant C0 : std_logic_vector(3 downto 0) := "0001";
    constant C1 : std_logic_vector(3 downto 0) := "0010";
    constant C2 : std_logic_vector(3 downto 0) := "0011";
    constant C3 : std_logic_vector(3 downto 0) := "0100";

begin

process(clk, reset)
begin
    if reset = '1' then
        state <= D0;
        passcode_flag <= '0';

    elsif rising_edge(clk) then
        if load = '1' then
            case state is
                when D0 =>
                    if digit_in = C0 then state <= D1;
                    else state <= D0; end if;

                when D1 =>
                    if digit_in = C1 then state <= D2;
                    else state <= D0; end if;

                when D2 =>
                    if digit_in = C2 then state <= D3;
                    else state <= D0; end if;

                when D3 =>
                    if digit_in = C3 then
                        passcode_flag <= '1';     -- CORRECT
                    else
                        passcode_flag <= '0';     -- WRONG
                    end if;

                    state <= D0;  -- restart for next try
            end case;
        end if;
    end if;
end process;

end Behavioral;