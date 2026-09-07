library ieee;
use ieee.std_logic_1164.all;
use work.rijndael_pkg.all;

entity rijndael_key_expansion is
    port (
        clk        : in  std_logic;
        reset      : in  std_logic; -- alto
        start      : in  std_logic;
        key_in     : in  std_logic_vector(127 downto 0);
        round_keys : out round_key_array_t;
        done       : out std_logic
    );
end entity rijndael_key_expansion;

architecture Behavioral of rijndael_key_expansion is

    type word_array_t is array (0 to 43) of std_logic_vector(31 downto 0);
    signal w_reg : word_array_t;

    type fsm_state_t is (IDLE, EXPAND, FINISHED);
    signal fsm : fsm_state_t;
    signal idx : integer range 0 to 44;

begin

    process(clk, reset)
        variable temp : std_logic_vector(31 downto 0);
    begin
        if reset = '1' then
            fsm  <= IDLE;
            idx  <= 4;
            done <= '0';
        elsif rising_edge(clk) then
            case fsm is
                when IDLE =>
                    done <= '0';
                    if start = '1' then
                        w_reg(0) <= key_in(127 downto 96);
                        w_reg(1) <= key_in(95 downto 64);
                        w_reg(2) <= key_in(63 downto 32);
                        w_reg(3) <= key_in(31 downto 0);
                        idx      <= 4;
                        fsm      <= EXPAND;
                    end if;

                when EXPAND =>
                    temp := w_reg(idx-1);
                    if (idx mod 4) = 0 then
                        temp := sub_word(rot_word(temp)) xor (RCON(idx/4) & x"000000");
                    end if;
                    w_reg(idx) <= w_reg(idx-4) xor temp;

                    if idx = 43 then
                        fsm <= FINISHED;
                    else
                        idx <= idx + 1;
                    end if;

                when FINISHED =>
                    done <= '1';
                    if start = '0' then
                        fsm <= IDLE;
                    end if;
            end case;
        end if;
    end process;

    -- empaquetado combinacional de las palabras
    gen_round_keys : for r in 0 to 10 generate
        round_keys(r) <= w_reg(4*r) & w_reg(4*r+1) & w_reg(4*r+2) & w_reg(4*r+3);
    end generate;

end architecture Behavioral;