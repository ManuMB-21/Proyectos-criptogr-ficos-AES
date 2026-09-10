library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity uart_rx is
    port(
        clk       : in  std_logic;
        rx        : in  std_logic;
        data_out  : out std_logic_vector(7 downto 0);
        data_valid: out std_logic
    );
end uart_rx;

architecture Behavioral of uart_rx is
    constant CLK_FREQ  : integer := 100000000;
    constant BAUD_RATE : integer := 115200;
    constant BAUD_TICK : integer := CLK_FREQ / BAUD_RATE;

    -- sincronizador de 2 etapas para la entrada asincrona rx
    signal rx_sync1 : std_logic := '1';
    signal rx_sync2 : std_logic := '1';

    signal counter : integer := 0;
    signal bit_cnt : integer range 0 to 9 := 0;
    signal byte_rx : std_logic_vector(7 downto 0) := (others=>'0');

    type state_type is (IDLE, START, DATA, STOP);
    signal state : state_type := IDLE;
begin

    -- Doble flip-flop para evitar metaestabilidad al muestrear rx
    process(clk)
    begin
        if rising_edge(clk) then
            rx_sync1 <= rx;
            rx_sync2 <= rx_sync1;
        end if;
    end process;

    process(clk)
    begin
        if rising_edge(clk) then
            data_valid <= '0';
            case state is
            when IDLE =>
                if rx_sync2='0' then
                    counter <= BAUD_TICK/2;
                    state <= START;
                end if;
            when START =>
                if counter=0 then
                    counter <= BAUD_TICK-1;
                    bit_cnt <= 0;
                    state <= DATA;
                else
                    counter <= counter-1;
                end if;
            when DATA =>
                if counter=0 then
                    byte_rx(bit_cnt) <= rx_sync2;
                    if bit_cnt=7 then
                        state <= STOP;
                    else
                        bit_cnt <= bit_cnt+1;
                    end if;
                    counter <= BAUD_TICK-1;
                else
                    counter <= counter-1;
                end if;
            when STOP =>
                if counter=0 then
                    data_out <= byte_rx;
                    data_valid <= '1';
                    state <= IDLE;
                else
                    counter <= counter-1;
                end if;
            end case;
        end if;
    end process;

end Behavioral;
