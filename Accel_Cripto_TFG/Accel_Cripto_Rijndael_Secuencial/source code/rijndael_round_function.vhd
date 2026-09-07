library ieee;
use ieee.std_logic_1164.all;
use work.rijndael_pkg.all;

entity rijndael_round_function is
    port (
        state_in    : in  std_logic_vector(127 downto 0);
        round_key   : in  std_logic_vector(127 downto 0);
        cmd         : in  std_logic; -- cifrar=0, descifrar=1
        first_round : in  std_logic; -- ronda especial = 1
        last_round  : in  std_logic; -- ronda especial = 1
        state_out   : out std_logic_vector(127 downto 0)
    );
end entity rijndael_round_function;

architecture Behavioral of rijndael_round_function is

    function add_round_key(s : state_array_t; k : std_logic_vector(127 downto 0))
        return state_array_t is
        variable rk : state_array_t := to_state(k);
        variable r  : state_array_t;
    begin
        for i in 0 to 15 loop
            r(i) := s(i) xor rk(i);
        end loop;
        return r;
    end function;

    function sub_bytes(s : state_array_t) return state_array_t is
        variable r : state_array_t;
    begin
        for i in 0 to 15 loop
            r(i) := sub_byte(s(i));
        end loop;
        return r;
    end function;

    function inv_sub_bytes(s : state_array_t) return state_array_t is
        variable r : state_array_t;
    begin
        for i in 0 to 15 loop
            r(i) := inv_sub_byte(s(i));
        end loop;
        return r;
    end function;

    function idx(row, col : integer) return integer is
    begin
        return col*4 + row;
    end function;

    function shift_rows(s : state_array_t) return state_array_t is
        variable r : state_array_t;
    begin
        for row in 0 to 3 loop
            for col in 0 to 3 loop
                -- desplazamiento a la izquierda de 'row' posiciones
                r(idx(row,col)) := s(idx(row, (col+row) mod 4));
            end loop;
        end loop;
        return r;
    end function;

    function inv_shift_rows(s : state_array_t) return state_array_t is
        variable r : state_array_t;
    begin
        for row in 0 to 3 loop
            for col in 0 to 3 loop
                -- desplazamiento a la derecha de 'row' posiciones
                r(idx(row,col)) := s(idx(row, (col-row+4) mod 4));
            end loop;
        end loop;
        return r;
    end function;

    function mix_columns(s : state_array_t) return state_array_t is
        variable r  : state_array_t;
        variable a0, a1, a2, a3 : byte_t;
    begin
        for col in 0 to 3 loop
            a0 := s(idx(0,col)); a1 := s(idx(1,col));
            a2 := s(idx(2,col)); a3 := s(idx(3,col));
            r(idx(0,col)) := gf_mul(a0,2) xor gf_mul(a1,3) xor a2 xor a3;
            r(idx(1,col)) := a0 xor gf_mul(a1,2) xor gf_mul(a2,3) xor a3;
            r(idx(2,col)) := a0 xor a1 xor gf_mul(a2,2) xor gf_mul(a3,3);
            r(idx(3,col)) := gf_mul(a0,3) xor a1 xor a2 xor gf_mul(a3,2);
        end loop;
        return r;
    end function;

    function inv_mix_columns(s : state_array_t) return state_array_t is
        variable r  : state_array_t;
        variable a0, a1, a2, a3 : byte_t;
    begin
        for col in 0 to 3 loop
            a0 := s(idx(0,col)); a1 := s(idx(1,col));
            a2 := s(idx(2,col)); a3 := s(idx(3,col));
            r(idx(0,col)) := gf_mul(a0,14) xor gf_mul(a1,11) xor gf_mul(a2,13) xor gf_mul(a3,9);
            r(idx(1,col)) := gf_mul(a0,9)  xor gf_mul(a1,14) xor gf_mul(a2,11) xor gf_mul(a3,13);
            r(idx(2,col)) := gf_mul(a0,13) xor gf_mul(a1,9)  xor gf_mul(a2,14) xor gf_mul(a3,11);
            r(idx(3,col)) := gf_mul(a0,11) xor gf_mul(a1,13) xor gf_mul(a2,9)  xor gf_mul(a3,14);
        end loop;
        return r;
    end function;

begin

    process(state_in, round_key, cmd, first_round, last_round)
        variable s : state_array_t;
    begin
        s := to_state(state_in);

        if cmd = '0' then
            -- cifrado
            if first_round = '1' then
            
                s := add_round_key(s, round_key);
            elsif last_round = '1' then
                
                s := sub_bytes(s);
                s := shift_rows(s);
                s := add_round_key(s, round_key);
            else
                s := sub_bytes(s);
                s := shift_rows(s);
                s := mix_columns(s);
                s := add_round_key(s, round_key);
            end if;
        else

            -- descifrado
            if first_round = '1' then

                s := add_round_key(s, round_key);
                s := inv_sub_bytes(s);
                s := inv_shift_rows(s);
            elsif last_round = '1' then

                s := add_round_key(s, round_key);
            else
                s := add_round_key(s, round_key);
                s := inv_mix_columns(s);
                s := inv_sub_bytes(s);
                s := inv_shift_rows(s);
            end if;
        end if;

        state_out <= to_vector(s);
    end process;

end architecture Behavioral;
