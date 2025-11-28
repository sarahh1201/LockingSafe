library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity DisplayController is
    Port (
        clk : in STD_LOGIC;                          -- system clock
        DispVal : in STD_LOGIC_VECTOR (3 downto 0);  -- input value
        anode   : out STD_LOGIC_VECTOR (3 downto 0); -- digit enable
        segOut  : out STD_LOGIC_VECTOR (6 downto 0); -- segment output
        passcode_flag : out STD_LOGIC                -- success flag
    );
end DisplayController;

architecture Behavioral of DisplayController is

    type digit_array is array (0 to 3) of std_logic_vector(3 downto 0);

    signal pass_true : digit_array := (
        0 => "0001",  -- 1
        1 => "0010",  -- 2
        2 => "0011",  -- 3
        3 => "0100"   -- 4
    );

    signal pass_temp : digit_array := (others => (others => '0'));
    signal pass_index : integer range 0 to 3 := 0;
    signal pass_check : std_logic := '0';
    signal check_mode : std_logic := '0';  -- NEW: flag to override display

    -- Multiplexing
    signal mux_index : integer range 0 to 3 := 0;
    signal current_digit : std_logic_vector(3 downto 0);

    -- Clock divider
    signal div_counter : unsigned(15 downto 0) := (others => '0');
    signal slow_clk : std_logic := '0';

begin

    ---------------------------------------------------------------------
    -- CLOCK DIVIDER
    ---------------------------------------------------------------------
    process(clk)
    begin
        if rising_edge(clk) then
            div_counter <= div_counter + 1;
            slow_clk <= div_counter(15);
        end if;
    end process;

    ---------------------------------------------------------------------
    -- PASSCODE LOGIC
    ---------------------------------------------------------------------
    process(clk)
    begin
        if rising_edge(clk) then
            case DispVal is
                when "0000" => pass_temp(pass_index) <= "0000";
                when "0001" => pass_temp(pass_index) <= "0001";
                when "0010" => pass_temp(pass_index) <= "0010";
                when "0011" => pass_temp(pass_index) <= "0011";
                when "0100" => pass_temp(pass_index) <= "0100";
                when "0101" => pass_temp(pass_index) <= "0101";
                when "0110" => pass_temp(pass_index) <= "0110";
                when "0111" => pass_temp(pass_index) <= "0111";
                when "1000" => pass_temp(pass_index) <= "1000";
                when "1001" => pass_temp(pass_index) <= "1001";

                -- Cursor moves
                when "1010" => pass_index <= 0;
                when "1011" => pass_index <= 1;
                when "1100" => pass_index <= 2;
                when "1101" => pass_index <= 3;

                -- Check passcode
                when "1110" =>
                    check_mode <= '1';  -- enable override
                    if pass_temp = pass_true then
                        pass_check <= '1';
                    else
                        pass_check <= '0';
                    end if;

                -- Reset
                when "1111" =>
                    pass_temp <= (others => (others => '0'));
                    pass_index <= 0;
                    pass_check <= '0';
                    check_mode <= '0';

                when others =>
                    null;
            end case;
        end if;
    end process;

    passcode_flag <= pass_check;

    ---------------------------------------------------------------------
    -- DISPLAY MULTIPLEXING
    ---------------------------------------------------------------------
    process(slow_clk)
    begin
        if rising_edge(slow_clk) then
            mux_index <= (mux_index + 1) mod 4;
        end if;
    end process;

    ---------------------------------------------------------------------
    -- SELECT DIGIT TO DISPLAY
    ---------------------------------------------------------------------
    process(mux_index, pass_check, check_mode, pass_temp)
    begin
        if check_mode = '1' then
            if pass_check = '1' then
                -- Success → show "600D"
                case mux_index is
                    when 0 => current_digit <= "0110"; -- 6
                    when 1 => current_digit <= "0000"; -- 0
                    when 2 => current_digit <= "0000"; -- 0
                    when 3 => current_digit <= "1101"; -- D
                    when others => current_digit <= "1111";
                end case;
            else
                -- Failure → show "E" only
                case mux_index is
                    when 0 => current_digit <= "1110"; -- E
                    when others => current_digit <= "1111"; -- blank
                end case;
            end if;
        else
            -- Normal mode → show entered digits
            case mux_index is
                when 0 => current_digit <= pass_temp(0);
                when 1 => current_digit <= pass_temp(1);
                when 2 => current_digit <= pass_temp(2);
                when 3 => current_digit <= pass_temp(3);
                when others => current_digit <= "1111";
            end case;
        end if;
    end process;

    ---------------------------------------------------------------------
    -- DRIVE ANODES
    ---------------------------------------------------------------------
    with mux_index select
        anode <= "1110" when 0,
                 "1101" when 1,
                 "1011" when 2,
                 "0111" when 3;

    ---------------------------------------------------------------------
    -- 7-segment DECODER
    ---------------------------------------------------------------------
    process(current_digit)
    begin
        case current_digit is
            when "0000" => segOut <= "1000000";  -- 0
            when "0001" => segOut <= "1111001";  -- 1
            when "0010" => segOut <= "0100100";  -- 2
            when "0011" => segOut <= "0110000";  -- 3
            when "0100" => segOut <= "0011001";  -- 4
            when "0101" => segOut <= "0010010";  -- 5
            when "0110" => segOut <= "0000010";  -- 6
            when "0111" => segOut <= "1111000";  -- 7
            when "1000" => segOut <= "0000000";  -- 8
            when "1001" => segOut <= "0010000";  -- 9
            when "1101" => segOut <= "0111111";  -- D
            when "1110" => segOut <= "1000110";  -- E
            when others => segOut <= "1111111";  -- blank
        end case;
    end process;

end Behavioral;
