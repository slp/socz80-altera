--+-----------------------------------+-------------------------------------+--
--|                      ___   ___    | (c) 2013-2014 William R Sowerbutts  |--
--|   ___  ___   ___ ___( _ ) / _ \   | will@sowerbutts.com                 |--
--|  / __|/ _ \ / __|_  / _ \| | | |  |                                     |--
--|  \__ \ (_) | (__ / / (_) | |_| |  | A Z80 FPGA computer, just for fun   |--
--|  |___/\___/ \___/___\___/ \___/   |                                     |--
--|                                   |              http://sowerbutts.com/ |--
--+-----------------------------------+-------------------------------------+--
--| Top level module: connects modules to each other and the outside world  |--
--+-------------------------------------------------------------------------+--
--
-- See README.txt for more details
--

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.T80_Pack.ALL;

entity top_level is
    Port (
        CLOCK_50          : in    std_logic;
        LEDG              : out   std_logic_vector(9 downto 0);
        BUTTON            : in    std_logic_vector(2 downto 0);
        SW                : in    std_logic_vector(9 downto 0);

        -- UART0 (to MAX3232 level shifter chip, hardware flow control)
        UART_RXD           : in    std_logic;
        UART_TXD           : out   std_logic;

        -- GPIOs
        GPIO1_D            : inout    std_logic_vector(31 downto 0);
        GPIO0_D            : inout    std_logic_vector(31 downto 0);

        -- 7-SEG Display
        HEX0_D:  out   std_logic_vector(6 downto 0);
        --HEX0_DP: out   std_logic;
        HEX1_D:  out   std_logic_vector(6 downto 0);
        --HEX1_DP: out   std_logic;
        HEX2_D:  out   std_logic_vector(6 downto 0);
        --HEX2_DP: out   std_logic;
        HEX3_D:  out   std_logic_vector(6 downto 0);
        --sHEX3_DP: out   std_logic

        -- SD card socket
        SD_CLK  : out std_logic;
        SD_CMD  : in std_logic;
        SD_DAT0 : out std_logic;
        SD_DAT3 : out std_logic;
        SD_WP_N : in std_logic;

        -- SDRAM chip
        DRAM_CLK            : out   std_logic;
        DRAM_CKE            : out   std_logic;
        DRAM_CS_N           : out   std_logic;
        DRAM_RAS_N          : out   std_logic;
        DRAM_CAS_N          : out   std_logic;
        DRAM_WE_N           : out   std_logic;
        DRAM_DQM            : out   std_logic_vector( 1 downto 0);
        DRAM_ADDR           : out   std_logic_vector (12 downto 0);
        DRAM_BA             : out   std_logic_vector( 1 downto 0);
        DRAM_DQ             : inout std_logic_vector (15 downto 0)
    );
end top_level;

architecture Behavioral of top_level is
    constant clk_freq_mhz        : natural := 50; -- this is the frequency which the PLL outputs, in MHz.

    -- SDRAM configuration
    constant sdram_address_width : natural := 24;
    constant sdram_column_bits   : natural := 9;
    constant cycles_per_refresh  : natural := (64000*clk_freq_mhz)/8192-1;


    -- For simulation, we don't need a long init stage. but for real DRAM we need approx 101us.
    -- The constant below has a different value when interpreted by the synthesis and simulator
    -- tools in order to achieve the desired timing in each.
    constant sdram_startup_cycles: natural := 101 * clk_freq_mhz
    -- pragma translate_off
    - 10000 -- reduce the value the simulator uses
    -- pragma translate_on
    ;

    -- signals for clocking
    signal clk_feedback         : std_logic;  -- PLL clock feedback
    signal clk_unbuffered       : std_logic;  -- unbuffered system clock
    signal clk                  : std_logic;  -- buffered system clock (all logic should be clocked by this)

    -- console latch
    signal console_select_clk1  : std_logic;
    signal console_select_sync  : std_logic;
    signal swap_uart01          : std_logic := '0';

    -- system reset signals
    signal power_on_reset       : std_logic_vector(1 downto 0) := (others => '1');
    signal system_reset         : std_logic;
    signal reset_button_clk1    : std_logic;
    signal reset_button_sync    : std_logic; -- reset button signal, synchronised to our clock
    signal reset_request_uart   : std_logic; -- reset request signal from FTDI UART (when you send "!~!~!~" to the UART, this line is asserted)

    -- CPU control
    signal coldboot             : std_logic;
    signal cpu_clk_enable       : std_logic;
    signal cpu_m1_cycle         : std_logic;
    signal cpu_req_mem          : std_logic;
    signal cpu_req_io           : std_logic;
    signal req_mem              : std_logic;
    signal req_io               : std_logic;
    signal req_read             : std_logic;
    signal req_write            : std_logic;
    signal virtual_address      : std_logic_vector(15 downto 0);
    signal physical_address     : std_logic_vector(25 downto 0);
    signal mem_wait             : std_logic;
    signal cpu_wait             : std_logic;
    signal dram_wait            : std_logic;
    signal mmu_wait             : std_logic;
    signal spimaster0_wait      : std_logic;
    signal spimaster1_wait      : std_logic;

    -- chip selects
    signal mmu_cs               : std_logic;
    signal rom_cs               : std_logic;
    signal sram_cs              : std_logic;
    signal dram_cs              : std_logic;
    signal uartA_cs             : std_logic;
    signal uartB_cs             : std_logic;
    signal uart0_cs             : std_logic;
    signal uart1_cs             : std_logic;
    signal timer_cs             : std_logic;
    signal spimaster0_cs        : std_logic;
    signal spimaster1_cs        : std_logic;
    signal clkscale_cs          : std_logic;
    signal gpio_cs              : std_logic;

    -- data bus
    signal cpu_data_in          : std_logic_vector(7 downto 0);
    signal cpu_data_out         : std_logic_vector(7 downto 0);
    signal rom_data_out         : std_logic_vector(7 downto 0);
    signal sram_data_out        : std_logic_vector(7 downto 0);
    signal dram_data_out        : std_logic_vector(7 downto 0);
    signal uart0_data_out       : std_logic_vector(7 downto 0);
    signal uart1_data_out       : std_logic_vector(7 downto 0);
    signal timer_data_out       : std_logic_vector(7 downto 0);
    signal spimaster0_data_out  : std_logic_vector(7 downto 0);
    signal spimaster1_data_out  : std_logic_vector(7 downto 0);
    signal mmu_data_out         : std_logic_vector(7 downto 0);
    signal clkscale_out         : std_logic_vector(7 downto 0);
    signal gpio_data_out        : std_logic_vector(7 downto 0);

    -- GPIO
    signal gpio_input           : std_logic_vector(7 downto 0);
    signal gpio_output          : std_logic_vector(7 downto 0);
    signal gpio_bank0_input     : std_logic_vector(31 downto 0);
    signal gpio_bank0_output    : std_logic_vector(31 downto 0);
    signal gpio_bank1_input     : std_logic_vector(31 downto 0);
    signal gpio_bank1_output    : std_logic_vector(31 downto 0);

    -- Interrupts
    signal cpu_interrupt_in     : std_logic;
    signal timer_interrupt      : std_logic;
    signal uart0_interrupt      : std_logic;
    signal uart1_interrupt      : std_logic;

begin
    -- Hold CPU reset high for 8 clock cycles on startup,
    -- and when the user presses their reset button.
    process(clk)
    begin
        if rising_edge(clk) then
            -- Xilinx advises using two flip-flops are used to bring external
            -- signals which feed control logic into our clock domain.
            reset_button_clk1 <= not BUTTON(0);
            reset_button_sync <= reset_button_clk1;
            console_select_clk1 <= SW(9);
            console_select_sync <= console_select_clk1;

            -- reset the system when requested
            if (power_on_reset(0) = '1' or reset_button_sync = '1' or reset_request_uart = '1') then
                system_reset <= '1';
            else
                system_reset <= '0';
            end if;

            -- shift 0s into the power_on_reset shift register from the MSB
            power_on_reset <= '0' & power_on_reset(power_on_reset'length-1 downto 1);

            -- During reset, latch the console select jumper. This is used to
            -- optionally swap over the UART roles and move the system console to
            -- the second serial port on the IO board.
            if system_reset = '1' then
                swap_uart01 <= console_select_sync;
            else
                swap_uart01 <= swap_uart01;
            end if;
        end if;
    end process;

    -- GPIO input signal routing
    gpio_input(0) <= SW(0);
    gpio_input(1) <= SW(1);
    gpio_input(2) <= SW(2);
    gpio_input(3) <= SW(3);
    gpio_input(4) <= SW(4);
    gpio_input(5) <= SW(5);
    gpio_input(6) <= swap_uart01;
    gpio_input(7) <= coldboot;

    -- GPIO output signal routing
    LEDG(0) <= gpio_output(0);
    LEDG(1) <= gpio_output(1);
    LEDG(2) <= gpio_output(2);
    LEDG(3) <= gpio_output(3);
    LEDG(4) <= gpio_output(4);
    LEDG(5) <= gpio_output(5);
    LEDG(6) <= gpio_output(6);
    LEDG(7) <= gpio_output(7);

    -- User LED (LED1) on Papilio Pro indicates when the CPU is being asked to wait (eg by the SDRAM cache)
    LEDG(9) <= cpu_wait;

    --
    LEDG(8) <= clk or not(BUTTON(2));

    -- Interrupt signal for the CPU
    cpu_interrupt_in <= (timer_interrupt or uart0_interrupt or uart1_interrupt);

    -- 7 Seg
    seg0: entity work.DE0_SEG7 port map(virtual_address(3 downto 0), HEX0_D);
    seg1: entity work.DE0_SEG7 port map(virtual_address(7 downto 4), HEX1_D);
    seg2: entity work.DE0_SEG7 port map(virtual_address(11 downto 8), HEX2_D);
    seg3: entity work.DE0_SEG7 port map(virtual_address(15 downto 12), HEX3_D);

    -- Z80 CPU core
    cpu: entity work.Z80cpu
    port map (
                 reset => system_reset,
                 clk => clk,
                 clk_enable => cpu_clk_enable,
                 m1_cycle => cpu_m1_cycle,
                 interrupt => cpu_interrupt_in,
                 nmi => '0',
                 req_mem => cpu_req_mem,
                 req_io => cpu_req_io,
                 req_read => req_read,
                 req_write => req_write,
                 mem_wait => cpu_wait,
                 address => virtual_address,
                 data_in => cpu_data_in,
                 data_out => cpu_data_out
             );

    -- Memory management unit
    mmu: entity work.MMU
    port map (
                reset => system_reset,
                clk => clk,
                address_in => virtual_address,
                address_out => physical_address,
                cpu_data_in => cpu_data_out,
                cpu_data_out => mmu_data_out,
                req_mem_in => cpu_req_mem,
                req_io_in  => cpu_req_io,
                req_mem_out => req_mem,
                req_io_out => req_io,
                req_read => req_read,
                req_write => req_write,
                io_cs => mmu_cs,
                cpu_wait => mmu_wait,
                access_violated => open -- for now!!
            );

    -- This process determines which IO or memory device the CPU is addressing
    -- and asserts the appropriate chip select signals.
    cs_process: process(req_mem, req_io, physical_address, virtual_address, uartA_cs, uartB_cs, swap_uart01)
    begin
        -- memory chip selects: default to unselected
        rom_cs   <= '0';
        sram_cs  <= '0';
        dram_cs  <= '0';

        -- io chip selects: default to unselected
        uartA_cs      <= '0';
        uartB_cs      <= '0';
        mmu_cs        <= '0';
        timer_cs      <= '0';
        spimaster0_cs <= '0';
        spimaster1_cs <= '0';
        clkscale_cs   <= '0';
        gpio_cs       <= '0';

        -- memory address decoding
        -- address space is organised as:
        -- 0x0 000 000 - 0x0 FFF FFF  16MB DRAM (cached)    (mapped to 8MB DRAM twice)
        -- 0x1 000 000 - 0x1 FFF FFF  16MB DRAM (uncached)  (mapped to 8MB DRAM twice)
        -- 0x2 000 000 - 0x2 000 FFF   4KB monitor ROM      (FPGA block RAM)
        -- 0x2 001 000 - 0x2 001 FFF   4KB SRAM             (FPGA block RAM)
        -- 0x2 002 000 - 0x3 FFF FFF  unused space for future expansion
        if physical_address(25) = '0' then
            -- bottom 32MB: DRAM handles this
            dram_cs <= req_mem;
        else
            -- top 32MB: other memory devices
            case physical_address(24 downto 12) is
                when "0000000000000" =>  rom_cs <= req_mem;
                when "0000000000001" => sram_cs <= req_mem;
                when others => -- undecoded memory space
            end case;
        end if;

        -- IO address decoding
        case virtual_address(7 downto 3) is
            when "00000" => uartA_cs            <= req_io;  -- 00 ... 07
            when "00010" => timer_cs            <= req_io;  -- 10 ... 17
            when "00011" => spimaster0_cs       <= req_io;  -- 18 ... 1F
            when "00100" => gpio_cs             <= req_io;  -- 20 ... 27
            when "00101" => uartB_cs            <= req_io;  -- 28 ... 2F
            when "00110" => spimaster1_cs       <= req_io;  -- 30 ... 37
                                                            -- unused ports
            when "11110" => clkscale_cs         <= req_io;  -- F0 ... F7
            when "11111" => mmu_cs              <= req_io;  -- F8 ... FF
            when others =>
        end case;

        -- send the UART chip select to the appropriate UART depending
        -- on whether they have been swapped over or not.
        if swap_uart01 = '0' then
            uart0_cs <= uartB_cs;
            uart1_cs <= uartA_cs;
        else
            uart0_cs <= uartA_cs;
            uart1_cs <= uartB_cs;
        end if;
    end process;

    -- the selected memory device can request the CPU to wait
    mem_wait <=
       dram_wait       when dram_cs='1' else
       spimaster0_wait when spimaster0_cs='1' else
       spimaster1_wait when spimaster1_cs='1' else
       '0';

    -- the MMU can, at any time, request the CPU wait (this is used when
    -- translating IO to memory requests, to implement a wait state for
    -- the "17th page")
    cpu_wait <= (mem_wait or mmu_wait);

    -- input mux for CPU data bus
    cpu_data_in <=
       rom_data_out        when        rom_cs='1' else
       dram_data_out       when       dram_cs='1' else
       sram_data_out       when       sram_cs='1' else
       uart0_data_out      when      uart0_cs='1' else
       uart1_data_out      when      uart1_cs='1' else
       timer_data_out      when      timer_cs='1' else
       mmu_data_out        when        mmu_cs='1' else
       spimaster0_data_out when spimaster0_cs='1' else
       spimaster1_data_out when spimaster1_cs='1' else
       clkscale_out        when   clkscale_cs='1' else
       gpio_data_out       when       gpio_cs='1' else
       rom_data_out; -- default case

   dram: entity work.DRAM
   generic map(
               sdram_address_width => sdram_address_width,
               sdram_column_bits   => sdram_column_bits,
               sdram_startup_cycles=> sdram_startup_cycles,
               cycles_per_refresh  => cycles_per_refresh
              )
   port map(
               clk             => clk,
               reset           => '0', -- important to note that we DO NOT reset the SDRAM controller on reset (it would stop refreshing, which would be bad)

               -- interface to synthetic CPU
               cs => dram_cs,
               req_read => req_read,
               req_write => req_write,
               mem_address => physical_address(24 downto 0),
               mem_wait => dram_wait,
               data_in => cpu_data_out,
               data_out => dram_data_out,
               coldboot => coldboot,

               -- interface to hardware SDRAM chip
              SDRAM_CLK        => open,
              SDRAM_CKE        => DRAM_CKE,
              SDRAM_CS         => DRAM_CS_N,
              SDRAM_nCAS       => DRAM_CAS_N,
              SDRAM_nRAS       => DRAM_RAS_N,
              SDRAM_nWE        => DRAM_WE_N,
              SDRAM_DQM        => DRAM_DQM,
              SDRAM_BA         => DRAM_BA,
              SDRAM_ADDR       => DRAM_ADDR,
              SDRAM_DQ         => DRAM_DQ
           );

   -- 4KB system ROM implemented in block RAM
   rom: entity work.MonZ80
   port map(
               clk => clk,
               A => physical_address(11 downto 0),
               D => rom_data_out
           );

   -- 4KB SRAM memory implemented in block RAM
   sram: entity work.SSRAM
   generic map(
                  AddrWidth => 12
              )
   port map(
               clk => clk,
               ce => sram_cs,
               we => req_write,
               A => physical_address(11 downto 0),
               DIn => cpu_data_out,
               DOut => sram_data_out
           );

   -- UART connected to FTDI USB UART
   uart0: entity work.uart_interface
   generic map ( watch_for_reset => 1, clk_frequency => (clk_freq_mhz * 1000000) )
   port map(
               clk => clk,
               reset => system_reset,
               reset_out => reset_request_uart, -- result of watching for reset sequence on the input
               serial_in => UART_RXD,
               serial_out => UART_TXD,
               serial_rts => open,
               serial_cts => '0',
               cpu_address => virtual_address(2 downto 0),
               cpu_data_in => cpu_data_out,
               cpu_data_out => uart0_data_out,
               enable => uart0_cs,
               interrupt => uart0_interrupt,
               req_read => req_read,
               req_write => req_write
           );

   -- UART connected to two GPIOs (1(30), 1(31))
   uart1: entity work.uart_interface
   generic map ( watch_for_reset => 1, clk_frequency => (clk_freq_mhz * 1000000) )
   port map(
               clk => clk,
               reset => system_reset,
               reset_out => open,
               serial_in => GPIO1_D(30),
               serial_out => GPIO1_D(31),
               serial_rts => open,
               serial_cts => '0',
               cpu_address => virtual_address(2 downto 0),
               cpu_data_in => cpu_data_out,
               cpu_data_out => uart1_data_out,
               enable => uart1_cs,
               interrupt => uart1_interrupt,
               req_read => req_read,
               req_write => req_write
           );

   -- Timer device (internally scales the clock to 1MHz)
   timer: entity work.timer
   generic map ( clk_frequency => (clk_freq_mhz * 1000000) )
   port map(
               clk => clk,
               reset => system_reset,
               cpu_address => virtual_address(2 downto 0),
               data_in => cpu_data_out,
               data_out => timer_data_out,
               enable => timer_cs,
               req_read => req_read,
               req_write => req_write,
               interrupt => timer_interrupt
           );

   -- GPIO to FPGA pins and/or internal signals
   gpio: entity work.gpio
   port map(
               clk => clk,
               reset => system_reset,
               cpu_address => virtual_address(2 downto 0),
               data_in => cpu_data_out,
               data_out => gpio_data_out,
               enable => gpio_cs,
               read_notwrite => req_read,
               input_pins => gpio_input,
               output_pins => gpio_output
           );

  -- SPI master device connected to SD card socket on the IO board
  spimaster1: entity work.spimaster
  port map(
              clk => clk,
              reset => system_reset,
              cpu_address => virtual_address(2 downto 0),
              cpu_wait => spimaster1_wait,
              data_in => cpu_data_out,
              data_out => spimaster1_data_out,
              enable => spimaster1_cs,
              req_read => req_read,
              req_write => req_write,
              slave_cs => SD_DAT3,
              slave_clk => SD_CLK,
              slave_mosi => SD_DAT0,
              slave_miso => SD_CMD
          );


   -- An attempt to allow the CPU clock to be scaled back to run
   -- at slower speeds without affecting the clock signal sent to
   -- IO devices. Basically this was an attempt to make CP/M games
   -- playable :) Very limited success. Might be simpler to remove
   -- this entirely.
   clkscale: entity work.clkscale
   port map (
               clk => clk,
               reset => system_reset,
               cpu_address => virtual_address(2 downto 0),
               data_in => cpu_data_out,
               data_out => clkscale_out,
               enable => clkscale_cs,
               read_notwrite => req_read,
               clk_enable => cpu_clk_enable
           );

   pll: entity work.pll
   port map (
               areset => open,
               inclk0 => CLOCK_50,
               c0 => DRAM_CLK, -- 100 Mhz - 180 deg
               c1 => clk, -- 100 Mhz
               locked => open
           );

end Behavioral;
