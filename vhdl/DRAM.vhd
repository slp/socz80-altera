--+-----------------------------------+-------------------------------------+--
--|                      ___   ___    | (c) 2013-2014 William R Sowerbutts  |--
--|   ___  ___   ___ ___( _ ) / _ \   | will@sowerbutts.com                 |--
--|  / __|/ _ \ / __|_  / _ \| | | |  |                                     |--
--|  \__ \ (_) | (__ / / (_) | |_| |  | A Z80 FPGA computer, just for fun   |--
--|  |___/\___/ \___/___\___/ \___/   |                                     |--
--|                                   |              http://sowerbutts.com/ |--
--+-----------------------------------+-------------------------------------+--
--| DRAM interface: Connect the CPU to the SDRAM on the Papilio Pro board.  |--
--| The SDRAM takes about 10 cycles to respond with data after making a     |--
--| request, so this module includes a direct-mapped cache to store         |--
--| recently read or written data in order to hide this latency.            |--
--+-------------------------------------------------------------------------+--
--
-- The Papilio Pro board has an 8MB SDRAM chip on the board. The socz80 MMU
-- provides a 64MB (26-bit) phyiscal address space. The low 32MB of address space
-- is allocated to the DRAM (the top 32MB being used for other memory devices).
-- 
-- The low 32MB is divided into two 16MB blocks. Accesses to the first block
-- (starting at 0MB) go through the cache, while accesses to the second
-- block (starting at 16MB) bypass the cache. There is only 8MB SDRAM on the
-- Papilio Pro so it is aliased twice in each block, ie it appears at 0MB,
-- 8MB, 16MB and 24MB.
--
-- The cache is direct mapped, ie the low bits of the address dictate which cache
-- line to use and which byte within that line. When a cache line is written to
-- the top bits of the address are stored in "cache tag" memory. When a cache line
-- is read the top bits of the address are compared to the stored tag to determine
-- if the cached data relates to the same address.
--
-- Each cache line consists of a 45 bits:
--   32 bits of cached data
--    4 validity bits to indicate if the cached data is valid or not
--    9 bits of address tag to indicate the top address bits of the
--
-- bit number (read these two        22222211111111110000000000
-- lines top to bottom)              54321098765432109876543210
--
-- CPU address is 16 bits wide:                PPPPOOOOOOOOOOOO (4 bit page,  12 bit offset)
-- physical address is 26 bits wide: FFFFFFFFFFFFFFOOOOOOOOOOOO (14 bit frame, 12 bit offset)
-- DRAM address is     25 bits wide:  CIFFFFFFFFFFFOOOOOOOOOOOO (1 bit cache flag, 1 bit ignored, 11 bit frame, 12 bit offset)
-- cached address is   23 bits wide:    TTTTTTTTTLLLLLLLLLLLLBB (9 bit cache line tag, 12 bit cache line, 2 bit byte offset)
--
-- cache lines use 4096 x 36 bit BRAM
-- cache tags use  4096 x  9 bit BRAM

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity DRAM is
	generic(
        sdram_address_width : natural;
        sdram_column_bits   : natural;
        sdram_startup_cycles: natural;
        cycles_per_refresh  : natural
	);
	port(
        -- interface to the system
        clk         : in    std_logic;
        reset       : in    std_logic;
        cs          : in    std_logic;
        req_read    : in    std_logic;
        req_write   : in    std_logic;
        mem_address : in    std_logic_vector(24 downto 0);
        data_in     : in    std_logic_vector(7 downto 0);
        data_out    : out   std_logic_vector(7 downto 0) := (others => '0');
        mem_wait    : out   std_logic;
        coldboot    : out   std_logic; -- this signals 1 until the SDRAM has been initialised

        -- interface to hardware SDRAM chip
        SDRAM_CLK   : out   std_logic;
        SDRAM_CKE   : out   std_logic;
        SDRAM_CS    : out   std_logic;
        SDRAM_nRAS  : out   std_logic;
        SDRAM_nCAS  : out   std_logic;
        SDRAM_nWE   : out   std_logic;
        SDRAM_DQM   : out   std_logic_vector( 1 downto 0);
        SDRAM_ADDR  : out   std_logic_vector (12 downto 0);
        SDRAM_BA    : out   std_logic_vector( 1 downto 0);
        SDRAM_DQ    : inout std_logic_vector (15 downto 0)
	);
end DRAM;

architecture behaviour of DRAM is
    -- sdram controller interface
    signal cmd_address           : std_logic_vector(sdram_address_width-2 downto 0) := (others => '0');
    signal cmd_wr                : std_logic := '1';
    signal cmd_enable            : std_logic;
    signal cmd_byte_enable       : std_logic_vector(3 downto 0);
    signal cmd_data_in           : std_logic_vector(31 downto 0);
    signal cmd_ready             : std_logic;
    signal sdram_data_out        : std_logic_vector(31 downto 0);
    signal sdram_data_out_ready  : std_logic;
    signal seen_ready            : std_logic := '0';
    signal last_address_word     : std_logic_vector(20 downto 0);

    -- internal signals
    signal current_word          : std_logic_vector(31 downto 0); -- value of current cache line
    signal current_byte_valid    : std_logic_vector(3 downto 0);  -- validity bits for current cache line
    signal word_changed          : std_logic;                     -- did the address bus value change?
    signal cache_hit             : std_logic;
    signal address_hit           : std_logic;
    signal byte_valid_hit        : std_logic;                      
    signal write_back            : std_logic;

    -- state machine
    type controller_state is ( st_idle,         -- waiting for command
                               st_read,         -- cache miss: issued read command to controller, waiting for data to arrive
                               st_read_done,    -- cache hit/completed miss: data arrived from controller, waiting for CPU to de-assert
                               st_write);       -- write: issued write command, waiting for CPU to de-assert
    signal current_state : controller_state;
    signal next_state    : controller_state;

    -- here's the cache memory signals
    signal cache_line_memory_write_enable : std_logic;
    signal cache_line_memory_data_in      : std_logic_vector(35 downto 0); -- 35 downto 32: validity bits; 31 downto 0: four data bytes
    signal cache_line_memory_data_out     : std_logic_vector(35 downto 0);
    signal cache_tag_memory_write_enable  : std_logic;
    signal cache_tag_memory_data_in       : std_logic_vector(8 downto 0);
    signal cache_tag_memory_data_out      : std_logic_vector(8 downto 0);

    -- break up the incoming physical address
    alias address_byte       : std_logic_vector(1 downto 0)  is mem_address(1 downto 0);
    alias address_line       : std_logic_vector(11 downto 0) is mem_address(13 downto 2);
    alias address_tag        : std_logic_vector(8 downto 0)  is mem_address(22 downto 14);
    alias address_word       : std_logic_vector(20 downto 0) is mem_address(22 downto 2);
                                                             -- mem_address(23) is unused in this design
    alias cache_inhibit      : std_logic                     is mem_address(24);

begin

    -- this should be based on the generic, really
    cmd_address <= mem_address(22 downto 2); -- address_tag & address_line
    cmd_data_in <= data_in & data_in & data_in & data_in; -- write the same data four times
    cmd_wr <= req_write;
    cache_tag_memory_data_in <= address_tag;
    coldboot <= not seen_ready;

    compute_next_state: process(req_read, req_write, current_state, cache_hit, cmd_ready, cs, sdram_data_out_ready, word_changed)
    begin
        cmd_enable <= '0';
        mem_wait <= '0';
        write_back <= '0';
        case current_state is
            when st_idle =>
                if cs = '1' and cmd_ready = '1' then 
                    if req_read = '1' then 
                        -- we can't process a read immediately if the address input just changed; delay them for one cycle.
                        if word_changed = '1' then
                            mem_wait <= '1';
                            next_state <= st_idle;
                            -- come back next cycle!
                        else
                            if cache_hit = '1' then
                                mem_wait <= '0';
                                next_state <= st_read_done;
                            else
                                cmd_enable <= '1';
                                mem_wait <= '1';
                                next_state <= st_read;
                            end if;
                        end if;
                    elsif req_write = '1' then
                        if word_changed = '1' then
                            mem_wait <= '1';
                            next_state <= st_idle;
                            -- come back next cycle!
                        else
                            next_state <= st_write;
                            cmd_enable <= '1';
                            mem_wait <= '0'; -- no need to wait, the SDRAM controller will latch all the inputs
                            write_back <= '1';
                        end if;
                    else
                        next_state <= st_idle;
                        mem_wait <= '0'; -- we know cmd_ready='1'
                    end if;
                else
                    next_state <= st_idle;
                    mem_wait <= (not cmd_ready);
                end if;
            when st_read =>
                if cs = '1' and req_read = '1' then
                    if sdram_data_out_ready = '1' then
                        next_state <= st_read_done;
                    else
                        next_state <= st_read;
                    end if;
                else
                    -- this kind of implies that they gave up on us?
                    next_state <= st_idle;
                end if;
                mem_wait <= (not sdram_data_out_ready) and (not cache_hit);
            when st_read_done =>
                if cs = '1' and req_read = '1' then
                    next_state <= st_read_done;
                else
                    next_state <= st_idle;
                end if;
                mem_wait <= (not sdram_data_out_ready) and (not cache_hit);
            when st_write =>
                if cs = '1' and req_write = '1' then
                    next_state <= st_write;
                else
                    next_state <= st_idle;
                end if;
                mem_wait <= (not cmd_ready); -- no need to wait once the write has been committed
        end case;
    end process;

    word_changed_check: process(last_address_word, address_word)
    begin
        if address_word = last_address_word then
            word_changed <= '0';
        else
            word_changed <= '1';
        end if;
    end process;

    cache_address_check: process(cache_tag_memory_data_out, cache_line_memory_data_out, address_tag)
    begin
        if cache_tag_memory_data_out = address_tag then
            address_hit <= '1';
            current_byte_valid <= cache_line_memory_data_out(35 downto 32);
        else
            address_hit <= '0';
            current_byte_valid <= "0000";
        end if;
    end process;

    cache_byte_valid_check: process(address_byte, current_byte_valid)
    begin
        case address_byte is
            when "00"   => byte_valid_hit <= current_byte_valid(0);
            when "01"   => byte_valid_hit <= current_byte_valid(1);
            when "10"   => byte_valid_hit <= current_byte_valid(2);
            when "11"   => byte_valid_hit <= current_byte_valid(3);
            when others => byte_valid_hit <= '0';
        end case;
    end process;

    cache_hit_check: process(byte_valid_hit, address_hit, cache_inhibit)
    begin
        if address_hit = '1' and byte_valid_hit = '1' and cache_inhibit = '0' then
            cache_hit <= '1';
        else
            cache_hit <= '0';
        end if;
    end process;

    byte_enable_decode: process(address_byte)
    begin
        case address_byte is
            when "00"   => cmd_byte_enable <= "0001";
            when "01"   => cmd_byte_enable <= "0010";
            when "10"   => cmd_byte_enable <= "0100";
            when "11"   => cmd_byte_enable <= "1000";
            when others => cmd_byte_enable <= "1000";
        end case;
    end process;

    data_out_demux: process(address_byte, sdram_data_out_ready, sdram_data_out, cache_line_memory_data_out, current_word)
    begin
        -- when the SDRAM is presenting data, feed it direct to the CPU.
        -- otherwise feed data from our cache memory.
        if sdram_data_out_ready = '1' then
            current_word <= sdram_data_out;
        else
            current_word <= cache_line_memory_data_out(31 downto 0);
        end if;

        case address_byte is
            when "00"   => data_out <= current_word( 7 downto  0);
            when "01"   => data_out <= current_word(15 downto  8);
            when "10"   => data_out <= current_word(23 downto 16);
            when "11"   => data_out <= current_word(31 downto 24);
            when others => data_out <= current_word(31 downto 24);
        end case;
    end process;

    cache_write: process(current_state, data_in, next_state, write_back, cache_line_memory_data_out, sdram_data_out, sdram_data_out_ready, address_byte, current_byte_valid)
    begin
        if (next_state = st_read) or (write_back = '1') then
            cache_tag_memory_write_enable <= '1';
        else
            cache_tag_memory_write_enable <= '0';
        end if;

        cache_line_memory_write_enable <= '0';
        cache_line_memory_data_in <= cache_line_memory_data_out;

        if next_state = st_read then
            cache_line_memory_data_in <= (others => '0'); -- set word and all valid flags to 1
            cache_line_memory_write_enable <= '1';
        end if;

        -- has our read completed?
        if current_state = st_read then
            if sdram_data_out_ready = '1' then
                cache_line_memory_data_in <= "1111" & sdram_data_out;
                cache_line_memory_write_enable <= '1';
            end if;
        elsif write_back = '1' then 
            case address_byte is
                when "00"   =>
                    cache_line_memory_data_in <= current_byte_valid(3 downto 1) & "1" & 
                                                 cache_line_memory_data_out(31 downto  8) & data_in;
                when "01"   =>
                    cache_line_memory_data_in <= 
                                                current_byte_valid(3 downto 2) & "1" & current_byte_valid(0) &
                                                cache_line_memory_data_out(31 downto 16) & data_in & cache_line_memory_data_out(7 downto 0);
                when "10"   =>
                    cache_line_memory_data_in <= 
                                                current_byte_valid(3) & "1" & current_byte_valid(1 downto 0) &
                                                cache_line_memory_data_out(31 downto 24) & data_in & cache_line_memory_data_out(15 downto 0);
                when "11"   =>
                    cache_line_memory_data_in <= 
                                                "1" & current_byte_valid(2 downto 0) &
                                                data_in & cache_line_memory_data_out(23 downto 0);
                when others => -- shut up, compiler!
            end case;
            cache_line_memory_write_enable <= '1';
        end if;
    end process;

    sdram_registers: process(clk)
    begin
        if rising_edge(clk) then
            -- state register
            current_state <= next_state;
            -- coldboot detection
            seen_ready <= seen_ready or cmd_ready;
            -- track memory address
            last_address_word <= address_word;
        end if;
    end process;

    -- underlying SDRAM controller (thanks, Hamsterworks!)
    sdram_ctrl: entity work.SDRAM_Controller 
    GENERIC MAP(
                sdram_address_width => sdram_address_width,
                sdram_column_bits   => sdram_column_bits,
                sdram_startup_cycles=> sdram_startup_cycles,
                cycles_per_refresh  => cycles_per_refresh
               ) 
    PORT MAP(
                clk             => clk,
                reset           => reset,

                cmd_address     => cmd_address,
                cmd_wr          => cmd_wr,
                cmd_enable      => cmd_enable,
                cmd_ready       => cmd_ready,
                cmd_byte_enable => cmd_byte_enable,
                cmd_data_in     => cmd_data_in,

                data_out        => sdram_data_out,
                data_out_ready  => sdram_data_out_ready,

                SDRAM_CLK       => SDRAM_CLK,
                SDRAM_CKE       => SDRAM_CKE,
                SDRAM_CS        => SDRAM_CS,
                SDRAM_RAS       => SDRAM_nRAS,
                SDRAM_CAS       => SDRAM_nCAS,
                SDRAM_WE        => SDRAM_nWE,
                SDRAM_DQM       => SDRAM_DQM,
                SDRAM_BA        => SDRAM_BA,
                SDRAM_ADDR      => SDRAM_ADDR,
                SDRAM_DATA      => SDRAM_DQ
            );

    -- block RAM used to store cache line data and byte validity (packs nicely into 36 bits)
    cacheline_memory_sram: entity work.RAM4K36
    port map (
        clk      => clk,
        reset    => reset,
        write    => cache_line_memory_write_enable,
        address  => address_line,
        data_in  => cache_line_memory_data_in,
        data_out => cache_line_memory_data_out
        
    );

    -- block RAM used to store cache line tag memory (packs nicely into 9 bits)
    cachetag_memory_sram: entity work.RAM4K9
    port map (
        clk      => clk,
        reset    => reset,
        write    => cache_tag_memory_write_enable,
        address  => address_line,
        data_in  => cache_tag_memory_data_in,
        data_out => cache_tag_memory_data_out
    );
end;
