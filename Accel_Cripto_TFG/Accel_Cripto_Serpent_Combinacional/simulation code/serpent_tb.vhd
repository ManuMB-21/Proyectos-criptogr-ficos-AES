library ieee;
use ieee.std_logic_1164.all;
use std.textio.all;
use ieee.std_logic_textio.all;

entity serpent_tb is
end entity serpent_tb;

architecture sim of serpent_tb is

    procedure report_hex(etiqueta : string; v : std_logic_vector) is
        variable l : line;
    begin
        write(l, etiqueta);
        hwrite(l, v);
        report l.all;
        deallocate(l);
    end procedure;

    signal clk      : std_logic := '0';
    signal reset    : std_logic := '0';
    signal start    : std_logic := '0';
    signal cmd      : std_logic := '0';
    signal key      : std_logic_vector(127 downto 0) := (others => '0');
    signal data_in  : std_logic_vector(127 downto 0) := (others => '0');
    signal data_out : std_logic_vector(127 downto 0);
    signal done     : std_logic;

    -- vector 1
    constant KEY1_TV        : std_logic_vector(127 downto 0) := x"00000000000000000000000000000000";
    constant PLAINTEXT1_TV  : std_logic_vector(127 downto 0) := x"80000000000000000000000000000000";
    constant CIPHERTEXT1_TV : std_logic_vector(127 downto 0) := x"10b5ffb720b8cb9002a1142b0ba2e94a";

    -- vector 2
    constant KEY2_TV        : std_logic_vector(127 downto 0) := x"00112233445566778899aabbccddeeff";
    constant PLAINTEXT2_TV  : std_logic_vector(127 downto 0) := x"0123456789abcdeffedcba9876543210";
    constant CIPHERTEXT2_TV : std_logic_vector(127 downto 0) := x"929dd890dcc881c9a7d8b94b0aa0bad5";

    constant CLK_PERIOD : time := 10 ns;
    signal sim_done : boolean := false;

begin

    dut : entity work.serpent_top
        port map (
            clk      => clk,
            reset    => reset,
            start    => start,
            cmd      => cmd,
            key      => key,
            data_in  => data_in,
            data_out => data_out,
            done     => done
        );

    clk_gen : process
    begin
        while not sim_done loop
            clk <= '0'; wait for CLK_PERIOD/2;
            clk <= '1'; wait for CLK_PERIOD/2;
        end loop;
        wait;
    end process;

    stim : process
    begin
        -- reset
        reset <= '1';
        start <= '0';
        wait for CLK_PERIOD * 3;
        reset <= '0';
        wait for CLK_PERIOD;

        --  cifrado 1
        key     <= KEY1_TV;
        data_in <= PLAINTEXT1_TV;
        cmd <= '0';
        start   <= '1';
        wait for CLK_PERIOD;
        start   <= '0';
        wait until done = '1';
        wait for CLK_PERIOD/4;  -- margen para que se estabilicen las senales
        report_hex("cifrado V1: obtenido = ", data_out);
        assert data_out = CIPHERTEXT1_TV report "FALLO en cifrado V1" severity failure;
        report "OK: cifrado V1";
        wait for CLK_PERIOD * 2;

        -- descifrado 1
        key     <= KEY1_TV;
        data_in <= CIPHERTEXT1_TV;
        cmd <= '1';
        start   <= '1';
        wait for CLK_PERIOD;
        start   <= '0';
        wait until done = '1';
        wait for CLK_PERIOD/4;
        report_hex("descifrado V1: obtenido = ", data_out);
        assert data_out = PLAINTEXT1_TV report "FALLO en descifrado V1" severity failure;
        report "OK: descifrado V1";
        wait for CLK_PERIOD * 2;

        -- cifrado 2
        key     <= KEY2_TV;
        data_in <= PLAINTEXT2_TV;
        cmd <= '0';
        start   <= '1';
        wait for CLK_PERIOD;
        start   <= '0';
        wait until done = '1';
        wait for CLK_PERIOD/4;
        report_hex("cifrado V2: obtenido = ", data_out);
        assert data_out = CIPHERTEXT2_TV report "FALLO en cifrado V2" severity failure;
        report "OK: cifrado V2";
        wait for CLK_PERIOD * 2;

        -- descifrado 2
        key     <= KEY2_TV;
        data_in <= CIPHERTEXT2_TV;
        cmd <= '1';
        start   <= '1';
        wait for CLK_PERIOD;
        start   <= '0';
        wait until done = '1';
        wait for CLK_PERIOD/4;
        report_hex("descifrado V2: obtenido = ", data_out);
        assert data_out = PLAINTEXT2_TV report "FALLO en descifrado V2" severity failure;
        report "OK: descifrado V2";

        report "TODOS LOS VECTORES DE PRUEBA DE SERPENT COINCIDEN.";
        sim_done <= true;
        wait;
    end process;

end architecture sim;