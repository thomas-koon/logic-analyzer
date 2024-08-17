----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 08/16/2024 12:54:55 PM
-- Design Name: 
-- Module Name: trigger_controller - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.std_logic_1164.ALL;
use work.util.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity trigger_controller is
    port ( 
        clk                : in std_logic
        reset              : in std_logic;
        all_data_in        : in multi_channels_data(CHANNELS - 1 downto 0); 
        sample_pulse       : in std_logic;

        channel_sel        : in std_logic_vector(CHANNELS - 1 downto 0);
        mode               : in std_logic_vector(2 downto 0);
        pattern_trig       : in std_logic_vector(7 downto 0);
        if_pos_edge_trig   : in std_logic;
        count_trig         : in std_logic_vector(7 downto 0);

        i2c_sda_channel    : in std_logic_vector(CHANNELS - 1 downto 0);
        i2c_scl_channel    : in std_logic_vector(CHANNELS - 1 downto 0);

        trigger            : out std_logic_vector (0 downto 0);
        stop               : out std_logic_vector (0 downto 0)
    );
end trigger_controller;

architecture behavioral of trigger_controller is

    type trigger_mode_t is (AUTO, EDGE, PATTERN, COUNTING, I2C, UART);
    type std_logic_vector_array is array(0 to NUM_CHANNELS-1) of std_logic_vector(15 downto 0);
    type boolean_array is array(0 to NUM_CHANNELS-1) of boolean;
    type integer_array is array(0 to NUM_CHANNELS-1) of integer;
    
    signal channel_modes : array(NUM_CHANNELS-1 downto 0) of trigger_mode_t;

    signal prev_byte : multi_channels_data(CHANNELS - 1 downto 0);

    -- for PATTERN mode
    signal pattern_to_match : std_logic_vector(7 downto 0);
    signal combined_prev_curr : std_logic_vector_array := (others => (others => '0'));
    signal pattern_matched : boolean_array := (others => FALSE);

    -- for COUNTING mode
    signal trigger_count : integer_array := (others => 0);
    signal curr_count : integer_array := (others => 0);
    signal count_reached : boolean_array := (others => FALSE);

    -- for I2C mode
    signal last_sda_byte   : std_logic_vector(7 downto 0) := (others => '0');
    signal curr_sda_byte   : std_logic_vector(7 downto 0) := (others => '0');
    signal last_sda_bit    : std_logic := '1';

begin

    -- assign modes based on channel_sel
    process(clk, reset)
    begin
        if reset = '1' then
            -- Reset all channels
            for i in 0 to CHANNELS-1 loop
                channel_modes(i) <= AUTO;
            end loop;
            active_channel <= 0;
        else
            -- Update active channel based on channel_sel
            active_channel <= get_channel_from_onehot(channel_sel);
            -- Assign the mode to the active channel
            case mode is
                when "000" => channel_modes(active_channel) <= AUTO;
                when "001" => channel_modes(active_channel) <= EDGE;
                when "010" => channel_modes(active_channel) <= PATTERN;
                when "011" => channel_modes(active_channel) <= COUNTING;
                when "100" => channel_modes(active_channel) <= I2C;
                when "101" => channel_modes(active_channel) <= UART;
                when "110" => channel_modes(active_channel) <= SPI;
                when others => channel_modes(active_channel) <= AUTO; -- Default case
            end case;
        end if;
    end process;

    -- trigger
    process(clk, reset)
    begin
        case channel_modes(i) is
            when AUTO =>

                -- AUTOmatically trigger
                trigger(i) <= '1';

            when EDGE =>

                -- Edge detection logic
                if if_pos_edge_trig = '1' then
                    -- Check if there is a high value in the current byte
                    if curr_byte > "00000000" then
                        trigger(i) <= '1';
                    end if;
                else
                    -- Check if there is a low value in the current byte
                    if curr_byte < "11111111" then
                        trigger(i) <= '1';
                    end if;
                end if;

            when PATTERN =>

                -- Combine previous and current byte into a 16-bit value
                -- and check for pattern
                combined_prev_curr(i) <= prev_byte(i) & all_data_in(i);
                pattern_matched(i) <= contains_pattern(combined_prev_curr(i), pattern_to_match(i));
                trigger(i) <= pattern_matched(i);
                prev_byte(i) <= all_data_in(i);
            
            when COUNTING =>

                count(i) <= count(i) + 1;
                -- Check if the count has reached the trigger value
                if count(i) = trigger_count(i) then
                    count_reached(i) <= '1';
                else
                    count_reached(i) <= '0';
                end if;

            when UART =>

                -- check for a low value
                if curr_byte < "11111111" then
                    trigger(i) <= '1';
                end if;

            when I2C =>

                -- Capture current and previous SDA bytes
                curr_scl_byte <= all_data_in(i2c_scl_channel); 
                curr_sda_byte <= all_data_in(i2c_sda_channel);
                prev_sda_byte <= curr_sda_byte;
                prev_scl_byte <= curr_scl_byte;

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
                end if;               

        end case;
                
                    
    end process;

        

    


end behavioral;
