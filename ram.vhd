library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- =============================================================
-- LAB 3: Pamiec RAM z inicjalizacja w VHDL
-- (wartosci zgodne z ram_init.mif)
--
-- ModelSim Starter Edition nie obsluguje atrybutu ram_init_file
-- dlatego inicjalizacja jest bezposrednio w kodzie VHDL.
-- Na plytce Quartus uzywa MIF automatycznie.
-- =============================================================

entity ram is
    port (
        clk     : in  std_logic;
        we      : in  std_logic;
        address : in  std_logic_vector(9 downto 0);
        data    : in  std_logic_vector(15 downto 0);
        q       : out std_logic_vector(15 downto 0)
    );
end entity ram;

architecture rtl of ram is

    type mem_type is array(0 to 1023) of std_logic_vector(15 downto 0);

    signal ram_block : mem_type := (
        -- Segment 0: stale programu
        0   => x"0007",   -- adres 0 = 7        (argument 1 dodawania)
        1   => x"0002",   -- adres 1 = 2        (argument 2 dodawania)
        2   => x"0009",   -- adres 2 = 9        (oczekiwany wynik 7+2)
        3   => x"000F",   -- adres 3 = 15       (max warto?? 4-bitowa)
        4   => x"00FF",   -- adres 4 = 255      (max warto?? 8-bitowa)
        5   => x"7FFF",   -- adres 5 = 32767    (max warto?? dodatnia 16-bit)
        6   => x"8000",   -- adres 6 = -32768   (test flagi znaku S)
        7   => x"0000",   -- adres 7 = 0        (test flagi zera Z)
        -- Segment 1
        256 => x"0010",   -- adres 100h = 16
        -- Segment 2
        512 => x"0020",   -- adres 200h = 32
        -- Segment 3
        768 => x"0030",   -- adres 300h = 48
        -- reszta: zera
        others => x"0000"
    );

begin

    -- Synchroniczny zapis
    process(clk)
    begin
        if (clk'event and clk = '1') then
            if we = '1' then
                ram_block(to_integer(unsigned(address))) <= data;
            end if;
        end if;
    end process;

    -- Asynchroniczny odczyt
    q <= ram_block(to_integer(unsigned(address)));

end architecture rtl;
