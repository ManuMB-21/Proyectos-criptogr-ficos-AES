library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity uart_top is
    port(
        CLK100MHZ : in  std_logic;
        UART_RXD  : in  std_logic;
        UART_TXD  : out std_logic;
        BTN_RESET : in  std_logic
    );
end uart_top;

architecture Behavioral of uart_top is

    -- UART - framer
    signal rx_byte       : std_logic_vector(7 downto 0);
    signal rx_byte_valid : std_logic;
    signal tx_byte       : std_logic_vector(7 downto 0);
    signal tx_start      : std_logic;
    signal tx_busy       : std_logic;

    --  framer - core criptografico
    signal cmd         : std_logic;
    signal key_128     : std_logic_vector(127 downto 0);
    signal data_128    : std_logic_vector(127 downto 0);
    signal block_ready : std_logic;
    signal core_result : std_logic_vector(127 downto 0);
    signal core_done   : std_logic;

    signal reset   : std_logic;

begin

    reset   <= BTN_RESET;

    ----------------------------------------------------------------
    RX_INST : entity work.uart_rx
    port map(
        clk        => CLK100MHZ,
        rx         => UART_RXD,
        data_out   => rx_byte,
        data_valid => rx_byte_valid
    );

    ----------------------------------------------------------------
    FRAMER_INST : entity work.Inter_uart_cripto
    port map(
        clk         => CLK100MHZ,
        reset       => reset,
        rx_data     => rx_byte,
        rx_valid    => rx_byte_valid,
        tx_start    => tx_start,
        tx_data     => tx_byte,
        tx_busy     => tx_busy,
        cmd         => cmd,
        key_out     => key_128,
        data_out    => data_128,
        block_ready => block_ready,
        core_result => core_result,
        core_done   => core_done
    );

    ----------------------------------------------------------------
    CORE_INST : entity work.rijndael_core
    port map(
        clk      => CLK100MHZ,
        reset    => reset,
        start    => block_ready,
        cmd      => cmd,
        key_in   => key_128,
        data_in  => data_128,
        data_out => core_result,
        done     => core_done
    );

    ----------------------------------------------------------------
    TX_INST : entity work.uart_tx
    port map(
        clk      => CLK100MHZ,
        start_tx => tx_start,
        data_in  => tx_byte,
        tx       => UART_TXD,
        busy     => tx_busy
    );

end Behavioral;