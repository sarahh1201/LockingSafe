library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity DisplayController is
    Port (
        clk     : in  std_logic;                          -- clock input
        DispVal : in  STD_LOGIC_VECTOR (3 downto 0);      -- input digit
        anode   : out std_logic_vector(3 downto 0);       -- digit enable
        segOut  : out STD_LOGIC_VECTOR (6 downto 0);      -- 7-seg output
        passcode_flag : out std_logic                     -- success/fail flag
    );
end DisplayController;

architecture Behavioral of DisplayController is

    type pass_true_array is array (0 to 3) of std_logic_vector(3 downto 0);
    signal pass_true : pass_true_array := (
        0 => "0001",  -- 4
        1 => "0010",  -- 3
        2 => "0011",  -- 8
        3 => "0100"   -- 7
    );

    type pass_temp_array is array (0 to 3) of std_logic_vector(3 downto 0);
    signal pass_temp : pass_temp_array := (
        0 => "0000",
        1 => "0000",
        2 => "0000",
        3 => "0000"
    );

    signal pass_index : integer range 0 to 3 := 0;
    signal pass_check : std_logic := '0';

begin

    process(clk)
    begin
        if rising_edge(clk) then
            case DispVal is
                when "0000" =>   -- 0
                    anode  <= "1110";
                    segOut <= "1000000";
                    if pass_index <= 3 then
                        pass_temp(pass_index) <= "0000";
                        pass_index <= pass_index + 1;
                    end if;

                when "0001" =>   -- 1
                    anode  <= "1110";
                    segOut <= "1111001";
                    if pass_index <= 3 then
                        pass_temp(pass_index) <= "0001";
                        pass_index <= pass_index + 1;
                    end if;

                when "0010" =>   -- 2
                    anode  <= "1110";
                    segOut <= "0100100";
                    if pass_index <= 3 then
                        pass_temp(pass_index) <= "0010";
                        pass_index <= pass_index + 1;
                    end if;

                when "0011" =>   -- 3
                    anode  <= "1110";
                    segOut <= "0110000";
                    if pass_index <= 3 then
                        pass_temp(pass_index) <= "0011";
                        pass_index <= pass_index + 1;
                    end if;

                when "0100" =>   -- 4
                    anode  <= "1110";
                    segOut <= "0011001";
                    if pass_index <= 3 then
                        pass_temp(pass_index) <= "0100";
                        pass_index <= pass_index + 1;
                    end if;

                when "0101" =>   -- 5
                    anode  <= "1110";
                    segOut <= "0010010";
                    if pass_index <= 3 then
                        pass_temp(pass_index) <= "0101";
                        pass_index <= pass_index + 1;
                    end if;

                when "0110" =>   -- 6
                    anode  <= "1110";
                    segOut <= "0000010";
                    if pass_index <= 3 then
                        pass_temp(pass_index) <= "0110";
                        pass_index <= pass_index + 1;
                    end if;

                when "0111" =>   -- 7
                    anode  <= "1110";
                    segOut <= "1111000";
                    if pass_index <= 3 then
                        pass_temp(pass_index) <= "0111";
                        pass_index <= pass_index + 1;
                    end if;

                when "1000" =>   -- 8
                    anode  <= "1110";
                    segOut <= "0000000";
                    if pass_index <= 3 then
                        pass_temp(pass_index) <= "1000";
                        pass_index <= pass_index + 1;
                    end if;

                when "1001" =>   -- 9
                    anode  <= "1110";
                    segOut <= "0010000";
                    if pass_index <= 3 then
                        pass_temp(pass_index) <= "1001";
                        pass_index <= pass_index + 1;
                    end if;

                when "1110" =>   -- E (Check passcode)
                    if (pass_temp(0) = pass_true(0) and
                        pass_temp(1) = pass_true(1) and
                        pass_temp(2) = pass_true(2) and
                        pass_temp(3) = pass_true(3)) then
                        pass_check <= '1';  -- correct
                        anode <= "0000";
                        segOut <= "1111001"; -- show "1"
                    else
                        pass_check <= '0';  -- incorrect
                        anode <= "0000";
                        segOut <= "1000000"; -- show "0"
                    end if;

                when "1111" =>   -- F (reset)
                    anode <= "0000";
                    segOut <= "0111111";  -- placeholder
                    pass_temp <= (others => (others => '0'));
                    pass_index <= 0;
                    pass_check <= '0';

                when others =>
                    anode <= "0000";
                    segOut <= "0111111";  -- default
            end case;

            -- drive the output flag
            passcode_flag <= pass_check;
        end if;
    end process;

end Behavioral;