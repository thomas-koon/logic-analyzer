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
    signal pending_mode_param : std_logic;
    signal pending_target     : std_logic;

begin

    process(clk, reset)
    begin
        if reset = '1' then

            curr_channels <= (others => '0');
            pending_mode_param <= '0';
            pending_target <= '0';
            set_mode_param <= '0';
            set_target <= '0';
            param <= (others => '0');
            channel_sel <= (others => '0');
            mode <= (others => '0');
            trigger <= (others => '0');
            stop <= (others => '0');
            channels_in <= (others => '0');

        elsif rising_edge(clk) then

            if pending_mode_param = '0' and pending_target = '0' then
                set_mode_param <= '0';
                set_target <= '0';
                param <= "00000000";
                channel_sel <= "0000";
                mode <= "000";

                case command(7:5) is

                    -- activate channels
                    when "001" =>

                        channels_in <= command(4:1);

                    -- set mode
                    when "010" =>

                        if to_integer(unsigned( command(4:3) )) < 4 then
                            channel_sel(to_integer(unsigned( command(4:3) ))) <= '1';
                            mode <= command(2:0);
                        end if;

                    -- set mode parameter
                    -- parameter set in next cycle (in the else statement)
                    when "011" =>

                        if to_integer(unsigned( command(4:3) )) < 4 then
                            channel_sel(to_integer(unsigned( command(4:3) ))) <= '1';
                            pending_mode_param <= '1';
                        end if;

                    -- set target data amount
                    when "100" =>

                        channel_sel(to_integer(unsigned( command(4:3) ))) <= '1';
                        pending_target <= '1';

                end case;

            -- if the last command was to set mode parameter
            elsif pending_mode_param = '1' and pending_target = '0' then

                set_mode_param <= '1';
                param <= command;
                pending_mode_param <= '0';

            -- if the last command was to set target parameter
            elsif pending_mode_param = '0' and pending_target = '1' then

                set_target <= '1';
                param <= command;
                pending_target <= '0';
            end if;

        end if;

    end process;




end behavioral;
