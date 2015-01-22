socz80-altera
===============

This is a port of Will Sowerbutts' socz80 retro microcomputer (http://sowerbutts.com/socz80) for Altera FPGA boards, currently supporting DE0-nano, DE2 and DE2-70 from Terasic.

Building
========

Make sure you have the Altera Quartus II software (I've used version 13.1 from Web Edition) binaries on your $PATH. Then run "make" for building the SOF file, and "make load" for loading it on your board.

Software
========

This project only contains the VHDL files for building the core and its depencies. You can find some software for this microcomputer and instructions about what you can do with it inside the tarball of the original project (http://sowerbutts.com/socz80/socz80-2014-04-30.tar.gz).

