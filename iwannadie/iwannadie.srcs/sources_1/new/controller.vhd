library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity controller is
   port (
       clk           : in  std_logic;
       reset         : in  std_logic;
       start         : in  std_logic;
       passcode_flag : in  std_logic;   -- from passcode checker
       
       load          : out std_logic;   -- latch keypad digit
       done          : out std_logic;   -- correct code indicator

       lock_cmd      : out std_logic;   -- send to servo
       unlock_cmd    : out std_logic;   -- send to servo
       alarmState    : out std_logic    -- alarm on wrong entry
   );
end controller;

architecture Behavioral of controller is

   type state_type is (LOCKED, CHECK_PASSWORD, UNLOCKED, ERROR);
   signal state : state_type := LOCKED;

begin

process (clk, reset)
begin
    if reset = '1' then
        state      <= LOCKED;
        load       <= '0';
        done       <= '0';
        lock_cmd   <= '1';
        unlock_cmd <= '0';
        alarmState <= '0';

    elsif rising_edge(clk) then
        case state is

            ----------------------------------------------------------------
            when LOCKED =>
            ----------------------------------------------------------------
                load       <= '0';
                done       <= '0';
                lock_cmd   <= '1';
                unlock_cmd <= '0';
                alarmState <= '0';

                if start = '1' then
                    state <= CHECK_PASSWORD;
                end if;

            ----------------------------------------------------------------
            when CHECK_PASSWORD =>
            ----------------------------------------------------------------
                load       <= '1';   -- latch keypad digit
                done       <= '0';
                lock_cmd   <= '1';
                unlock_cmd <= '0';
                alarmState <= '0';

                -- decide based on passcode_flag
                if passcode_flag = '1' then
                    state <= UNLOCKED;
                else
                    state <= ERROR;
                end if;

            ----------------------------------------------------------------
            when UNLOCKED =>
            ----------------------------------------------------------------
                load       <= '0';
                done       <= '1';   -- signal success
                unlock_cmd <= '1';
                lock_cmd   <= '0';
                alarmState <= '0';

                if start = '0' then
                    state <= LOCKED;
                end if;

            ----------------------------------------------------------------
            when ERROR =>
            ----------------------------------------------------------------
                load       <= '0';
                done       <= '0';
                lock_cmd   <= '1';
                unlock_cmd <= '0';
                alarmState <= '1';  -- buzzer on

                -- return to locked after error
                state <= LOCKED;

        end case;
    end if;
end process;

end Behavioral;
