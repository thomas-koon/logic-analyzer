library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.util.all;  -- Assuming you have custom types in util.all

entity input_handler_tb is
end entity input_handler_tb;

architecture testbench of input_handler_tb is

    -- Component declaration for the Unit Under Test (UUT)
    component input_handler is
        generic (
            CHANNELS : integer := 4
        );
        port (
            clk         : in  std_logic;
            reset       : in  std_logic;
            channels_in : in  std_logic_vector(CHANNELS - 1 downto 0); -- Channel selection vector
            data_out    : out multi_channels_data(CHANNELS - 1 downto 0) -- Output data for each channel
        );
    end component;

    signal clk         : std_logic := '0';
    signal reset       : std_logic := '0';
    signal channels_in : std_logic_vector(3 downto 0) := (others => '0');
    signal data_out    : multi_channels_data(3 downto 0);

    -- Clock period constant
    constant clk_period : time := 10 ns;

begin

    uut: input_handler
        generic map (
            CHANNELS => 4
        )
        port map (
            clk         => clk,
            reset       => reset,
            channels_in => channels_in,
            data_out    => data_out
        );

    clk_process : process
    begin
        clk <= '0';
        wait for clk_period/2;
        clk <= '1';
        wait for clk_period/2;
    end process;

    stim_proc: process
    begin

        reset <= '1';
        channels_in <= "0000";  -- No channels selected
        wait for 20 ns;

        reset <= '0';
        wait for 20 ns;

        -- Test case 1: Select channel 0
        channels_in <= "0001";
        wait for 40 ns;

        -- Test case 2: Select channels 1 and 2
        channels_in <= "0110";
        wait for 40 ns;

        -- Test case 3: Select all channels
        channels_in <= "1111";
        wait for 40 ns;

        -- Test case 4: Reset the system
        reset <= '1';
        wait for 20 ns;
        reset <= '0';
        wait for 20 ns;

        wait;
    end process;

end architecture testbench;
