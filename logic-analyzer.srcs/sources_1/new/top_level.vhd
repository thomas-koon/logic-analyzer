library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.util.all;

entity top_level is
    generic (
        CHANNELS : integer := 4
    );
    port (
        clk         : in  std_logic;
        reset       : in  std_logic;
        command     : in  std_logic_vector(7 downto 0);
        data_out    : out std_logic_vector(7 downto 0);
        which_channel_out : out std_logic_vector(CHANNELS - 1 downto 0)
    );
end top_level;

architecture behavioral of top_level is

    -- Internal signal declarations
    signal channels_in    : std_logic_vector(CHANNELS - 1 downto 0);
    signal channel_sel    : std_logic_vector(CHANNELS - 1 downto 0);
    signal mode           : std_logic_vector(2 downto 0);
    signal set_mode_param : std_logic;
    signal set_target     : std_logic;
    signal param          : std_logic_vector(7 downto 0);
    signal trigger        : std_logic_vector(CHANNELS - 1 downto 0);
    signal stop           : std_logic_vector(CHANNELS - 1 downto 0);
    signal all_data_in    : multi_channels_data(CHANNELS - 1 downto 0);

begin

    command_handler : entity work.command_handler
        generic map (
            CHANNELS => CHANNELS
        )
        port map (
            clk            => clk,
            reset          => reset,
            command        => command,
            channels_in    => channels_in,
            channel_sel    => channel_sel,
            mode           => mode,
            set_mode_param => set_mode_param,
            set_target     => set_target,
            param          => param
        );

    input_handler : entity work.input_handler
        generic map (
            CHANNELS => CHANNELS
        )
        port map (
            clk         => clk,
            reset       => reset,
            channels_in => channels_in,
            data_out    => all_data_in
        );

    trigger_controller : entity work.trigger_controller
        generic map (
            CHANNELS => CHANNELS
        )
        port map (
            clk            => clk,
            reset          => reset,
            all_data_in    => all_data_in,
            sample_pulse   => clk,
            channels_in    => channels_in,
            channel_sel    => channel_sel,
            mode           => mode,
            set_mode_param => set_mode_param,
            set_target     => set_target,
            param          => param,
            trigger        => trigger,
            stop           => stop
        );

    multi_buffer : entity work.multi_buffer
        generic map (
            CHANNELS => CHANNELS
        )
        port map (
            clk               => clk,
            reset             => reset,
            all_data_in       => all_data_in,
            triggers          => trigger,
            stop              => stop,
            data_out          => data_out,
            which_channel_out => which_channel_out
        );

end behavioral;
