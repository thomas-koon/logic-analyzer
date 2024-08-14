library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity single_buffer_tb is
end single_buffer_tb;

architecture testbench of single_buffer_tb is

    component single_buffer
        port (
            clk       : in std_logic;
            reset     : in std_logic;
            data_in   : in std_logic_vector(7 downto 0);
            trigger   : in std_logic;
            read      : in std_logic;
            data_out  : out std_logic_vector(7 downto 0)
        );
    end component;

    signal clk       : std_logic := '0';
    signal reset     : std_logic := '0';
    signal data_in   : std_logic_vector(7 downto 0) := (others => '0');
    signal trigger   : std_logic := '0';
    signal read      : std_logic := '0';
    signal data_out  : std_logic_vector(7 downto 0);

    constant clk_period : time := 10 ns;

begin

    uut: single_buffer
        port map (
            clk       => clk,
            reset     => reset,
            data_in   => data_in,
            trigger   => trigger,
            read      => read,
            data_out  => data_out
        );

    -- Clock process
    clk_process : process
    begin
        clk <= '1';
        wait for clk_period / 2;
        clk <= '0';
        wait for clk_period / 2;
    end process clk_process;

    -- Stimulus process
    stim_proc : process
    begin
        -- Initialize
        reset <= '1';
        wait for clk_period;
        reset <= '0';
        
        -- Write AA
        data_in <= "10101010";
        trigger <= '1';

        wait for clk_period;

        -- Write BB
        data_in <= "10111011";
        trigger <= '0';
        read <= '1';
        wait for clk_period;

        -- Write CC
        data_in <= "11001100";
        read <= '1';
        wait for clk_period;

        -- Write DD
        data_in <= "11011101";
        read <= '1';
        wait for clk_period;

        -- Write EE
        data_in <= "11101110";
        read <= '1';
        wait for clk_period;

        -- Write FF
        data_in <= "11111111";
        read <= '1';
        wait for clk_period;

        read <= '1';
        wait for clk_period;
        read <= '0';
        wait for clk_period;

        read <= '1';
        wait for clk_period;
        read <= '0';
        wait for clk_period;

        read <= '1';
        wait for clk_period;
        read <= '0';
        wait for clk_period;      

        -- End Simulation
        wait;
    end process stim_proc;

end testbench;
