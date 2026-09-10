library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity uart_tx is
    port(
        clk        : in  std_logic;
        start_tx   : in  std_logic;
        data_in    : in  std_logic_vector(7 downto 0);
        tx         : out std_logic;
        busy       : out std_logic
    );
end uart_tx;

architecture Behavioral of uart_tx is

    constant CLK_FREQ  : integer := 100000000;
    constant BAUD_RATE : integer := 115200;
    constant BAUD_TICK : integer := CLK_FREQ / BAUD_RATE;

    signal counter : integer := 0;
    signal bit_cnt : integer range 0 to 9 := 0;

    signal tx_reg : std_logic := '1';
    signal bit_tx  : std_logic_vector(7 downto 0);

    type state_type is (IDLE, START, DATA, STOP);
    signal state : state_type := IDLE;

begin

tx <= tx_reg;

process(clk)
begin
    if rising_edge(clk) then

        case state is

        when IDLE =>
            busy <= '0';

            if start_tx='1' then
                bit_tx <= data_in;
                tx_reg <= '0';
                counter <= BAUD_TICK-1;
                bit_cnt <= 0;
                busy <= '1';
                state <= START;
            end if;

        when START =>
            if counter=0 then
                tx_reg <= bit_tx(0);
                counter <= BAUD_TICK-1;
                state <= DATA;
            else
                counter <= counter-1;
            end if;

        when DATA =>
            if counter=0 then

                if bit_cnt=7 then
                    tx_reg <= '1';
                    state <= STOP;
                else
                    bit_cnt <= bit_cnt + 1;
                    tx_reg <= bit_tx(bit_cnt+1);
                end if;

                counter <= BAUD_TICK-1;

            else
                counter <= counter-1;
            end if;

        when STOP =>
            if counter=0 then
                tx_reg <= '1';
                state <= IDLE;
            else
                counter <= counter-1;
            end if;

        end case;

    end if;
end process;

end Behavioral;                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    
