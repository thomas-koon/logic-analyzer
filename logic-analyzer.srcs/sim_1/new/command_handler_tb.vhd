library IEEE;
use IEEE.std_logic_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity command_handler_tb is
end command_handler_tb;

architecture behavioral of command_handler_tb is

    component command_handler
        port (
            clk : in std_logic;
            reset : in std_logic;
            command : in std_logic_vector (7 downto 0);
            channels_in : out std_logic_vector (3 downto 0);
            channel_sel : out std_logic_vector (3 downto 0);
            mode : out std_logic_vector (2 downto 0);
            set_mode_param : out std_logic;
            set_target : out std_logic;
            param : out std_logic_vector (7 downto 0);
            trigger : out std_logic_vector (3 downto 0);
            stop : out std_logic_vector (3 downto 0)
        );
    end component;

    signal clk : std_logic := '0';
    signal reset : std_logic := '0';
    signal command : std_logic_vector(7 downto 0) := (others => '0');
    signal channels_in : std_logic_vector(3 downto 0);
    signal channel_sel : std_logic_vector(3 downto 0);
    signal mode : std_logic_vector(2 downto 0);
    signal set_mode_param : std_logic;
    signal set_target : std_logic;
    signal param : std_logic_vector(7 downto 0);
    signal trigger : std_logic_vector(3 downto 0);
    signal stop : std_logic_vector(3 downto 0);

    constant CLK_PERIOD : time := 10 ns;

begin

    uut: command_handler
        port map (
            clk => clk,
            reset => reset,
            command => command,
            channels_in => channels_in,
            channel_sel => channel_sel,
            mode => mode,
            set_mode_param => set_mode_param,
            set_target => set_target,
            param => param,
            trigger => trigger,
            stop => stop
        );

    clk_process : process
    begin
        clk <= '1';
        wait for CLK_PERIOD/2;
        clk <= '0';
        wait for CLK_PERIOD/2;
    end process;

    stim_proc: process
    begin
        -- Apply reset
        reset <= '1';
        wait for 20 ns;
        reset <= '0';
        wait for 20 ns;

        -- Test 1: Activate channels 0110 (Command: "001")
        command <= "00101100"; 
        wait for CLK_PERIOD;

        -- Test 2: Set mode (Command: "010")
        command <= "01001011"; -- Set mode for channel 1 with mode 011 PATTERN
        wait for CLK_PERIOD;

        -- Test 3: Set mode parameter (Command: "011")
        command <= "01111000"; -- Set mode parameter for channel 3
        wait for CLK_PERIOD;
        command <= "11110000"; -- Parameter for the previous mode
        wait for CLK_PERIOD;

        -- Test 4: Set target data amount (Command: "100")
        command <= "10010110"; -- Set target data amount for channel 2
        wait for CLK_PERIOD;
        command <= "00000100"; -- Target data value
        wait for CLK_PERIOD;

        -- End simulation
        wait;
    end process;

end behavioral;
