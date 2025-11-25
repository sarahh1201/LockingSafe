library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity buzzer_controller is
    port (
        clk     : in  std_logic; -- System clock
        reset   : in  std_logic; -- Asynchronous reset
        buzzer_out : out std_logic  -- Output to the buzzer
    );
end entity buzzer_controller;

architecture behavioral of buzzer_controller is
    constant FREQ_HZ : integer := 1000; -- Desired buzzer frequency in Hz
    constant CLK_FREQ_HZ : integer := 100_000_000; -- System clock frequency in Hz (e.g., 100 MHz for our FPGA)
    constant HALF_PERIOD_COUNT : integer := (CLK_FREQ_HZ / (2 * FREQ_HZ)) - 1;

    signal counter : natural range 0 to HALF_PERIOD_COUNT;
    signal buzzer_state : std_logic := '0';

begin

    process (clk, reset)
    begin
        if reset = '1' then
            counter <= 0;
            buzzer_state <= '0';
        elsif rising_edge(clk) then
            if counter = HALF_PERIOD_COUNT then
                counter <= 0;
                buzzer_state <= not buzzer_state; -- Toggle buzzer output
            else
                counter <= counter + 1;
            end if;
        end if;
    end process;

    buzzer_out <= buzzer_state;

end architecture behavioral;
