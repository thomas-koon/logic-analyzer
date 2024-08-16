library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

package multi_channel_type is
    type multi_channels_data is array (natural range <>) of std_logic_vector (7 downto 0);
end package multi_channel_type;

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.multi_channel_type.all;

entity multi_buffer is

    generic (
        CHANNELS : integer := 4
    );

    port (
        clk               : in std_logic;
        reset             : in std_logic;
        all_data_in       : in multi_channels_data(CHANNELS - 1 downto 0); 
        triggers          : in std_logic_vector(CHANNELS - 1 downto 0); 
        data_out          : out std_logic_vector(7 downto 0);
        which_channel_out : out std_logic_vector(CHANNELS - 1 downto 0)
    );
end multi_buffer;

architecture behavioral of multi_buffer is

    -- Data output from each channel's buffer
    -- looped with round robin
    signal all_data_out : multi_channels_data(CHANNELS - 1 downto 0);
    signal rr_idx : integer := 0;
    signal prev_rr_idx : integer := 0;

    -- Which buffers currently triggered
    signal triggered_channels : std_logic_vector(CHANNELS - 1 downto 0);

    -- Which buffer currently being read (one-hot vector)
    signal read_signals : std_logic_vector(CHANNELS - 1 downto 0);
    signal buffer_has_data_out  : std_logic_vector(CHANNELS - 1 downto 0);

    component single_buffer
        port (
            clk       : in std_logic;
            reset     : in std_logic;
            data_in   : in std_logic_vector(7 downto 0);
            trigger   : in std_logic;
            read      : in std_logic;
            data_out  : out std_logic_vector(7 downto 0);
            out_en    : out std_logic
        );
    end component;

begin

    gen_buffers: for i in CHANNELS - 1 downto 0 generate
        buffer_instance: single_buffer
            port map (
                clk       => clk,
                reset     => reset,
                data_in   => all_data_in(i),
                trigger   => triggers(i),
                read      => read_signals(i),
                data_out  => all_data_out(i),
                out_en    => buffer_has_data_out(i)
            );
    end generate;

    round_robin : process(clk, reset)
    begin
        if reset = '1' then
            prev_rr_idx <= 0;
            rr_idx <= 0;
            read_signals <= (others => '0');
        elsif rising_edge(clk) then
            if triggered_channels(rr_idx) = '1' or triggers(rr_idx) = '1' then
                -- If triggered, set read signal for current channel only
                read_signals <= (others => '0');
                read_signals(rr_idx) <= '1';
            else
                read_signals <= (others => '0');
            end if;
            
            -- Move to next triggered channel
            if triggered_channels((rr_idx + 1) mod CHANNELS) = '1' or triggers((rr_idx + 1) mod CHANNELS) = '1' then
                -- Check the next channel in the round-robin order
                rr_idx <= (rr_idx + 1) mod CHANNELS;
            elsif triggered_channels((rr_idx + 2) mod CHANNELS) = '1' or triggers((rr_idx + 2) mod CHANNELS) = '1' then
                -- Check the second next channel in the round-robin order
                rr_idx <= (rr_idx + 2) mod CHANNELS;
            elsif triggered_channels((rr_idx + 3) mod CHANNELS) = '1' or triggers((rr_idx + 3) mod CHANNELS) = '1' then
                -- Check the third next channel in the round-robin order
                rr_idx <= (rr_idx + 3) mod CHANNELS;
            else
                -- If no triggered channels are found, keep rr_idx and disable read signals
                read_signals <= (others => '0');
            end if;

        end if;
    end process round_robin;

    output_data : process(clk, reset)
    begin
        if reset = '1' then
            data_out <= "00000000";
            which_channel_out <= (others => '0');
        elsif rising_edge(clk) then
            which_channel_out <= (others => '0');
            for i in CHANNELS - 1 downto 0 loop              
                if buffer_has_data_out(i) = '1' then
                    data_out <= all_data_out(i);
                    which_channel_out(i) <= '1';
                end if;
            end loop;
        end if;
    end process output_data;


    -- Update Triggered Channels
    set_triggers : process(clk, reset, triggers)
    begin
        if reset = '1' then
            triggered_channels <= (others => '0');
        else
            triggered_channels <= triggers;
        end if;
    end process set_triggers;

    


    

end behavioral;
