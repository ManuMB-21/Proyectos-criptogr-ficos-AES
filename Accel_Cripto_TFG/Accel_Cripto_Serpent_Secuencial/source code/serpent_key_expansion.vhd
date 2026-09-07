library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.serpent_pkg.all;

entity serpent_key_expansion is
    port (
        clk        : in  std_logic;
        reset      : in  std_logic; -- alto
        start      : in  std_logic;
        key_in     : in  std_logic_vector(127 downto 0);
        round_keys : out round_key_array_t;
        done       : out std_logic
    );
end entity serpent_key_expansion;

architecture Behavioral of serpent_key_expansion is
    -- patron ciclico de s-boxes
    type box_pattern_t is array (0 to 7) of integer range 0 to 7;
    constant BOX_PATTERN : box_pattern_t := (3,2,1,0,7,6,5,4);

    type w_array_t is array (0 to 139) of word32;
    signal raw_w : w_array_t;

    type fsm_state_t is (IDLE, EXPAND, GEN_KEYS, FINISHED);
    signal fsm : fsm_state_t;

    signal i_cnt : integer range 0 to 131;
    signal n_cnt : integer range 0 to 32;

begin

    process(clk, reset)
        variable key_words : block128;
        variable idx        : integer;
        variable sb         : block128;
    begin
        if reset = '1' then
            fsm   <= IDLE;
            i_cnt <= 0;
            n_cnt <= 0;
            done  <= '0';
        elsif rising_edge(clk) then
            case fsm is
                when IDLE =>
                    done <= '0';
                    if start = '1' then
                        raw_w(0) <= key_in(31 downto 0);
                        raw_w(1) <= key_in(63 downto 32);
                        raw_w(2) <= key_in(95 downto 64);
                        raw_w(3) <= key_in(127 downto 96);
                        
                        raw_w(4) <= x"00000001"; 
                        raw_w(5) <= x"00000000";
                        raw_w(6) <= x"00000000";
                        raw_w(7) <= x"00000000";
                        
                        i_cnt <= 0;
                        fsm   <= EXPAND;
                    end if;
                -- palabras 
                when EXPAND =>
                    idx := i_cnt + 8;
                    raw_w(idx) <= rol32(
                        raw_w(idx-8) xor raw_w(idx-5) xor raw_w(idx-3) xor raw_w(idx-1)
                        xor PHI xor std_logic_vector(to_unsigned(i_cnt, 32)),
                        11);

                    if i_cnt = 131 then
                        n_cnt <= 0;
                        fsm   <= GEN_KEYS;
                    else
                        i_cnt <= i_cnt + 1;
                    end if;
                
                -- 33 subclaves
                when GEN_KEYS =>
                    sb := sbox(BOX_PATTERN(n_cnt mod 8),
                               raw_w(8 + 4*n_cnt),
                               raw_w(8 + 4*n_cnt + 1),
                               raw_w(8 + 4*n_cnt + 2),
                               raw_w(8 + 4*n_cnt + 3));

                    round_keys(n_cnt)(0) <= sb(0);
                    round_keys(n_cnt)(1) <= sb(1);
                    round_keys(n_cnt)(2) <= sb(2);
                    round_keys(n_cnt)(3) <= sb(3);

                    if n_cnt = 32 then
                        fsm <= FINISHED;
                    else
                        n_cnt <= n_cnt + 1;
                    end if;

                when FINISHED =>
                    done <= '1';
                    if start = '0' then
                        fsm <= IDLE;
                    end if;
            end case;
        end if;
    end process;

end architecture Behavioral;