# 18-224/624 S25 Tapeout
## Tetris

A condensed version of Tetris with no speedup or fancy mechanics (e.g. t-spin). The main strategy of this design is to use the fact that the VGA cycle is really long to allow for game state to be updated over multiple clock cycles instead of one. More details can be found in the documentation folder.

Some images of the working screen:

## IO

| Input/Output	| Description|																
|-------------|--------------------------------------------------|
| io_in[0]    | Toggle button to pause/play game                 |
| io_in[1]    | Drop button to drop tetris piece                 |
| io_in[2]    | Save button to save tetris piece                 |
| io_in[3]    | Rotate button to rotate tetris piece             |
| io_in[4]    | MISO, for an spi Pmod JSTK2                      |
| io_in[11:5] | Unused                                           |
| io_out[1:0] | Red channel                                      |
| io_out[3:2] | Green channel                                    |
| io_out[5:4] | Blue channel                                     |
| io_out[6]   | HS, horizontal sync                              |
| io_out[7]   | VS, vertical sync                                |
| io_out[8]   | MOSI, for an spi Pmod JSTK2                      |
| io_out[9]   | CS, for an spi Pmod JSTK2                        |
| io_out[10]  | SCK, for an spi Pmod JSTK2                       |
| io_out[11]  | Indicates whether game is going                  |

## How to Test

Attach a 640x480 VGA monitor to the tinyVGA Pmod which hooks up to ports io_out[7:0], 4 buttons to io_in[3:0], an SPI joystick to io_in[4] + io_out[10:8], an LED to io_out[11], and run a 25MHz clock.
