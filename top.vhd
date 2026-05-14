library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity top is
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
end entity top;

architecture rtl of top is

    ----------------------------------------------------------------
    -- KOMPONENTY
    ----------------------------------------------------------------

    component alu is
        port (
            BB    : in  std_logic_vector(15 downto 0);
            BC    : in  std_logic_vector(15 downto 0);
            S_ALU : in  std_logic_vector(3 downto 0);
            S_F   : in  std_logic;
            C_in  : in  std_logic;
            Y     : out std_logic_vector(15 downto 0);
            C     : out std_logic;
            Z     : out std_logic;
            S     : out std_logic;
            P     : out std_logic
        );
    end component;

    component register_cpu is
        port (
            clk   : in  std_logic;
            DI    : in  signed(15 downto 0);
            BA    : in  signed(15 downto 0);
            Sbb   : in  signed(3 downto 0);
            Sbc   : in  signed(3 downto 0);
            Sba   : in  signed(3 downto 0);
            Sid   : in  signed(2 downto 0);
            Sa    : in  signed(1 downto 0);
            BB    : out signed(15 downto 0);
            BC    : out signed(15 downto 0);
            ADR   : out signed(31 downto 0);
            IRout : out signed(15 downto 0)
        );
    end component;

    component busint is
        port (
            clk           : in    std_logic;
            ADR           : in    signed(31 downto 0);
            DO            : in    signed(15 downto 0);
            Smar          : in    std_logic;
            Smbr          : in    std_logic;
            WRin          : in    std_logic;
            RDin          : in    std_logic;
            AD            : out   signed(31 downto 0);
            D             : inout signed(15 downto 0);
            DI            : out   signed(15 downto 0);
            WR            : out   std_logic;
            RD            : out   std_logic;
            phys_addr_out : out   std_logic_vector(9 downto 0)
        );
    end component;

    component ram is
        port (
            clk     : in  std_logic;
            we      : in  std_logic;
            address : in  std_logic_vector(9 downto 0);
            data    : in  std_logic_vector(15 downto 0);
            q       : out std_logic_vector(15 downto 0)
        );
    end component;

    component hex_display is
        port (
            hex_in  : in  std_logic_vector(3 downto 0);
            seg_out : out std_logic_vector(6 downto 0)
        );
    end component;

    ----------------------------------------------------------------
    -- SYGNA?Y
    ----------------------------------------------------------------

    signal clk  : std_logic;
    signal mode : std_logic_vector(1 downto 0);

    -- rejestry
    signal reg_BB   : signed(15 downto 0);
    signal reg_BC   : signed(15 downto 0);
    signal reg_ADR  : signed(31 downto 0);
    signal reg_IR   : signed(15 downto 0);
    signal reg_DI   : signed(15 downto 0);
    signal reg_BA   : signed(15 downto 0);

    signal reg_Sbb  : signed(3 downto 0);
    signal reg_Sbc  : signed(3 downto 0);
    signal reg_Sba  : signed(3 downto 0);
    signal reg_Sid  : signed(2 downto 0);
    signal reg_Sa   : signed(1 downto 0);

    -- ALU
    signal alu_BB : std_logic_vector(15 downto 0);
    signal alu_BC : std_logic_vector(15 downto 0);
    signal alu_Y  : std_logic_vector(15 downto 0);

    signal alu_C  : std_logic;
    signal alu_Z  : std_logic;
    signal alu_S  : std_logic;
    signal alu_P  : std_logic;

    -- busint
    signal bus_DO    : signed(15 downto 0);
    signal bus_Smar  : std_logic;
    signal bus_Smbr  : std_logic;
    signal bus_WRin  : std_logic;
    signal bus_RDin  : std_logic;

    signal bus_AD    : signed(31 downto 0);
    signal bus_D     : signed(15 downto 0);
    signal bus_DI    : signed(15 downto 0);

    signal bus_WR    : std_logic;
    signal bus_RD    : std_logic;

    signal phys_addr : std_logic_vector(9 downto 0);

    -- RAM
    signal ram_data_out : std_logic_vector(15 downto 0);

    -- display
    signal display_data : std_logic_vector(15 downto 0);
    signal flags_nibble : std_logic_vector(3 downto 0);

    signal hex4_in : std_logic_vector(3 downto 0);
    signal hex5_in : std_logic_vector(3 downto 0);

begin

    ----------------------------------------------------------------
    -- ZEGAR
    ----------------------------------------------------------------

    clk  <= not KEY(0);
    mode <= SW(9 downto 8);

    ----------------------------------------------------------------
    -- STEROWANIE REJESTRAMI
    ----------------------------------------------------------------

    reg_Sbb <= signed(SW(7 downto 4));
    reg_Sbc <= "0011";
    reg_Sba <= "0010";
    reg_Sid <= "000";
    reg_Sa  <= "00";

    ----------------------------------------------------------------
    -- BA
    ----------------------------------------------------------------

    reg_BA <= signed(alu_Y) when mode = "00" else
              to_signed(to_integer(unsigned(SW(7 downto 0))), 16) when mode = "01" else
              bus_DI when mode = "10" else
              to_signed(to_integer(unsigned(SW(7 downto 0))), 16);

    reg_DI <= to_signed(to_integer(unsigned(SW(7 downto 0))), 16);

    ----------------------------------------------------------------
    -- BUSINT
    ----------------------------------------------------------------

    bus_DO <= reg_BB;

    bus_Smar <= '1' when (mode = "01" or mode = "10") else '0';

    bus_Smbr <= '1' when mode = "01" else '0';

    bus_WRin <= '1' when mode = "01" else '0';

    bus_RDin <= '1' when mode = "10" else '0';

    ----------------------------------------------------------------
    -- KONWERSJE
    ----------------------------------------------------------------

    alu_BB <= std_logic_vector(reg_BB);
    alu_BC <= std_logic_vector(reg_BC);

    bus_D <= signed(ram_data_out)
             when bus_RD = '1'
             else (others => 'Z');

    ----------------------------------------------------------------
    -- REGISTER FILE
    ----------------------------------------------------------------

    U_REGS : register_cpu
        port map (
            clk   => clk,
            DI    => reg_DI,
            BA    => reg_BA,
            Sbb   => reg_Sbb,
            Sbc   => reg_Sbc,
            Sba   => reg_Sba,
            Sid   => reg_Sid,
            Sa    => reg_Sa,
            BB    => reg_BB,
            BC    => reg_BC,
            ADR   => reg_ADR,
            IRout => reg_IR
        );

    ----------------------------------------------------------------
    -- ALU
    ----------------------------------------------------------------

    U_ALU : alu
        port map (
            BB    => alu_BB,
            BC    => alu_BC,
            S_ALU => SW(3 downto 0),
            S_F   => '0',
            C_in  => '0',
            Y     => alu_Y,
            C     => alu_C,
            Z     => alu_Z,
            S     => alu_S,
            P     => alu_P
        );

    ----------------------------------------------------------------
    -- BUS INTERFACE
    ----------------------------------------------------------------

    U_BUSINT : busint
        port map (
            clk           => clk,
            ADR           => reg_ADR,
            DO            => bus_DO,
            Smar          => bus_Smar,
            Smbr          => bus_Smbr,
            WRin          => bus_WRin,
            RDin          => bus_RDin,
            AD            => bus_AD,
            D             => bus_D,
            DI            => bus_DI,
            WR            => bus_WR,
            RD            => bus_RD,
            phys_addr_out => phys_addr
        );

    ----------------------------------------------------------------
    -- RAM
    ----------------------------------------------------------------

    U_RAM : ram
        port map (
            clk     => clk,
            we      => bus_WR,
            address => phys_addr,
            data    => std_logic_vector(bus_D),
            q       => ram_data_out
        );

    ----------------------------------------------------------------
    -- DISPLAY DATA
    ----------------------------------------------------------------

    display_data <= alu_Y when mode = "00" else
                    x"00" & SW(7 downto 0) when mode = "01" else
                    ram_data_out when mode = "10" else
                    std_logic_vector(reg_BB);

    flags_nibble <= alu_C & alu_Z & alu_S & alu_P;

    ----------------------------------------------------------------
    -- HEX4 / HEX5 MUX
    ----------------------------------------------------------------

    hex4_in <= flags_nibble
               when (mode = "00" or mode = "11")
               else phys_addr(3 downto 0);

    hex5_in <= SW(3 downto 0)
               when (mode = "00" or mode = "11")
               else phys_addr(7 downto 4);

    ----------------------------------------------------------------
    -- LED
    ----------------------------------------------------------------

    LEDR(7 downto 0) <= display_data(7 downto 0);
    LEDR(8)          <= bus_WR;
    LEDR(9)          <= bus_RD;

    ----------------------------------------------------------------
    -- HEX DISPLAY
    ----------------------------------------------------------------

    U_HEX0 : hex_display
        port map (
            hex_in  => display_data(3 downto 0),
            seg_out => HEX0
        );

    U_HEX1 : hex_display
        port map (
            hex_in  => display_data(7 downto 4),
            seg_out => HEX1
        );

    U_HEX2 : hex_display
        port map (
            hex_in  => display_data(11 downto 8),
            seg_out => HEX2
        );

    U_HEX3 : hex_display
        port map (
            hex_in  => display_data(15 downto 12),
            seg_out => HEX3
        );

    U_HEX4 : hex_display
        port map (
            hex_in  => hex4_in,
            seg_out => HEX4
        );

    U_HEX5 : hex_display
        port map (
            hex_in  => hex5_in,
            seg_out => HEX5
        );

end architecture rtl;
