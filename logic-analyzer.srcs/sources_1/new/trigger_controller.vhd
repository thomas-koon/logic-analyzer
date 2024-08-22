library IEEE;
use IEEE.std_logic_1164.ALL;
use ieee.numeric_std.all;
use work.util.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity trigger_controller is

    generic (
        CHANNELS : integer := 4
    );

    port ( 
        clk                : in std_logic;
        reset              : in std_logic;
        all_data_in        : in multi_channels_data(CHANNELS - 1 downto 0); 
        sample_pulse       : in std_logic;

        channels_in        : in std_logic_vector(CHANNELS - 1 downto 0);
        channel_sel        : in std_logic_vector(CHANNELS - 1 downto 0);

        mode               : in std_logic_vector(2 downto 0);
        
        set_mode_param     : in std_logic;
        set_target         : in std_logic;
        param              : in std_logic_vector(7 downto 0);

        trigger            : out std_logic_vector (CHANNELS - 1 downto 0);
        stop               : out std_logic_vector (CHANNELS - 1 downto 0)
    );
end trigger_controller;

architecture behavioral of trigger_controller is

    type trigger_mode_t is (AUTO, EDGE, PATTERN, COUNTING, I2C, UART);
    type channel_byte_array is array(CHANNELS-1 downto 0) of std_logic_vector(7 downto 0);
    type channel_2byte_array is array(CHANNELS-1 downto 0) of std_logic_vector(15 downto 0);
    type boolean_array is array(CHANNELS-1 downto 0) of boolean;
    type integer_array is array(CHANNELS-1 downto 0 ) of integer;
    type mode_array is array(CHANNELS-1 downto 0) of trigger_mode_t;

    signal channel_modes : mode_array := (others => AUTO);

    -- for EDGE mode
    signal if_pos_edge_trig : std_logic_vector(CHANNELS-1 downto 0) := (others => '0');

    -- for PATTERN mode
    signal prev_curr_data : channel_2byte_array := (others => (others => '0'));
    signal prev_byte : multi_channels_data(CHANNELS - 1 downto 0) := (others => (others => '0'));
    signal pattern_to_match : channel_byte_array := (others => (others => '0'));
    signal pattern_matched : std_logic_vector(CHANNELS-1 downto 0);

    -- for COUNTING mode
    signal trigger_count : integer_array := (others => 0);
    signal curr_count : integer_array := (others => 0);
    signal count_reached : boolean_array := (others => FALSE);

    -- for I2C mode
    signal i2c_sda_channel : std_logic_vector(CHANNELS - 1 downto 0);
    signal i2c_scl_channel : std_logic_vector(CHANNELS - 1 downto 0);
    signal prev_sda_byte   : std_logic_vector(7 downto 0) := (others => '0');
    signal prev_scl_byte   : std_logic_vector(7 downto 0) := (others => '0');
    signal curr_sda_byte   : std_logic_vector(7 downto 0) := (others => '0');
    signal curr_scl_byte   : std_logic_vector(7 downto 0) := (others => '0');

    -- keep track of data received so far (decrements from target)
    signal capture_target : integer_array := (others => 0);

    -- keep track of triggered and stopped channels
    signal triggered : std_logic_vector(CHANNELS - 1 downto 0);
    signal stopped : std_logic_vector(CHANNELS - 1 downto 0);
begin

    -- assign modes based on channel_sel
    process(clk, reset)
        variable selected_channel : integer;
    begin
        if reset = '1' then
            -- Reset all channels
            for i in 0 to CHANNELS-1 loop
                channel_modes(i) <= AUTO;
            end loop;
        elsif rising_edge(clk) then
            if mode > "000" then
                selected_channel := get_channel_from_onehot(channel_sel);
                case mode is
                    when "001" => channel_modes(selected_channel) <= AUTO;
                    when "010" => channel_modes(selected_channel) <= EDGE;
                    when "011" => channel_modes(selected_channel) <= PATTERN;
                    when "100" => channel_modes(selected_channel) <= COUNTING;
                    when "101" => channel_modes(selected_channel) <= I2C;
                    when "110" => channel_modes(selected_channel) <= UART;
                    when others => channel_modes(selected_channel) <= AUTO; -- Default case
                end case;
            end if;
        end if;
    end process;

    -- configure channel mode parameters
    -- only EDGE, PATTERN, COUNTING, and I2C use parameters
    process (clk, reset)
        variable selected_channel : integer;
    begin
        if reset = '1' then

        elsif rising_edge(clk) then
            if set_mode_param = '1' then
                selected_channel := get_channel_from_onehot(channel_sel);
                case channel_modes(selected_channel) is

                    when EDGE =>
                        if_pos_edge_trig(selected_channel) <= param(0);

                    when PATTERN =>
                        report "[trigger_controller] pattern parameter set";
                        pattern_to_match(selected_channel) <= param;

                    when COUNTING =>
                        trigger_count(selected_channel) <= to_integer(unsigned(param));

                    when I2C =>
                        i2c_scl_channel <= param(7 downto 4);
                        i2c_sda_channel <= param(3 downto 0);
                    
                    when others =>

                end case;
            end if;
        end if;
    end process;

    process(clk, reset)
        variable selected_channel : integer;
    begin
        if reset = '1' then
            -- Reset stop signals and captured data
            for i in 0 to CHANNELS-1 loop
                stop(i) <= '0';
                stopped(i) <= '0';
                capture_target(i) <= 0;
            end loop;
        elsif rising_edge(clk) then
            if set_target = '1' and set_mode_param = '0' then
                selected_channel := get_channel_from_onehot(channel_sel);
                capture_target(selected_channel) <= to_integer(unsigned(param));
            end if;

            for i in 0 to CHANNELS-1 loop
                stop(i) <= '0';
                if channels_in(i) = '1' and triggered(i) = '1' and stopped(i) <= '0' then
                    if capture_target(i) > 0 then
                        capture_target(i) <= capture_target(i) - 1;
                    elsif capture_target(i) = 0 then
                        stop(i) <= '1';
                        stopped(i) <= '1';
                    end if;
                end if;
            end loop;
        end if;
    end process;

    -- trigger
    process(clk, reset)
    begin

        if reset = '1' then

            for i in CHANNELS - 1 downto 0 loop
                prev_byte(i) <= "00000000";
                pattern_matched(i) <= '0';
                trigger(i) <= '0';
                triggered(i) <= '0';
                stopped(i) <= '0';
            end loop;

        elsif rising_edge(clk) then
            for i in CHANNELS - 1 downto 0 loop
                trigger(i) <= '0';
                if channels_in(i) = '1' and triggered(i) <= '0' and stopped(i) <= '0' then
                    case channel_modes(i) is
                        when AUTO =>

                            -- AUTOmatically trigger
                            trigger(i) <= '1';
                            triggered(i) <= '1';

                        when EDGE =>

                            -- Edge detection logic
                            if if_pos_edge_trig(i) = '1' then
                                -- Check if there is a high value in the current byte
                                if all_data_in(i) > "00000000" then
                                    trigger(i) <= '1';
                                    triggered(i) <= '1';
                                end if;
                            else
                                -- Check if there is a low value in the current byte
                                if all_data_in(i) < "11111111" then
                                    trigger(i) <= '1';
                                    triggered(i) <= '1';
                                end if;
                            end if;

                        when PATTERN =>

                            -- Combine previous and current byte into a 16-bit value
                            -- and check for pattern
                            prev_curr_data(i) <= prev_byte(i) & all_data_in(i);
                            trigger(i) <= contains_pattern(prev_curr_data(i), pattern_to_match(i));
                            triggered(i) <= contains_pattern(prev_curr_data(i), pattern_to_match(i));
                            prev_byte(i) <= all_data_in(i);
                        
                        when COUNTING =>

                            -- increment count
                            if count_reached(i) = FALSE then
                                curr_count(i) <= curr_count(i) + 1;
                            end if;

                            -- Check if the curr_count has reached the trigger value
                            if curr_count(i) = trigger_count(i) and count_reached(i) = FALSE then
                                count_reached(i) <= TRUE;
                                curr_count(i) <= 0;
                                trigger(i) <= '1';
                                triggered(i) <= '1';
                            end if;

                        when UART =>

                            -- check for a low value
                            if all_data_in(i) < "11111111" then
                                trigger(i) <= '1';
                                triggered(i) <= '1';
                            end if;

                        when I2C =>

                            -- Capture current and previous SDA bytes
                            curr_scl_byte <= all_data_in(get_channel_from_onehot(i2c_scl_channel)); 
                            curr_sda_byte <= all_data_in(get_channel_from_onehot(i2c_sda_channel));

                            -- Check for SDA 1 => 0, SCL 1 => 1
                            if (curr_sda_byte(7) = '1' and curr_sda_byte(6) = '0' and curr_scl_byte(7) = '1' and curr_scl_byte(6) = '1') or
                            (curr_sda_byte(6) = '1' and curr_sda_byte(5) = '0' and curr_scl_byte(6) = '1' and curr_scl_byte(5) = '1') or
                            (curr_sda_byte(5) = '1' and curr_sda_byte(4) = '0' and curr_scl_byte(5) = '1' and curr_scl_byte(4) = '1') or
                            (curr_sda_byte(4) = '1' and curr_sda_byte(3) = '0' and curr_scl_byte(4) = '1' and curr_scl_byte(3) = '1') or
                            (curr_sda_byte(3) = '1' and curr_sda_byte(2) = '0' and curr_scl_byte(3) = '1' and curr_scl_byte(2) = '1') or
                            (curr_sda_byte(2) = '1' and curr_sda_byte(1) = '0' and curr_scl_byte(2) = '1' and curr_scl_byte(1) = '1') or
                            (curr_sda_byte(1) = '1' and curr_sda_byte(0) = '0' and curr_scl_byte(1) = '1' and curr_scl_byte(0) = '1') or
                            (prev_sda_byte(0) = '1' and curr_sda_byte(7) = '0' and prev_scl_byte(0) = '1' and curr_scl_byte(7) = '1') then
                                trigger(i) <= '1';
                                triggered(i) <= '1';
                            end if;
                            
                            prev_sda_byte <= curr_sda_byte;
                            prev_scl_byte <= curr_scl_byte;

                    end case;
                end if;
            end loop;
        end if;                    
    end process;

    

        

    


end behavioral;
