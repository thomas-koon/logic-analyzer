library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.util.all;

entity top_level_tb is
end top_level_tb;

architecture sim of top_level_tb is

    constant CHANNELS : integer := 4;
    constant CLK_PERIOD : time := 10 ns;

    signal clk                : std_logic := '0';
    signal reset              : std_logic;
    signal command            : std_logic_vector(7 downto 0);
    signal data_out           : std_logic_vector(7 downto 0);
    signal which_channel_out  : std_logic_vector(CHANNELS - 1 downto 0);

    component top_level
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
    end component;

begin

    uut: top_level
        generic map (
            CHANNELS => CHANNELS
        )
        port map (
            clk                => clk,
            reset              => reset,
            command            => command,
            data_out           => data_out,
            which_channel_out  => which_channel_out
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

    stim_proc: process
    begin
        -- Initialize inputs
        reset <= '1';
        command <= (others => '0');
        wait for 20 ns;

        reset <= '0';
        wait for 20 ns;

        -- Set mode (010) of channel 1 (01) mode to PATTERN (011)
        command <= "01001011"; 
        wait for CLK_PERIOD;

        -- Set parameter for channel 1 PATTERN
        command <= "11100111";
        wait for CLK_PERIOD;

        -- Set target data amount (100) for channel 1 (01)
        command <= "10001000";
        wait for CLK_PERIOD;

        -- Channel 1 target data amount
        command <= "00000111";
        wait for CLK_PERIOD;

        -- Set mode (010) of channel 3 (11) mode to I2C (101)
        command <= "01011101";
        wait for CLK_PERIOD;

        -- Set parameter for channel 3 I2C
        -- SCL: 0001; SDA: 1000
        command <= "00011000";
        wait for CLK_PERIOD;

        -- Set target data amount (100) for channel 3 (11)
        command <= "10011000";
        wait for CLK_PERIOD;

        -- Channel 3 target data amount
        command <= "00001000";
        wait for CLK_PERIOD;

        -- Set mode (010) of channel 0 (00) to EDGE (010)
        command <= "01000010";
        wait for CLK_PERIOD;

        -- Set parameter of channel 0 EDGE to falling edge
        command <= "00000000";
        wait for CLK_PERIOD;

        -- Set target data amount (100) for channel 0 (00)
        command <= "10000000";
        wait for CLK_PERIOD;

        -- Channel 0 target data amount;
        command <= "11111111";
        wait for CLK_PERIOD;

        -- Start channels (001) 3, 1, 0 (1011)
        command <= "00110110";
        wait for CLK_PERIOD;

        command <= "00000000";
        wait for CLK_PERIOD * 10;

        

        -- I2C set parameter SDA, SCL 

        -- Channel 3 set target data amount

        -- Channel 3 target data amount

        -- Start I2C channels

        




        wait for 50 ns;
        assert false report "Simulation finished" severity note;
        wait;
    end process stim_proc;

end sim;
