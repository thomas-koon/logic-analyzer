library IEEE;
use IEEE.std_logic_1164.ALL;
use IEEE.numeric_std.ALL;
use work.util.ALL;

entity trigger_controller_tb is
end trigger_controller_tb;

architecture behavioral of trigger_controller_tb is

    constant CLK_PERIOD : time := 20 ns;

    signal clk           : std_logic := '0';
    signal reset         : std_logic := '1';
    signal all_data_in   : multi_channels_data(3 downto 0);
    signal sample_pulse  : std_logic := '0';
    signal channels_in   : std_logic_vector(3 downto 0);
    signal channel_sel   : std_logic_vector(3 downto 0) := (others => '0');
    signal mode          : std_logic_vector(2 downto 0) := (others => '0');
    signal set_param     : std_logic := '0';
    signal param         : std_logic_vector(7 downto 0) := (others => '0');
    signal trigger       : std_logic_vector(3 downto 0);
    signal stop          : std_logic_vector(3 downto 0);

begin

    clk_process : process
    begin
        clk <= '1';
        wait for CLK_PERIOD / 2;
        clk <= '0';
        wait for CLK_PERIOD / 2;
    end process clk_process;

    uut: entity work.trigger_controller
        generic map (
            CHANNELS => 4
        )
        port map (
            clk          => clk,
            reset        => reset,
            all_data_in  => all_data_in,
            sample_pulse => sample_pulse,
            channels_in  => channels_in,
            channel_sel  => channel_sel,
            mode         => mode,
            set_param    => set_param,
            param        => param,
            trigger      => trigger,
            stop         => stop
        );

    stim_process : process
    begin
        -- Reset the UUT
        reset <= '1';
        wait for CLK_PERIOD;
        
        -- Set channel 0 to I2C
        reset <= '0';
        channel_sel <= "0001";
        mode <= "101";  -- I2C mode
        wait for CLK_PERIOD;

        -- Set channel 1 to EDGE
        channel_sel <= "0010";
        mode <= "010";  -- EDGE mode
        wait for CLK_PERIOD;

        -- Set channel 2 to PATTERN
        channel_sel <= "0100";
        mode <= "011";  -- PATTERN mode
        wait for CLK_PERIOD;

        -- Set channel 3 to COUNTING
        channel_sel <= "1000";
        mode <= "100";  -- COUNTING mode
        wait for CLK_PERIOD;

        -- No longer selecting modes
        channel_sel <= "0000";
        mode <= "000";  
        wait for CLK_PERIOD;

        -- Set channel 3's counting parameter to 4
        channel_sel <= "1000";
        set_param <= '1';
        param <= "00000100";
        wait for CLK_PERIOD;

        -- Activate channel 3
        channel_sel <= "0000";
        set_param <= '0';
        param <= "00000000";
        channels_in <= "1000";
        wait for CLK_PERIOD;

        -- Set channel 2's pattern
        channel_sel <= "0100";
        set_param <= '1';
        param <= "11111111";
        wait for CLK_PERIOD;

        -- Activate channel 2
        channel_sel <= "0000";
        set_param <= '0';
        param <= "00000000";
        channels_in <= "1100";
        wait for CLK_PERIOD;

        -- Send one half of the pattern for channel 2
        -- Set channel 1 to falling edge
        channel_sel <= "0010";
        set_param <= '1';
        param <= "00000000";
        all_data_in(2) <= "00001111";
        wait for CLK_PERIOD;

        -- Activate channel 1
        -- Send other half of pattern for channel 2
        -- No falling edge for channel 1
        set_param <= '0';
        channels_in <= "1110";
        all_data_in(2) <= "11110000";   
        all_data_in(1) <= "11111111";
        wait for CLK_PERIOD;

        -- Falling edge for channel 1
        all_data_in(1) <= "11111011";
        assert trigger(3) = '1' report "Channel 3 should trigger, but didn't." severity failure;
        wait for CLK_PERIOD;

        assert trigger(2) = '1' report "Channel 2 should trigger, but didn't." severity failure;
        assert trigger(1) = '1' report "Channel 1 should trigger, but didn't." severity failure;
        wait for CLK_PERIOD;

        -- I2C setup: Channel 1 SCL, Channel 0 SDA
        channels_in <= "0000";
        set_param <= '1';
        channel_sel <= "0001";
        param <= "00100001"; 
        wait for CLK_PERIOD;

        set_param <= '0';
        channels_in <= "0001";
        all_data_in(1) <= "11111111";   
        all_data_in(0) <= "11111111";
        wait for CLK_PERIOD;

        all_data_in(1) <= "11111111";   
        all_data_in(0) <= "11111111";
        wait for CLK_PERIOD;

        all_data_in(1) <= "11111001";   
        all_data_in(0) <= "11111111";
        wait for CLK_PERIOD;

        all_data_in(1) <= "00111111";   
        all_data_in(0) <= "11110111";
        wait for CLK_PERIOD;

        --assert trigger(0) = '1' report "Channel 0 should trigger, but didn't." severity failure;
        wait for CLK_PERIOD;

        -- Stop simulation
        wait;
    end process stim_process;

end behavioral;
