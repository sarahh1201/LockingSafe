library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity controller is
   port (
       clk           : in  std_logic;
       reset         : in  std_logic;
       start         : in  std_logic;
       passcode_flag : in  std_logic;  -- '1' if correct password
       load          : out std_logic;
       done          : out std_logic
   );
end controller;

architecture Behavioral of controller is

   type state_type is (LOCKED, CHECK_PASSWORD, UNLOCKED, TIMEOUT);
   signal state : state_type := LOCKED;

   signal start_d : std_logic := '0';

begin

process (clk, reset)
begin
    if reset = '1' then
        state   <= LOCKED;
        load    <= '0';
        done    <= '0';
        start_d <= '0';

    elsif rising_edge(clk) then
        start_d <= start;   -- to detect rising edge of start

        case state is

            when LOCKED =>
                load <= '0';
                done <= '0';

                -- detect rising edge of "start"
                if start = '1' and start_d = '0' then
                    state <= CHECK_PASSWORD;
                end if;

            when CHECK_PASSWORD =>
                load <= '1';   -- sample entered password

                if passcode_flag = '1' then
                    state <= UNLOCKED;
                else
                    state <= LOCKED;   -- go back if wrong
                end if;

            when UNLOCKED =>
                load <= '0';
                done <= '1';   -- indicate success

                -- lock again when start goes low–>high again
                if start = '0' then
                    state <= LOCKED;
                end if;

            when TIMEOUT =>
                state <= LOCKED;

        end case;
    end if;
end process;

end Behavioral;
