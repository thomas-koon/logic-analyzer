library IEEE;
use IEEE.std_logic_1164.ALL;

package util is
    -- Function to get channel index from one-hot encoded signal
    function get_channel_from_onehot(sel: std_logic_vector) return integer;

    -- Function to check if a pattern exists in a data vector
    function contains_pattern(data : std_logic_vector; pattern : std_logic_vector) return std_logic;

    -- Type definition for multi-channel data
    type multi_channels_data is array (natural range <>) of std_logic_vector (7 downto 0);
end package util;

package body util is
    function get_channel_from_onehot(sel: std_logic_vector) return integer is
    begin
        for i in sel'length - 1 downto 0 loop
            if sel(i) = '1' then
                return i;
            end if;
        end loop;
        return -1;
    end function;

    function contains_pattern(data : std_logic_vector; pattern : std_logic_vector) return std_logic is
        constant data_len : integer := data'length;
        constant pattern_len : integer := pattern'length;
    begin
        for i in (data_len - pattern_len) downto 0 loop
            if data(i + pattern_len - 1 downto i) = pattern then
                return '1';
            end if;
        end loop;
        return '0';
    end function;
    
end package body util;
