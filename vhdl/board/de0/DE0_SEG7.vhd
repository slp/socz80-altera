--+-----------------------------------------------------------------------+-------------------------------------+--
--|________  ___________________________  ____________________ ________   | (c) 2014-2015 Manoel Trapier        |--
--|\______ \ \_   _____/\   _  \______  \/   _____/\_   _____//  _____/   | godzil@986-studio.com               |--
--| |    |  \ |    __)_ /  /_\  \  /    /\_____  \  |    __)_/   \  ___   |                                     |--
--| |    `   \|        \\  \_/   \/    / /        \ |        \    \_\  \  | A 7 Segment for DE0, just for fun   |--
--|/_______  /_______  / \_____  /____/ /_______  //_______  /\______  /  |                                     |--
--|        \/        \/        \/               \/         \/        \/   |          http://www.986-studio.com/ |--
--+-----------------------------------------------------------------------+-------------------------------------+--
--| DE0 7 Segment                                                                                               |--
--+-------------------------------------------------------------------------------------------------------------+--
--
-- See README.txt for more details
--
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity DE0_SEG7 is
    port(
        in_value: in  std_logic_vector(3 downto 0);
        segment:  out std_logic_vector(6 downto 0)
    );
end DE0_SEG7;

architecture Behavioral of DE0_SEG7 is
begin
    segment <= "1000000" when in_value = X"0" else -- ---t----
               "1111001" when in_value = X"1" else -- |      |
               "0100100" when in_value = X"2" else -- lt      rt
               "0110000" when in_value = X"3" else -- |      |
               "0011001" when in_value = X"4" else -- ---m----
               "0010010" when in_value = X"5" else -- |      |
               "0000010" when in_value = X"6" else -- lb      rb
               "1111000" when in_value = X"7" else -- |      |
               "0000000" when in_value = X"8" else -- ---b----
               "0011000" when in_value = X"9" else
               "0001000" when in_value = X"A" else
               "0000011" when in_value = X"B" else
               "1000110" when in_value = X"C" else
               "0100001" when in_value = X"D" else
               "0000110" when in_value = X"E" else
               "0001110";
end architecture;