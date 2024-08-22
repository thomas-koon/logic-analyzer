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

        -- Command 010: set channel 1 (01) mode to PATTERN (011)
        command <= "01001011"; 
        wait for CLK_PERIOD;

        -- Channel 1 set PATTERN mode parameter
        command <= "01101000";
        wait for CLK_PERIOD;

        -- Channel 1 parameter
        command <= "11100111";
        wait for CLK_PERIOD;

        -- Channel 1 set target data amount
        command <= "10001000";
        wait for CLK_PERIOD;

        -- Channel 1 target data amount
        command <= "00000111";
        wait for CLK_PERIOD;

        -- Start channel 1
        command <= "00100100";
        wait for CLK_PERIOD;

        command <= "00000000";
        wait for CLK_PERIOD * 15;





        wait for 50 ns;
        assert false report "Simulation finished" severity note;
        wait;
    end process stim_proc;

end sim;
