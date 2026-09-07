library ieee;
use ieee.std_logic_1164.all;
use work.serpent_pkg.all;

entity serpent_round_function is
    port (
        block_in   : in  std_logic_vector(127 downto 0);
        round_key1 : in  block128;
        round_key2 : in  block128;
        box_index  : in  integer range 0 to 7;
        cmd        : in  std_logic; -- cifrar=0, descifrar=1
        special    : in  std_logic; -- 1 = ronda diferente
        block_out  : out std_logic_vector(127 downto 0)
    );
end entity serpent_round_function;

architecture Behavioral of serpent_round_function is

    function keying(a, b : block128) return block128 is
        variable r : block128;
    begin
        for i in 0 to 3 loop
            r(i) := a(i) xor b(i);
        end loop;
        return r;
    end function;

    -- transformacion lineal
    function linear_transform(blk : block128) return block128 is
        variable b0, b1, b2, b3 : word32;
        variable r : block128;
    begin
        b0 := blk(0); b1 := blk(1); b2 := blk(2); b3 := blk(3);

        b0 := rol32(b0, 13);
        b2 := rol32(b2, 3);
        b1 := b1 xor b0 xor b2;
        b3 := b3 xor b2 xor (b0(28 downto 0) & "000");
        b1 := rol32(b1, 1);
        b3 := rol32(b3, 7);
        b0 := b0 xor b1 xor b3;
        b2 := b2 xor b3 xor (b1(24 downto 0) & "0000000");
        b0 := rol32(b0, 5);
        b2 := rol32(b2, 22);

        r(0) := b0; r(1) := b1; r(2) := b2; r(3) := b3;
        return r;
    end function;

    function linear_transform_inverse(blk : block128) return block128 is
        variable b0, b1, b2, b3 : word32;
        variable r : block128;
    begin
        b0 := blk(0); b1 := blk(1); b2 := blk(2); b3 := blk(3);

        b2 := ror32(b2, 22);
        b0 := ror32(b0, 5);
        b2 := b2 xor b3 xor (b1(24 downto 0) & "0000000");
        b0 := b0 xor b1 xor b3;
        b3 := ror32(b3, 7);
        b1 := ror32(b1, 1);
        b3 := b3 xor b2 xor (b0(28 downto 0) & "000");
        b1 := b1 xor b0 xor b2;
        b2 := ror32(b2, 3);
        b0 := ror32(b0, 13);

        r(0) := b0; r(1) := b1; r(2) := b2; r(3) := b3;
        return r;
    end function;

begin

    process(block_in, round_key1, round_key2, box_index, cmd, special)
        variable blk  : block128;
        variable sres : block128;
    begin
        blk := to_block(block_in);

                if cmd = '0' then
            -- cifrado
            blk  := keying(blk, round_key1);
            sres := sbox(box_index, blk(0), blk(1), blk(2), blk(3));
            if special = '1' then
                blk := keying(sres, round_key2); -- sin transformacion lineal
            else
                blk := linear_transform(sres);
            end if;
        else
            -- descifrado
            if special = '1' then
                blk  := keying(blk, round_key1);
                sres := inv_sbox(box_index, blk(0), blk(1), blk(2), blk(3));
                blk  := keying(sres, round_key2); -- sin transformacion lineal inversa
            else
                blk  := linear_transform_inverse(blk);
                sres := inv_sbox(box_index, blk(0), blk(1), blk(2), blk(3));
                blk  := keying(sres, round_key1);
            end if;
        end if;

        block_out <= to_vector(blk);
    end process;

end architecture Behavioral;