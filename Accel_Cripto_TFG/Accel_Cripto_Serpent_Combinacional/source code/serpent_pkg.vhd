library ieee;
use ieee.std_logic_1164.all;

package serpent_pkg is

    subtype word32 is std_logic_vector(31 downto 0);
    type block128 is array (0 to 3) of word32;   -- los 4 words del bloque
    type round_key_array_t is array (0 to 32) of block128; -- 33 subclaves de 128 bits

    function to_block(v : std_logic_vector(127 downto 0)) return block128;
    function to_vector(b : block128) return std_logic_vector;

    -- rotaciones circulares de 32 bits
    function rol32(x : word32; n : integer) return word32;
    function ror32(x : word32; n : integer) return word32;

    function sbox(box_num : integer range 0 to 7;
                  a, b, c, d : word32) return block128;

    function inv_sbox(box_num : integer range 0 to 7;
                       a, b, c, d : word32) return block128;

    constant PHI : word32 := x"9e3779b9";

end package serpent_pkg;

package body serpent_pkg is

    function to_block(v : std_logic_vector(127 downto 0)) return block128 is
        variable b : block128;
    begin
        b(0) := v(31  downto  0);
        b(1) := v(63  downto 32);
        b(2) := v(95  downto 64);
        b(3) := v(127 downto 96);
        return b;
    end function;

    function to_vector(b : block128) return std_logic_vector is
    begin
        return b(3) & b(2) & b(1) & b(0);
    end function;

    function rol32(x : word32; n : integer) return word32 is
        variable r : word32;
    begin
        r := x(31-n downto 0) & x(31 downto 32-n);
        return r;
    end function;

    function ror32(x : word32; n : integer) return word32 is
        variable r : word32;
    begin
        r := x(n-1 downto 0) & x(31 downto n);
        return r;
    end function;

    -- s-boxes directas
    function sbox(box_num : integer range 0 to 7;
                  a, b, c, d : word32) return block128 is
        variable w, x, y, z : word32;
        variable t01,t02,t03,t04,t05,t06,t07,t08,t09,t10 : word32;
        variable t11,t12,t13,t14,t15,t16,t17,t18 : word32;
        variable r : block128;
    begin
        case box_num is

        when 0 =>
            t01 := b   xor c;
            t02 := a   or  d;
            t03 := a   xor b;
            z   := t02 xor t01;
            t05 := c   or  z;
            t06 := a   xor d;
            t07 := b   or  c;
            t08 := d   and t05;
            t09 := t03 and t07;
            y   := t09 xor t08;
            t11 := t09 and y;
            t12 := c   xor d;
            t13 := t07 xor t11;
            t14 := b   and t06;
            t15 := t06 xor t13;
            w   := not t15;
            t17 := w   xor t14;
            x   := t12 xor t17;

        when 1 =>
            t01 := a   or  d;
            t02 := c   xor d;
            t03 := not b;
            t04 := a   xor c;
            t05 := a   or  t03;
            t06 := d   and t04;
            t07 := t01 and t02;
            t08 := b   or  t06;
            y   := t02 xor t05;
            t10 := t07 xor t08;
            t11 := t01 xor t10;
            t12 := y   xor t11;
            t13 := b   and d;
            z   := not t10;
            x   := t13 xor t12;
            t16 := t10 or  x;
            t17 := t05 and t16;
            w   := c   xor t17;

        when 2 =>
            t01 := a   or  c;
            t02 := a   xor b;
            t03 := d   xor t01;
            w   := t02 xor t03;
            t05 := c   xor w;
            t06 := b   xor t05;
            t07 := b   or  t05;
            t08 := t01 and t06;
            t09 := t03 xor t07;
            t10 := t02 or  t09;
            x   := t10 xor t08;
            t12 := a   or  d;
            t13 := t09 xor x;
            t14 := b   xor t13;
            z   := not t09;
            y   := t12 xor t14;

        when 3 =>
            t01 := a   xor c;
            t02 := a   or  d;
            t03 := a   and d;
            t04 := t01 and t02;
            t05 := b   or  t03;
            t06 := a   and b;
            t07 := d   xor t04;
            t08 := c   or  t06;
            t09 := b   xor t07;
            t10 := d   and t05;
            t11 := t02 xor t10;
            z   := t08 xor t09;
            t13 := d   or  z;
            t14 := a   or  t07;
            t15 := b   and t13;
            y   := t08 xor t11;
            w   := t14 xor t15;
            x   := t05 xor t04;

        when 4 =>
            t01 := a   or  b;
            t02 := b   or  c;
            t03 := a   xor t02;
            t04 := b   xor d;
            t05 := d   or  t03;
            t06 := d   and t01;
            z   := t03 xor t06;
            t08 := z   and t04;
            t09 := t04 and t05;
            t10 := c   xor t06;
            t11 := b   and c;
            t12 := t04 xor t08;
            t13 := t11 or  t03;
            t14 := t10 xor t09;
            t15 := a   and t05;
            t16 := t11 or  t12;
            y   := t13 xor t08;
            x   := t15 xor t16;
            w   := not t14;

        when 5 =>
            t01 := b   xor d;
            t02 := b   or  d;
            t03 := a   and t01;
            t04 := c   xor t02;
            t05 := t03 xor t04;
            w   := not t05;
            t07 := a   xor t01;
            t08 := d   or  w;
            t09 := b   or  t05;
            t10 := d   xor t08;
            t11 := b   or  t07;
            t12 := t03 or  w;
            t13 := t07 or  t10;
            t14 := t01 xor t11;
            y   := t09 xor t13;
            x   := t07 xor t08;
            z   := t12 xor t14;

        when 6 =>
            t01 := a   and d;
            t02 := b   xor c;
            t03 := a   xor d;
            t04 := t01 xor t02;
            t05 := b   or  c;
            x   := not t04;
            t07 := t03 and t05;
            t08 := b   and x;
            t09 := a   or  c;
            t10 := t07 xor t08;
            t11 := b   or  d;
            t12 := c   xor t11;
            t13 := t09 xor t10;
            y   := not t13;
            t15 := x   and t03;
            z   := t12 xor t07;
            t17 := a   xor b;
            t18 := y   xor t15;
            w   := t17 xor t18;

        when others => -- 7
            t01 := a   and c;
            t02 := not d;
            t03 := a   and t02;
            t04 := b   or  t01;
            t05 := a   and b;
            t06 := c   xor t04;
            z   := t03 xor t06;
            t08 := c   or  z;
            t09 := d   or  t05;
            t10 := a   xor t08;
            t11 := t04 and z;
            x   := t09 xor t10;
            t13 := b   xor x;
            t14 := t01 xor x;
            t15 := c   xor t05;
            t16 := t11 or  t13;
            t17 := t02 or  t14;
            w   := t15 xor t17;
            y   := a   xor t16;

        end case;

        r(0) := w; r(1) := x; r(2) := y; r(3) := z;
        return r;
    end function;

    -- s-boxes inversas
    function inv_sbox(box_num : integer range 0 to 7;
                       a, b, c, d : word32) return block128 is
        variable w, x, y, z : word32;
        variable t01,t02,t03,t04,t05,t06,t07,t08,t09,t10 : word32;
        variable t11,t12,t13,t14,t15,t16,t17,t18 : word32;
        variable r : block128;
    begin
        case box_num is

        when 0 =>
            t01 := c   xor d;
            t02 := a   or  b;
            t03 := b   or  c;
            t04 := c   and t01;
            t05 := t02 xor t01;
            t06 := a   or  t04;
            y   := not t05;
            t08 := b   xor d;
            t09 := t03 and t08;
            t10 := d   or  y;
            x   := t09 xor t06;
            t12 := a   or  t05;
            t13 := x   xor t12;
            t14 := t03 xor t10;
            t15 := a   xor c;
            z   := t14 xor t13;
            t17 := t05 and t13;
            t18 := t14 or  t17;
            w   := t15 xor t18;

        when 1 =>
            t01 := a   xor b;
            t02 := b   or  d;
            t03 := a   and c;
            t04 := c   xor t02;
            t05 := a   or  t04;
            t06 := t01 and t05;
            t07 := d   or  t03;
            t08 := b   xor t06;
            t09 := t07 xor t06;
            t10 := t04 or  t03;
            t11 := d   and t08;
            y   := not t09;
            x   := t10 xor t11;
            t14 := a   or  y;
            t15 := t06 xor x;
            z   := t01 xor t04;
            t17 := c   xor t15;
            w   := t14 xor t17;

        when 2 =>
            t01 := a   xor d;
            t02 := c   xor d;
            t03 := a   and c;
            t04 := b   or  t02;
            w   := t01 xor t04;
            t06 := a   or  c;
            t07 := d   or  w;
            t08 := not d;
            t09 := b   and t06;
            t10 := t08 or  t03;
            t11 := b   and t07;
            t12 := t06 and t02;
            z   := t09 xor t10;
            x   := t12 xor t11;
            t15 := c   and z;
            t16 := w   xor x;
            t17 := t10 xor t15;
            y   := t16 xor t17;

        when 3 =>
            t01 := c   or  d;
            t02 := a   or  d;
            t03 := c   xor t02;
            t04 := b   xor t02;
            t05 := a   xor d;
            t06 := t04 and t03;
            t07 := b   and t01;
            y   := t05 xor t06;
            t09 := a   xor t03;
            w   := t07 xor t03;
            t11 := w   or  t05;
            t12 := t09 and t11;
            t13 := a   and y;
            t14 := t01 xor t05;
            x   := b   xor t12;
            t16 := b   or  t13;
            z   := t14 xor t16;

        when 4 =>
            t01 := b   or  d;
            t02 := c   or  d;
            t03 := a   and t01;
            t04 := b   xor t02;
            t05 := c   xor d;
            t06 := not t03;
            t07 := a   and t04;
            x   := t05 xor t07;
            t09 := x   or  t06;
            t10 := a   xor t07;
            t11 := t01 xor t09;
            t12 := d   xor t04;
            t13 := c   or  t10;
            z   := t03 xor t12;
            t15 := a   xor t04;
            y   := t11 xor t13;
            w   := t15 xor t09;

        when 5 =>
            t01 := a   and d;
            t02 := c   xor t01;
            t03 := a   xor d;
            t04 := b   and t02;
            t05 := a   and c;
            w   := t03 xor t04;
            t07 := a   and w;
            t08 := t01 xor w;
            t09 := b   or  t05;
            t10 := not b;
            x   := t08 xor t09;
            t12 := t10 or  t07;
            t13 := w   or  x;
            z   := t02 xor t12;
            t15 := t02 xor t13;
            t16 := b   xor d;
            y   := t16 xor t15;

        when 6 =>
            t01 := a   xor c;
            t02 := not c;
            t03 := b   and t01;
            t04 := b   or  t02;
            t05 := d   or  t03;
            t06 := b   xor d;
            t07 := a   and t04;
            t08 := a   or  t02;
            t09 := t07 xor t05;
            x   := t06 xor t08;
            w   := not t09;
            t12 := b   and w;
            t13 := t01 and t05;
            t14 := t01 xor t12;
            t15 := t07 xor t13;
            t16 := d   or  t02;
            t17 := a   xor x;
            z   := t17 xor t15;
            y   := t16 xor t14;

        when others => -- 7
            t01 := a   and b;
            t02 := a   or  b;
            t03 := c   or  t01;
            t04 := d   and t02;
            z   := t03 xor t04;
            t06 := b   xor t04;
            t07 := d   xor z;
            t08 := not t07;
            t09 := t06 or  t08;
            t10 := b   xor d;
            t11 := a   or  d;
            x   := a   xor t09;
            t13 := c   xor t06;
            t14 := c   and t11;
            t15 := d   or  x;
            t16 := t01 or  t10;
            w   := t13 xor t15;
            y   := t14 xor t16;

        end case;

        r(0) := w; r(1) := x; r(2) := y; r(3) := z;
        return r;
    end function;

end package body serpent_pkg;