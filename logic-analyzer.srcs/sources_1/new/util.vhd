library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

package util is
    -- Function to get channel index from one-hot encoded signal
    function get_channel_from_onehot(sel: std_logic_vector) return integer;

    -- Function to check if a pattern exists in a data vector
    function contains_pattern(data : std_logic_vector; pattern : std_logic_vector) return boolean;

    -- Type definition for multi-channel data
    type multi_channels_data is array (natural range <>) of std_logic_vector (7 downto 0);
end package util;

package body util is
    function get_channel_from_onehot(sel: std_logic_vector) return integer is
    begin
        for i in 0 to sel'length - 1 loop
            if sel(i) = '1' then
                return i;
            end if;
        end loop;
        return -1; -- Default value in case no valid channel is found
    end function;

    function contains_pattern(data : std_logic_vector; pattern : std_logic_vector) return boolean is
    begin
        for i in 0 to (data'length - pattern'length) loop
            if data(i + pattern'length - 1 downto i) = pattern then
                return true;
            end if;
        end loop;
        return false;
    end function;
end package body util;
