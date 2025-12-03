library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity controller is
   port (
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
end controller;

architecture Behavioral of controller is
   type state_type is (LOCKED, UNLOCKED, LOCKOUT);
   signal state : state_type := LOCKED;

   signal prev_passcode_flag : std_logic := '0';
   signal attempt_pulse      : std_logic := '0';
   signal prev_start         : std_logic := '0';
   signal start_pulse        : std_logic := '0';

   signal wrong_attempts  : integer range 0 to 3 := 0;
   signal lockout_counter : unsigned(31 downto 0) := (others => '0');

   -- 30 seconds at 100 MHz
constant LOCKOUT_TIME : unsigned(31 downto 0) :=
  resize(to_unsigned(100_000_000, 32) * to_unsigned(30, 32), 32)(31 downto 0);

   signal done_int          : std_logic := '0';
   signal alarm_latch       : std_logic := '0';
   signal display_enable_int: std_logic := '0';

   signal blink_counter : unsigned(23 downto 0) := (others => '0');
   signal blink         : std_logic := '0';
begin
   done           <= done_int;
   alarmState     <= alarm_latch;
   display_enable <= display_enable_int;

   -- Blink generator
   process(clk, reset)
   begin
      if reset='1' then
         blink_counter <= (others => '0');
         blink         <= '0';
      elsif rising_edge(clk) then
         blink_counter <= blink_counter + 1;
         blink         <= blink_counter(22);
      end if;
   end process;

   process(clk, reset)
   begin
      if reset = '1' then
         state               <= LOCKED;
         done_int            <= '0';
         lock_cmd            <= '1';
         unlock_cmd          <= '0';
         alarm_latch         <= '0';
         wrong_attempts      <= 0;
         lockout_counter     <= (others => '0');
         prev_passcode_flag  <= '0';
         attempt_pulse       <= '0';
         prev_start          <= '0';
         start_pulse         <= '0';
         display_enable_int  <= '0';
         lockout_flag        <= '0';

      elsif rising_edge(clk) then
         attempt_pulse <= passcode_flag and not prev_passcode_flag;
         prev_passcode_flag <= passcode_flag;

         start_pulse <= start and not prev_start;
         prev_start  <= start;

         case state is
            when LOCKED =>
               done_int     <= '0';
               lock_cmd     <= '1';
               unlock_cmd   <= '0';
               lockout_flag <= '0';

               if attempt_pulse = '1' then
                  if correct_flag = '1' then
                     state          <= UNLOCKED;
                     wrong_attempts <= 0;
                     done_int       <= '1';
                     alarm_latch    <= '0';
                     lock_cmd       <= '0';
                     unlock_cmd     <= '1';
                  else
                     if wrong_attempts = 2 then
                        state           <= LOCKOUT;
                        lockout_counter <= (others => '0');
                        wrong_attempts  <= 3;
                     else
                        wrong_attempts <= wrong_attempts + 1;
                        alarm_latch    <= '1';
                     end if;
                  end if;
               elsif start_pulse = '1' then
                  display_enable_int <= not display_enable_int;
               end if;

            when UNLOCKED =>
               done_int   <= '1';
               lock_cmd   <= '0';
               unlock_cmd <= '1';
               if start_pulse = '1' then
                  state    <= LOCKED;
                  done_int <= '0';
               end if;

            when LOCKOUT =>
               done_int     <= '0';
               lock_cmd     <= '1';
               unlock_cmd   <= '0';
               alarm_latch  <= blink;
               lockout_flag <= '1';
               display_enable_int <= '0';

               if lockout_counter = LOCKOUT_TIME then
                  state            <= LOCKED;
                  wrong_attempts   <= 0;
                  lockout_counter  <= (others => '0');
                  alarm_latch      <= '0';
               else
                  lockout_counter  <= lockout_counter + 1;
                  alarm_latch      <= '1';
               end if;
         end case;
      end if;
   end process;
end Behavioral;
