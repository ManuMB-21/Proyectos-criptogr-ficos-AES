library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Inter_uart_cripto is
    port(
        clk         : in  std_logic;
        reset       : in  std_logic;   -- reset alto

        -- Interfaz con uart_rx
        rx_data     : in  std_logic_vector(7 downto 0);
        rx_valid    : in  std_logic;

        -- Interfaz con uart_tx
        tx_start    : out std_logic;
        tx_data     : out std_logic_vector(7 downto 0);
        tx_busy     : in  std_logic;

        -- Interfaz con el core
        cmd         : out std_logic;  -- cifrar=0, descifrar=1
        key_out     : out std_logic_vector(127 downto 0);
        data_out    : out std_logic_vector(127 downto 0);
        block_ready : out std_logic;

        core_result : in  std_logic_vector(127 downto 0);
        core_done   : in  std_logic -- pulso fin
    );
end Inter_uart_cripto;

architecture Behavioral of Inter_uart_cripto is

    constant KEY_BYTES  : integer := 16;
    constant DATA_BYTES : integer := 16;

    type state_t is (
        UART_IDLE, UART_KEY, UART_DATA,
        UART_WAIT_CORE,
        UART_TX_SEND, UART_TX_WAIT
    );
    signal state : state_t := UART_IDLE;

    signal byte_cnt     : integer range 0 to KEY_BYTES-1 := 0;
    signal cmd_reg       : std_logic_vector(7 downto 0) := (others => '0');
    signal key_reg        : std_logic_vector(127 downto 0) := (others => '0');
    signal data_reg       : std_logic_vector(127 downto 0) := (others => '0');
    signal result_reg     : std_logic_vector(127 downto 0) := (others => '0');

    signal block_ready_reg : std_logic := '0';
    signal tx_start_reg    : std_logic := '0';

begin

    cmd <= cmd_reg(0);
    key_out     <= key_reg;
    data_out    <= data_reg;
    block_ready <= block_ready_reg;

    tx_start    <= tx_start_reg;

    process(clk)
    begin
        if rising_edge(clk) then

            if reset = '1' then
                state           <= UART_IDLE;
                byte_cnt        <= 0;
                block_ready_reg <= '0';
                tx_start_reg    <= '0';

            else
                -- valores por defecto (pulsos de 1 ciclo)
                block_ready_reg <= '0';
                tx_start_reg    <= '0';

                case state is

                    -- recepcion
                    when UART_IDLE =>
                        byte_cnt <= 0;
                        if rx_valid = '1' then
                            cmd_reg <= rx_data;
                            state   <= UART_KEY;
                        end if;

                    when UART_KEY =>
                        if rx_valid = '1' then
                            key_reg <= key_reg(119 downto 0) & rx_data;

                            if byte_cnt = KEY_BYTES-1 then
                                byte_cnt <= 0;
                                state    <= UART_DATA;
                            else
                                byte_cnt <= byte_cnt + 1;
                            end if;
                        end if;

                    when UART_DATA =>
                        if rx_valid = '1' then
                            data_reg <= data_reg(119 downto 0) & rx_data;

                            if byte_cnt = DATA_BYTES-1 then
                                byte_cnt        <= 0;
                                block_ready_reg <= '1';
                                state           <= UART_WAIT_CORE;
                            else
                                byte_cnt <= byte_cnt + 1;
                            end if;
                        end if;

                    -- espera core
                    when UART_WAIT_CORE =>
                        if core_done = '1' then
                            result_reg <= core_result;
                            --byte_cnt   <= 0; 
                            state      <= UART_TX_SEND;
                        end if;

                    -- transmision
                    when UART_TX_SEND =>
                        if tx_busy = '0' then
                            tx_data      <= result_reg(127 downto 120);
                            tx_start_reg <= '1';
                            state        <= UART_TX_WAIT;
                        end if;

                    when UART_TX_WAIT =>
                        if tx_busy = '1' then
                            result_reg <= result_reg(119 downto 0) & x"00";

                            if byte_cnt = DATA_BYTES-1 then
                                byte_cnt <= 0;
                                state    <= UART_IDLE;
                            else
                                byte_cnt <= byte_cnt + 1;
                                state    <= UART_TX_SEND;
                            end if;
                        end if;

                end case;
            end if;
        end if;
    end process;

end Behavioral;
