library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_TEXTIO.ALL;
use STD.TEXTIO.ALL;
use work.util.all;  -- Assuming you have custom types in util.all

entity input_handler is

    generic (
        CHANNELS : integer := 4
    );

    port (
        clk         : in  std_logic;
        reset       : in  std_logic;
        channels_in : in  std_logic_vector(CHANNELS - 1 downto 0); -- Channel selection vector
        data_out    : out multi_channels_data(CHANNELS - 1 downto 0) -- Output data for each channel
    );

end entity input_handler;

architecture behavioral of input_handler is
    
    -- Files for each channel
    file data_file_0 : text open read_mode is "C:/Users/thoma/OneDrive/Desktop/logic-analyzer/data/input0.txt";
    file data_file_1 : text open read_mode is "C:/Users/thoma/OneDrive/Desktop/logic-analyzer/data/input1.txt";
    file data_file_2 : text open read_mode is "C:/Users/thoma/OneDrive/Desktop/logic-analyzer/data/input2.txt";
    file data_file_3 : text open read_mode is "C:/Users/thoma/OneDrive/Desktop/logic-analyzer/data/input3.txt";
    
begin
    -- File-based input process for simulation (read from 4 files)
    process (clk, reset)
        -- Declare internal signals for each channel's data
        variable line0      : line;
        variable line1      : line;
        variable line2      : line;
        variable line3      : line;

        variable channel_data : multi_channels_data(CHANNELS - 1 downto 0) := (others => (others => '0'));
    begin

        if reset = '1' then
            
            -- Reset all channel data
            for i in 0 to CHANNELS-1 loop
                channel_data(i) := (others => '0');
            end loop;

            data_out <= (others => (others => '0'));

        elsif rising_edge(clk) then
            -- Read data from each file if channel is selected
            if channels_in(0) = '1' and not endfile(data_file_0) then
                readline(data_file_0, line0);
                read(line0, channel_data(0)); -- Read data for channel 0
            end if;
            
            if channels_in(1) = '1' and not endfile(data_file_1) then

                report "[input_handler] reading channel 1";
                readline(data_file_1, line1);
                read(line1, channel_data(1)); -- Read data for channel 1
            end if;

            if channels_in(2) = '1' and not endfile(data_file_2) then
                readline(data_file_2, line2);
                read(line2, channel_data(2)); -- Read data for channel 2
            end if;

            if channels_in(3) = '1' and not endfile(data_file_3) then
                readline(data_file_3, line3);
                read(line3, channel_data(3)); -- Read data for channel 3
            end if;

            data_out <= channel_data;  -- Output data for all channels

        end if;

    end process;

end architecture behavioral;