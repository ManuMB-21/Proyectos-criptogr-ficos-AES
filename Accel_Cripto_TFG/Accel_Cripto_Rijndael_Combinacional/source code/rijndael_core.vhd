library ieee;
use ieee.std_logic_1164.all;
use work.rijndael_pkg.all;

entity rijndael_core is
    port (
        clk        : in  std_logic;
        reset      : in  std_logic; -- alto
        start      : in  std_logic;
        cmd        : in  std_logic; -- cifrar=0, descifrar=1
        key_in     : in  std_logic_vector(127 downto 0);
        data_in    : in  std_logic_vector(127 downto 0);
        data_out   : out std_logic_vector(127 downto 0);
        done       : out std_logic
    );
end entity rijndael_core;

architecture Behavioral of rijndael_core is
    type fsm_state_t is (IDLE, RUNNING, FINISHED);
    signal fsm : fsm_state_t;

    signal state_reg   : std_logic_vector(127 downto 0);
    signal next_state  : std_logic_vector(127 downto 0);
    signal round_keys  : round_key_array_t;
    signal round_cnt   : integer range 0 to 10;
    signal round_key_sel : std_logic_vector(127 downto 0);
    signal first_round   : std_logic;
    signal last_round    : std_logic;
begin

    u_key_expansion : entity work.rijndael_key_expansion
        port map (
            key_in     => key_in,
            round_keys => round_keys
        );

    -- seleccion de la clave de ronda
    round_key_sel <= round_keys(round_cnt)      when cmd = '0' else
                      round_keys(10 - round_cnt);

    first_round <= '1' when round_cnt = 0  else '0';
    last_round  <= '1' when round_cnt = 10 else '0';

    u_round : entity work.rijndael_round_function
        port map (
            state_in    => state_reg,
            round_key   => round_key_sel,
            cmd         => cmd,
            first_round => first_round,
            last_round  => last_round,
            state_out   => next_state
        );

    process(clk, reset)
    begin
        if reset = '1' then
            fsm       <= IDLE;
            state_reg <= (others => '0');
            round_cnt <= 0;
            done      <= '0';
        elsif rising_edge(clk) then
            case fsm is
                when IDLE =>
                    done <= '0';
                    if start = '1' then
                        state_reg <= data_in;
                        round_cnt <= 0;
                        fsm       <= RUNNING;
                    end if;

                when RUNNING =>
                    state_reg <= next_state;
                    if round_cnt = 10 then
                        fsm <= FINISHED;
                    else
                        round_cnt <= round_cnt + 1;
                    end if;

                when FINISHED =>
                    done <= '1';
                    if start = '0' then
                        fsm <= IDLE;
                    end if;
            end case;
        end if;
    end process;

    data_out <= state_reg;
end architecture Behavioral;