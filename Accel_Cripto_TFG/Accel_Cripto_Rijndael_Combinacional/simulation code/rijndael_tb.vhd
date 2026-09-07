library ieee;
use ieee.std_logic_1164.all;
use std.textio.all;
use ieee.std_logic_textio.all;

entity rijndael_tb is
end entity rijndael_tb;

architecture sim of rijndael_tb is

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
    constant KEY1_TV        : std_logic_vector(127 downto 0) := x"000102030405060708090a0b0c0d0e0f";
    constant PLAINTEXT1_TV  : std_logic_vector(127 downto 0) := x"00112233445566778899aabbccddeeff";
    constant CIPHERTEXT1_TV : std_logic_vector(127 downto 0) := x"69c4e0d86a7b0430d8cdb78070b4c55a";

    -- vector 2
    constant KEY2_TV        : std_logic_vector(127 downto 0) := x"2b7e151628aed2a6abf7158809cf4f3c";
    constant PLAINTEXT2_TV  : std_logic_vector(127 downto 0) := x"3243f6a8885a308d313198a2e0370734";
    constant CIPHERTEXT2_TV : std_logic_vector(127 downto 0) := x"3925841d02dc09fbdc118597196a0b32";

    constant CLK_PERIOD : time := 10 ns;
    signal sim_done : boolean := false;

begin

    dut : entity work.rijndael_top
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
        wait for CLK_PERIOD;
        reset <= '0';
        wait for CLK_PERIOD;

        -- cifrado 1
        key     <= KEY1_TV;
        data_in <= PLAINTEXT1_TV;
        cmd     <= '0';
        start   <= '1';
        wait for CLK_PERIOD;
        start   <= '0';
        wait until done = '1';
        wait for CLK_PERIOD/4;
        report_hex("cifrado V1: obtenido = ", data_out);
        assert data_out = CIPHERTEXT1_TV report "FALLO en cifrado V1" severity failure;
        report "OK: cifrado V1";
        wait for CLK_PERIOD * 2;

        -- descifrado 2
        key     <= KEY1_TV;
        data_in <= CIPHERTEXT1_TV;
        cmd     <= '1';
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
        cmd     <= '0';
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
        cmd     <= '1';
        start   <= '1';
        wait for CLK_PERIOD;
        start   <= '0';
        wait until done = '1';
        wait for CLK_PERIOD/4;
        report_hex("descifrado V2: obtenido = ", data_out);
        assert data_out = PLAINTEXT2_TV report "FALLO en descifrado V2" severity failure;
        report "OK: descifrado V2";

        report "TODOS LOS VECTORES DE PRUEBA (FIPS-197 / RIJNDAEL) COINCIDEN.";
        sim_done <= true;
        wait;
    end process;

end architecture sim;