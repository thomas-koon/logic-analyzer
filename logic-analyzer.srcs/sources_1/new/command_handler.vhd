library IEEE;
use IEEE.std_logic_1164.ALL;
use IEEE.numeric_std.ALL;
use work.util.all;

entity command_handler is

    generic (
        CHANNELS : integer := 4
    );

    port ( 
        clk : in std_logic;
        reset : in std_logic;

        command : in std_logic_vector (7 downto 0);

        channels_in : out std_logic_vector (CHANNELS - 1 downto 0);
        channel_sel : out std_logic_vector (CHANNELS - 1 downto 0);
        mode : out std_logic_vector (2 downto 0);
        set_mode_param : out std_logic;
        set_target : out std_logic;
        param : out std_logic_vector (7 downto 0)
    );
end command_handler;

architecture behavioral of command_handler is

    -- waiting for the second command to be parameter (after set mode/time)
    signal pending_mode_param : std_logic;
    signal pending_target     : std_logic;

begin

    process(clk, reset)
    begin
        if reset = '1' then

            pending_mode_param <= '0';
            pending_target <= '0';
            set_mode_param <= '0';
            set_target <= '0';
            param <= (others => '0');
            channel_sel <= (others => '0');
            mode <= (others => '0');
            channels_in <= (others => '0');

        elsif rising_edge(clk) then

            if pending_mode_param = '0' and pending_target = '0' then
                set_mode_param <= '0';
                set_target <= '0';
                param <= "00000000";
                channel_sel <= "0000";
                mode <= "000";

                case command(7 downto 5) is

                    -- activate channels
                    when "001" =>

                        channels_in <= command(4 downto 1);

                    -- set mode
                    when "010" =>

                        if to_integer(unsigned( command(4 downto 3) )) < 4 then
                            channel_sel(to_integer(unsigned( command(4 downto 3) ))) <= '1';
                            mode <= command(2 downto 0);
                            pending_mode_param <= '1';
                        end if;

                    -- set target data amount
                    when "100" =>

                        channel_sel(to_integer(unsigned( command(4 downto 3) ))) <= '1';
                        pending_target <= '1';

                    when others =>

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
