library IEEE;
use IEEE.STD_LOGIC_1164.ALL;


entity command_handler is
    port ( 
        clk : in STD_LOGIC;
        reset : in STD_LOGIC;

        command : in STD_LOGIC_VECTOR (7 downto 0);

        channels_in : out STD_LOGIC_VECTOR (3 downto 0);
        channel_sel : out STD_LOGIC_VECTOR (3 downto 0);
        mode : out STD_LOGIC_VECTOR (2 downto 0);
        set_mode_param : out STD_LOGIC;
        set_target : out STD_LOGIC;
        param : out STD_LOGIC_VECTOR (7 downto 0);
        trigger : out STD_LOGIC_VECTOR (3 downto 0);
        stop : out STD_LOGIC_VECTOR (3 downto 0)
    );
end command_handler;

architecture behavioral of command_handler is

    -- currently running channels
    signal curr_channels : std_logic_vector(CHANNELS - 1 downto 0);

    -- waiting for the second command to be parameter (after set mode/time)
    signal pending_param : std_logic;

begin

    process(clk, reset)
    begin

    end




end behavioral;
