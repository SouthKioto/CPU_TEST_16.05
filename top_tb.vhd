library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity top_tb is
end entity;

architecture behavior of top_tb is

    -- Komponent testowany
    component top
        port (
            SW   : in  std_logic_vector(9 downto 0);
            KEY  : in  std_logic_vector(1 downto 0);
            LEDR : out std_logic_vector(9 downto 0);
            HEX0 : out std_logic_vector(6 downto 0);
            HEX1 : out std_logic_vector(6 downto 0);
            HEX2 : out std_logic_vector(6 downto 0);
            HEX3 : out std_logic_vector(6 downto 0);
            HEX4 : out std_logic_vector(6 downto 0);
            HEX5 : out std_logic_vector(6 downto 0)
        );
    end component;

    -- Sygna?y testowe
    signal SW   : std_logic_vector(9 downto 0) := (others => '0');
    signal KEY  : std_logic_vector(1 downto 0) := (others => '1'); -- aktywne niskim
    signal LEDR : std_logic_vector(9 downto 0);
    signal HEX0, HEX1, HEX2, HEX3, HEX4, HEX5 : std_logic_vector(6 downto 0);

begin

    -- Instancja modu?u top
    uut: top
        port map (
            SW   => SW,
            KEY  => KEY,
            LEDR => LEDR,
            HEX0 => HEX0,
            HEX1 => HEX1,
            HEX2 => HEX2,
            HEX3 => HEX3,
            HEX4 => HEX4,
            HEX5 => HEX5
        );

    -- Proces testowy
    process
    begin
        ----------------------------------------------------------------
        -- RESET
        ----------------------------------------------------------------
        KEY(1) <= '0';  -- aktywacja resetu
        wait for 20 ns;
        KEY(1) <= '1';  -- zwolnienie resetu
        wait for 20 ns;

        ----------------------------------------------------------------
        -- 1?? Wpisz 7 do rejestru rA
        ----------------------------------------------------------------
        SW <= "0100000111";  -- DST=0 (rA), WEN=1, Sbc=00, Sbb=11=DI, S_ALU=0111=PASS BB
        KEY(0) <= '1'; wait for 10 ns;
        KEY(0) <= '0'; wait for 10 ns;  -- zbocze zegara
        KEY(0) <= '1'; wait for 20 ns;

        ----------------------------------------------------------------
        -- 2?? Wpisz 2 do rejestru rB
        ----------------------------------------------------------------
        SW <= "1100110010";  -- DST=1 (rB), WEN=1, Sbc=11=DI, Sbb=00, S_ALU=0001=PASS BC
        KEY(0) <= '1'; wait for 10 ns;
        KEY(0) <= '0'; wait for 10 ns;
        KEY(0) <= '1'; wait for 20 ns;

        ----------------------------------------------------------------
        -- 3?? Oblicz rA + rB
        ----------------------------------------------------------------
        SW <= "0001000010";  -- DST=rA, WEN=0, Sbc=01=rB, Sbb=00=rA, S_ALU=0010=ADD
        wait for 50 ns;

        ----------------------------------------------------------------
        -- Sprawdzenie wyniku (HEX0..HEX3 powinny pokaza? 0009)
        ----------------------------------------------------------------
        assert LEDR(2) = '0' and LEDR(3) = '0'
            report "TEST OK: 7 + 2 = 9"
            severity note;

        wait;
    end process;

end architecture;
