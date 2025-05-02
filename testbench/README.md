# 18-224/624 S25 Tapeout Test Files
This folder contains all test files related to the design process. Unfortunately, the easiest way to test the design is to put it on a physical emulator due to how long the VGA cycle is. I wanted to create somewhat of a more comprehensive testbench. However, this was the day the project was due when the ECE machines went down and I tried getting verilator to work on my mac for 3 hours with no success. So, this folder contains an assortment of files I used for testing parts of my design. 

## chipInterface_spi.sv
The chip interface I used to test my spi module with the physical Pmod JSTK2. It sends the command to the Pmod to get the normalized 8 bit x and y location of the joystick and displays the data received one byte at a time on 8 LEDs. 

## chipInterface_vga.sv
The chip interface I used to test the vga module again. This was adapted from my 18-240 code. 

## mem_test.py
A CocoTB testbench that exhaustively tests each memory location in the grid by loading it with a value and ensuring only that particular memory location gets written to. 

## spi_test.sv
A SystemVerilog testbench that tests the spi module for timing. Was used in EDA playground.

## testbench.py
A CocoTB testbench that tests the entire tetris module. Was used to generate waveforms that were then viewed with GTKwave. 

## test_tetris.sv
A SystemVerilog testbench that tests the entire tetris module. Was used with VCS since the previous testbench started creating vcd files that were hundreds of MB large. 