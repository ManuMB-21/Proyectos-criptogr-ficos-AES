library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.serpent_pkg.all;

entity serpent_key_expansion is
    port (
        key_in     : in  std_logic_vector(127 downto 0);
        round_keys : out round_key_array_t
    );
end entity serpent_key_expansion;

architecture Behavioral of serpent_key_expansion is
    -- patron ciclico de s-boxes
    type box_pattern_t is array (0 to 7) of integer range 0 to 7;
    constant BOX_PATTERN : box_pattern_t := (3,2,1,0,7,6,5,4);
    
    type w_array_t is array (0 to 139) of word32; -- raw_w(i+8) = w(i)
    
begin
    process(key_in)
        variable raw_w     : w_array_t;
        variable key_words : block128;
        variable idx       : integer;
        variable sb        : block128;
    begin

        key_words := to_block(key_in);
        raw_w(0) := key_words(0);
        raw_w(1) := key_words(1);
        raw_w(2) := key_words(2);
        raw_w(3) := key_words(3);
        raw_w(4) := x"00000001";
        raw_w(5) := x"00000000";
        raw_w(6) := x"00000000";
        raw_w(7) := x"00000000";
        
        -- palabras 
        for i in 0 to 131 loop
            idx := i + 8;
            raw_w(idx) := rol32(
                raw_w(idx-8) xor raw_w(idx-5) xor raw_w(idx-3) xor raw_w(idx-1)
                xor PHI xor std_logic_vector(to_unsigned(i, 32)),
                11);
        end loop;

        -- 33 subclaves
        for n in 0 to 32 loop
            sb := sbox(BOX_PATTERN(n mod 8),
                       raw_w(8 + 4*n),
                       raw_w(8 + 4*n + 1),
                       raw_w(8 + 4*n + 2),
                       raw_w(8 + 4*n + 3));
            round_keys(n) <= sb;
        end loop;
    end process;
end architecture Behavioral;