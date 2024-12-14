# Conway's Game of Life for Commodore 64

## What is Convay's Game of Life

__Wiki quote:__
The Game of Life, also known as Conway's Game of Life or simply Life, is a cellular automaton devised by the British mathematician John Horton Conway in 1970. It is a zero-player game, meaning that its evolution is determined by its initial state, requiring no further input. One interacts with the Game of Life by creating an initial configuration and observing how it evolves. It is Turing complete and can simulate a universal constructor or any other Turing machine.

[https://en.wikipedia.org/wiki/Conway%27s_Game_of_Life]

## Rules

- Any live cell with fewer than two live neighbours dies, as if by underpopulation.
- Any live cell with two or three live neighbours lives on to the next generation.
- Any live cell with more than three live neighbours dies, as if by overpopulation.
- Any dead cell with exactly three live neighbours becomes a live cell, as if by reproduction.

## Implementation

### Data Structures

- Using text mode (40x25) grid with emtpy space or filled character to keep the round state.
- Using additional 1024 bytes of RAM for neighbors counting.
- 32 bit counter to keep track of round number.

### Cycle

0. Increment the round number.
1. Clear the neighbors counting structure to all 0.
2. Screen memory will be traversed and for each live cell:
    a. the neighbor values in the neighbors counting structure will be incremented by one
    b. the respective cell will be ORed with 0b1000000.
3. The neighbors memory will be traversed and rules will be applied to each cell.
    a. The 0b1000000 bit can be used to figure out if the cell is live or not and the rest of the bits for count of neighbours.
4. Resulting state is written into the screen memory.

## Breakpoints

The [breakpoints] file contains names of labels that VICE will break on and open monitor when running via `make debug`. The file needs to be terminated by an empty line.

## Resources

[https://www.pagetable.com/c64ref/kernal/](C64 Kernal Reference)
[https://cc65.github.io/doc/](CC65 Docs)
[http://www.6502.org/users/obelisk/6502/reference.html](6502 Instruction Set)
[https://vice-emu.sourceforge.io/vice_11.html](VICE Monitor Manual)
