library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity single_buffer is
    port (
        clk       : in std_logic;
        reset     : in std_logic;
        data_in   : in std_logic_vector(7 downto 0);
        trigger   : in std_logic;
        read      : in std_logic;
        data_out  : out std_logic_vector(7 downto 0);
        out_en    : out std_logic
    );
end single_buffer;

architecture behavioral of single_buffer is
    
    constant BUFFER_SIZE : integer := 800;

    -- If previously triggered
    signal triggered : boolean := FALSE;
    
    -- Buffer
    signal buf : std_logic_vector(BUFFER_SIZE - 1 downto 0) := (others => '0');
    
    -- Buffer read/write index, output
    -- Read index initialized at 40 to be one byte behind the write pointer
    signal rd_idx : integer := 0;
    signal wr_idx : integer := 0;
    signal buf_out : std_logic_vector(7 downto 0) := (others => '0');

begin

    set_triggered : process(clk, reset)
    begin
        if reset = '1' then
            triggered <= FALSE;
        elsif rising_edge(clk) then
            if trigger = '1' then
                triggered <= TRUE;
            end if;
        end if;
    end process set_triggered;

    rw_buffer : process (clk, reset)
    begin
        if reset = '1' then
            buf <= (others => '0');
            rd_idx <= 0;
            wr_idx <= 0;
        elsif rising_edge(clk) then
            if trigger = '1' or triggered = TRUE then
                -- Write the 8-bit input data to the buffer at the current index
                buf(wr_idx + 7 downto wr_idx) <= data_in;
                
                -- Increment the write index and wrap around if necessary
                wr_idx <= (wr_idx + 8) mod BUFFER_SIZE;
            end if;

            out_en <= '0';
            if read = '1' then
                buf_out <= buf(rd_idx + 7 downto rd_idx);
                rd_idx <= (rd_idx + 8) mod BUFFER_SIZE;
                out_en <= '1';
            end if;
            
        end if;
    end process rw_buffer;

    data_out <= buf_out;

end behavioral;
