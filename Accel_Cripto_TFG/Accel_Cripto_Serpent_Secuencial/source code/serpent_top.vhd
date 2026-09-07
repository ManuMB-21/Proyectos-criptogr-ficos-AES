library ieee;
use ieee.std_logic_1164.all;

entity serpent_top is
    port (
        clk        : in  std_logic;
        reset      : in  std_logic;
        start      : in  std_logic;
        cmd        : in  std_logic; -- cifrar=0, descifrar=1
        key        : in  std_logic_vector(127 downto 0);
        data_in    : in  std_logic_vector(127 downto 0);
        data_out   : out std_logic_vector(127 downto 0);
        done       : out std_logic
    );
end entity serpent_top;

architecture Behavioral of serpent_top is
begin
    u_core : entity work.serpent_core
        port map (
            clk      => clk,
            reset    => reset,
            start    => start,
            cmd      => cmd,
            key_in   => key,
            data_in  => data_in,
            data_out => data_out,
            done     => done
        );
end architecture Behavioral;