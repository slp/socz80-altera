socz80-de0
==========

This is a port of Will Sowerbutts' socz80 retro microcomputer (http://sowerbutts.com/socz80) for the Tersasic DE0 board based on the DE0 nano port from https://github.com/slp/socz80-de0_nano.

Building
========

Make sure you have the Altera Quartus II software (I've used version 13.0 from Web Edition) binaries on your $PATH. Then run "make" for building the SOF file, and "make load" for loading it on your board.

Software
========

This project only contains the VHDL files for building the core and its depencies. You can find some software for this microcomputer and instructions about what you can do with it inside the tarball of the original project (http://sowerbutts.com/socz80/socz80-2014-04-30.tar.gz).

TODO
====

* Make it work on the DE0. Z80 + SRAM and ROM are working, but SDRAM need more tweak. I also need to publish the changes.
* Add support for the integrated SD Card
* Video Out and PS2 for a keyboard could be also a nice entry.
* Currently the 4 hex digit are used to show the CPU PC, but I will also create an IO device to show on them the value you want
* Also add all the SW switch and Button 1 and 2 to GPI and the LED to GPO minus the one used to display the CPU status. and Button 0 is used for Reset.
* The original design was developed for a Papilo Pro board, which feautres a reasonable amount of non volatile memory onboard. The DE0 have a flash device, it may be nice to allow to map it to memory. Not sure if allow write to it is a good idea.
