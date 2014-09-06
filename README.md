socz80-de0_nano
===============

This is a port of Will Sowerbutts' socz80 retro microcomputer (http://sowerbutts.com/socz80) for the Tersasic DE0-nano board.

Building
========

Make sure you have the Altera Quartus II software (I've used version 13.1 from Web Edition) binaries on your $PATH. Then run "make" for building the SOF file, and "make load" for loading it on your board.

Software
========

This project only contains the VHDL files for building the core and its depencies. You can find some software for this microcomputer and instructions about what you can do with it inside the tarball of the original project (http://sowerbutts.com/socz80/socz80-2014-04-30.tar.gz).

TODO
====

* To be able to get this design to run on the DE0-nano without breaking the timing constrains in excess, I had to remove the block RAM based cache. Even without this component, the design barely accomodates to said contrains. A better solution would probably be implementing an arbiter for the SDRAM, allowing this one and its controller to run at 100 Mhz, while the rest of the components run at ~70 Mhz.
 
* The original design was developed for a Papilo Pro board, which feautres a reasonable amount of non volatile memory onboard. The DE0-nano only provides a 2KB EEPROM, so I'm thinking about adding an SD card (using its SPI mode) to the design, for storing the ramdisks needed for running CP/M.
