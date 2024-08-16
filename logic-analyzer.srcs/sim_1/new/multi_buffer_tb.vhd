library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.multi_channel_type.all;

entity multi_buffer_tb is
end multi_buffer_tb;

architecture sim of multi_buffer_tb is

    constant CHANNELS : integer := 4;
    constant CLK_PERIOD : time := 10 ns;

    signal clk               : std_logic := '0';
    signal reset             : std_logic;
    signal all_data_in       : multi_channels_data(CHANNELS - 1 downto 0);
    signal triggers          : std_logic_vector(CHANNELS - 1 downto 0);
    signal data_out          : std_logic_vector(7 downto 0);
    signal which_channel_out : std_logic_vector(CHANNELS - 1 downto 0);

    component multi_buffer
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
    end component;

begin

    uut: multi_buffer
        generic map (
            CHANNELS => CHANNELS
        )
        port map (
            clk               => clk,
            reset             => reset,
            all_data_in       => all_data_in,
            triggers          => triggers,
            data_out          => data_out,
            which_channel_out => which_channel_out
        );

    clk_process : process
    begin
        while true loop
            clk <= '1';
            wait for CLK_PERIOD / 2;
            clk <= '0';
            wait for CLK_PERIOD / 2;
        end loop;
    end process clk_process;

    -- Stimulus process
    stim_proc: process
    begin
        -- Initialize inputs
        reset <= '1';
        all_data_in <= (others => (others => '0'));
        triggers <= (others => '0');
        wait for 20 ns;

        reset <= '0';
        wait for 20 ns;

        -- RR: 0
        all_data_in(0) <= "00000001";
        triggers(0) <= '1';

        wait for CLK_PERIOD;

        -- RR: 1
        all_data_in(1) <= "00000010";
        triggers(1) <= '1';

        wait for CLK_PERIOD;

        -- RR: 2
        all_data_in(0) <= "00000011";
        all_data_in(2) <= "00000100";
        triggers(0) <= '1';
        triggers(2) <= '1';

        wait for CLK_PERIOD;

        -- RR: 3
        triggers(3) <= '1';
        triggers(2) <= '0';
        all_data_in(3) <= "00000101";

        wait for CLK_PERIOD;

        wait for CLK_PERIOD;

        wait for CLK_PERIOD;

        wait for 50 ns;
        assert false report "Simulation finished" severity note;
        wait;
    end process stim_proc;

end sim;
