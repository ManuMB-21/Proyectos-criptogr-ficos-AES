library ieee;
use ieee.std_logic_1164.all;
use work.rijndael_pkg.all;

entity rijndael_key_expansion is
    port (
        key_in     : in  std_logic_vector(127 downto 0);
        round_keys : out round_key_array_t
    );
end entity rijndael_key_expansion;

architecture Behavioral of rijndael_key_expansion is
    type word_array_t is array (0 to 43) of std_logic_vector(31 downto 0);

    function expand_key(k : std_logic_vector(127 downto 0)) return word_array_t is
        variable w    : word_array_t;
        variable temp : std_logic_vector(31 downto 0);
    begin

        w(0) := k(127 downto 96);
        w(1) := k(95 downto 64);
        w(2) := k(63 downto 32);
        w(3) := k(31 downto 0);
        for idx in 4 to 43 loop
            temp := w(idx-1);
            if (idx mod 4) = 0 then
                temp := sub_word(rot_word(temp)) xor (RCON(idx/4) & x"000000");
            end if;
            w(idx) := w(idx-4) xor temp;
        end loop;
        return w;
    end function;

    signal words : word_array_t;
begin
    words <= expand_key(key_in);

    -- empaquetado combinacional de las palabras
    gen_round_keys : for r in 0 to 10 generate
        round_keys(r) <= words(4*r) & words(4*r+1) & words(4*r+2) & words(4*r+3);
    end generate;
    
end architecture Behavioral;