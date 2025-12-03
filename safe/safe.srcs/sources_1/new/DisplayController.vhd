library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity DisplayController is
    Port (
        clk            : in  STD_LOGIC;                          -- system clock
        DispVal        : in  STD_LOGIC_VECTOR(3 downto 0);       -- input value
        anode          : out STD_LOGIC_VECTOR(3 downto 0);       -- digit enable
        segOut         : out STD_LOGIC_VECTOR(6 downto 0);       -- segment output
        passcode_flag  : out STD_LOGIC;                          -- 1-cycle pulse on check attempt
        correct_flag   : out STD_LOGIC;                          -- 1-cycle pulse if attempt correct
        display_enable : in  STD_LOGIC;                          -- blank when low (ignored if lockout_flag=1)
        lockout_flag   : in  STD_LOGIC                           -- input from main controller
    );
end DisplayController;

architecture Behavioral of DisplayController is
    type digit_array is array (0 to 3) of std_logic_vector(3 downto 0);

    -- Stored passcode: 1-2-3-4
    signal pass_true   : digit_array := ("0001","0010","0011","0100");

    -- Entry buffer and cursor
    signal pass_temp   : digit_array := (others => (others => '0'));
    signal pass_index  : integer range 0 to 3 := 0;

    -- Internal check state 
    signal pass_check  : std_logic := '0';  -- 1 if entry matches pass_true on a check
    signal show_result : std_logic := '0';  -- 1-cycle display override on check

    -- Output flag registers (pulsed for 1 clk on check)
    signal passcode_flag_r : std_logic := '0';
    signal correct_flag_r  : std_logic := '0';

    -- Multiplexing
    signal mux_index   : integer range 0 to 3 := 0;

    -- Clock divider for multiplexing
    signal div_counter : unsigned(15 downto 0) := (others => '0');
    signal slow_clk    : std_logic := '0';

    -- Digit-to-segment helper (common-cathode; a..g = segOut[6:0])
    function digit_to_segments(d : std_logic_vector(3 downto 0)) return std_logic_vector is
    begin
        case d is
            when "0000" => return "1000000"; -- 0
            when "0001" => return "1111001"; -- 1
            when "0010" => return "0100100"; -- 2
            when "0011" => return "0110000"; -- 3
            when "0100" => return "0011001"; -- 4
            when "0101" => return "0010010"; -- 5
            when "0110" => return "0000010"; -- 6
            when "0111" => return "1111000"; -- 7
            when "1000" => return "0000000"; -- 8
            when "1001" => return "0010000"; -- 9
            when others => return "1111111"; -- blank
        end case;
    end function;

begin
    process(clk)
    begin
        if rising_edge(clk) then
            div_counter <= div_counter + 1;
            slow_clk    <= div_counter(15);
        end if;
    end process;

    -- PASSCODE ENTRY AND CHECK (1-cycle pulses for flags and display override)
    process(clk)
    begin
        if rising_edge(clk) then
            -- default: clear 1-cycle pulses
            passcode_flag_r <= '0';
            correct_flag_r  <= '0';
            show_result     <= '0';

            case DispVal is
                -- Digit entry
                when "0000"|"0001"|"0010"|"0011"|"0100"|"0101"|"0110"|"0111"|"1000"|"1001" =>
                    pass_temp(pass_index) <= DispVal;

                -- Cursor moves
                when "1010" => pass_index <= 0;
                when "1011" => pass_index <= 1;
                when "1100" => pass_index <= 2;
                when "1101" => pass_index <= 3;

                -- Check attempt
                when "1110" =>
                    passcode_flag_r <= '1';       -- attempt pulse
                    show_result     <= '1';       -- show message for one cycle
                    if pass_temp = pass_true then
                        pass_check       <= '1';
                        correct_flag_r   <= '1';   -- success pulse
                    else
                        pass_check       <= '0';
                        -- correct_flag_r stays '0' on failure
                    end if;

                -- Reset entry buffer
                when "1111" =>
                    pass_temp   <= (others => (others => '0'));
                    pass_index  <= 0;
                    pass_check  <= '0';
                    show_result <= '0';

                when others =>
                    null;
            end case;
        end if;
    end process;

    -- Flag outputs
    passcode_flag <= passcode_flag_r;
    correct_flag  <= correct_flag_r;

    process(slow_clk)
    begin
        if rising_edge(slow_clk) then
            mux_index <= (mux_index + 1) mod 4;
        end if;
    end process;

    process(mux_index, pass_temp, pass_check, show_result, lockout_flag, display_enable)
    begin
        -- Lockout forces display off
        if lockout_flag = '1' then
            segOut <= "1111111";

        -- Global display disable
        elsif display_enable = '0' then
            segOut <= "1111111";

        -- Brief success/failure message on check
        elsif show_result = '1' then
            if pass_check = '1' then
                -- Displayes "G00d"
                case mux_index is
                    when 0 => segOut <= "0100001"; 
                    when 1 => segOut <= "1000000"; 
                    when 2 => segOut <= "1000000"; 
                    when 3 => segOut <= "0000010"; 
                    when others => segOut <= "1111111";
                end case;
            else
                -- Displays ER0R
                case mux_index is
                    when 0 => segOut <= "0101111"; 
                    when 1 => segOut <= "1000000"; 
                    when 2 => segOut <= "0101111"; 
                    when 3 => segOut <= "0000110"; 
                    when others => segOut <= "1111111";
                end case;
            end if;

        else
            case mux_index is
                when 0 => segOut <= digit_to_segments(pass_temp(0));
                when 1 => segOut <= digit_to_segments(pass_temp(1));
                when 2 => segOut <= digit_to_segments(pass_temp(2));
                when 3 => segOut <= digit_to_segments(pass_temp(3));
                when others => segOut <= "1111111";
            end case;
        end if;
    end process;

    with mux_index select
        anode <= "1110" when 0,
                 "1101" when 1,
                 "1011" when 2,
                 "0111" when 3;

end Behavioral;
