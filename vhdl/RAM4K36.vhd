--+-----------------------------------+-------------------------------------+--
--|                      ___   ___    | (c) 2013-2014 William R Sowerbutts  |--
--|   ___  ___   ___ ___( _ ) / _ \   | will@sowerbutts.com                 |--
--|  / __|/ _ \ / __|_  / _ \| | | |  |                                     |--
--|  \__ \ (_) | (__ / / (_) | |_| |  | A Z80 FPGA computer, just for fun   |--
--|  |___/\___/ \___/___\___/ \___/   |                                     |--
--|                                   |              http://sowerbutts.com/ |--
--+-----------------------------------+-------------------------------------+--
--| A 4096 entry deep, 36-bit wide RAM using four RAM4K9 devices (and thus  |--
--| eight Xilinx RAMB16BWER devices)                                        |--
--+-------------------------------------------------------------------------+--

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
library UNISIM;
entity RAM4K36 is
	port(
		clk			: in  std_logic;
		write  		: in  std_logic;
		address		: in  std_logic_vector(11 downto 0);
		data_in		: in  std_logic_vector(35 downto 0);
		data_out	: out std_logic_vector(35 downto 0)
	);
end RAM4K36;

architecture behaviour of RAM4K36 is

begin

    ram0: entity work.RAM4K9
    port map (
        clock      => clk,
        wren    => write,
        address  => address,
        data  => data_in(8 downto 0),
        q => data_out(8 downto 0)
    );

    ram1: entity work.RAM4K9
    port map (
        clock      => clk,
        wren    => write,
        address  => address,
        data  => data_in(17 downto 9),
        q => data_out(17 downto 9)
    );

    ram2: entity work.RAM4K9
    port map (
        clock      => clk,
        wren    => write,
        address  => address,
        data  => data_in(26 downto 18),
        q => data_out(26 downto 18)
    );

    ram3: entity work.RAM4K9
    port map (
        clock      => clk,
        wren    => write,
        address  => address,
        data  => data_in(35 downto 27),
        q => data_out(35 downto 27)
    );

end;
