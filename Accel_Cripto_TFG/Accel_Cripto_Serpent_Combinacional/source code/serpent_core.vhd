library ieee;
use ieee.std_logic_1164.all;
use work.serpent_pkg.all;

entity serpent_core is
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
end entity serpent_core;

architecture Behavioral of serpent_core is

    type fsm_state_t is (IDLE, RUNNING, FINISHED);
    signal fsm : fsm_state_t;

    signal state_reg  : std_logic_vector(127 downto 0);
    signal next_state : std_logic_vector(127 downto 0);
    signal round_keys : round_key_array_t;

    signal step_cnt : integer range 0 to 31;

    signal box_index : integer range 0 to 7;
    signal special   : std_logic;

    signal key_idx1 : integer range 0 to 32;
    signal key_idx2 : integer range 0 to 32;

    signal round_key1_sel : block128;
    signal round_key2_sel : block128;

begin

    round_key1_sel <= round_keys(key_idx1);
    round_key2_sel <= round_keys(key_idx2);

    u_key_expansion : entity work.serpent_key_expansion
        port map (
            key_in     => key_in,
            round_keys => round_keys
        );

    process(step_cnt, cmd)
    begin
        if cmd = '0' then
            box_index <= step_cnt mod 8;
            if step_cnt = 31 then
                special <= '1';
            else
                special <= '0';
            end if;
            key_idx1 <= step_cnt;
            key_idx2 <= step_cnt + 1;
        else
            box_index <= (31 - step_cnt) mod 8;
            if step_cnt = 0 then
                special <= '1';
            else
                special <= '0';
            end if;
            if step_cnt = 0 then
                key_idx1 <= 32;
                key_idx2 <= 31;
            else
                key_idx1 <= 31 - step_cnt;
                key_idx2 <= 0;
            end if;
        end if;
    end process;

    u_round : entity work.serpent_round_function
        port map (
            block_in   => state_reg,
            round_key1 => round_key1_sel,
            round_key2 => round_key2_sel,
            box_index  => box_index,
            cmd        => cmd,
            special    => special,
            block_out  => next_state
        );

    process(clk, reset)
    begin
        if reset = '1' then
            fsm       <= IDLE;
            state_reg <= (others => '0');
            step_cnt  <= 0;
            done      <= '0';
        elsif rising_edge(clk) then
            case fsm is
                when IDLE =>
                    done <= '0';
                    if start = '1' then
                        state_reg <= data_in;
                        step_cnt  <= 0;
                        fsm       <= RUNNING;
                    end if;

                when RUNNING =>
                    state_reg <= next_state;
                    if step_cnt = 31 then
                        fsm <= FINISHED;
                    else
                        step_cnt <= step_cnt + 1;
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