
# Conway's Game of Life for Commodore 64

This is a small hobby project created for fun and learning.

It was inspired by countless YouTube videos about **retro computing** and classic machines. After spending a lot of time watching and reading about the Commodore 64, I wanted to actually program something, instead of just consuming content. It was for sure exciting :)

This is my **first program written in 6502 assembly**, so the code is far from perfection and nowhere near optimial. Please bear with me.

<p align="center">
  <img src="demo.gif" width="480">
</p>


## What is Convay's Game of Life

*Wiki quote:*
The Game of Life, also known as Conway's Game of Life or simply Life, is a cellular automaton devised by the British mathematician John Horton Conway in 1970. It is a zero-player game, meaning that its evolution is determined by its initial state, requiring no further input. One interacts with the Game of Life by creating an initial configuration and observing how it evolves. It is Turing complete and can simulate a universal constructor or any other Turing machine.

[Wikipedia](https://en.wikipedia.org/wiki/Conway%27s_Game_of_Life)

## Rules

- Any live cell with fewer than two live neighbours dies, as if by underpopulation.
- Any live cell with two or three live neighbours lives on to the next generation.
- Any live cell with more than three live neighbours dies, as if by overpopulation.
- Any dead cell with exactly three live neighbours becomes a live cell, as if by reproduction.

## Implementation

The program is written in 6502 assembly and runs entirely in **text mode (40×25)** on the Commodore 64. The game world is stored directly in **screen RAM ($0400)**, where each character represents one cell.

A generation-based loop updates the simulation according to Conway’s rules.

### Memory Used

- **Screen RAM ($0400–$07E7)**  
  Stores the current state of the game.  
  - Filled character = live cell  
  - Space = dead cell  

- **Neighbor Buffer (1024 bytes)**  
  Temporary memory used to count how many neighbors each cell has.

- **Round Counter (32-bit)**  
  Counts how many generations have been processed.

### How a Generation Works

Each generation is calculated in several simple steps:

1. **Increase the round counter**
2. **Clear the neighbor buffer**
3. **Scan the screen**
   - For every live cell, all eight neighboring cells get their neighbor count increased.
   - The cell’s previous state is marked in the buffer.
4. **Apply the rules**
   - Live cell with fewer than 2 neighbors dies
   - Live cell with 2 or 3 neighbors survives
   - Live cell with more than 3 neighbors dies
   - Dead cell with exactly 3 neighbors becomes alive
5. **Write the new state back to the screen**

---

### Notes

- The algorithm uses two passes to avoid overwriting data too early.
- Screen RAM is used directly to keep the code simple.
- The focus is on clarity and correctness rather than maximum speed.

## Compile and Run

Requires the ca65 out of the [cc65 suite](https://cc65.github.io). Having that installed, jurst run `make` to build and to execute in simulator run `make run`.

## Breakpoints

The [breakpoints] file contains names of labels that VICE will break on and open monitor when running via `make debug`. The file needs to be terminated by an empty line.
You can change font of the Monitor in Vice settings -> Host -> Monitor -> Font.

## Resources

[C64 Kernal Reference](https://www.pagetable.com/c64ref/kernal/)

[CC65 Docs](https://cc65.github.io/doc/)

[6502 Instruction Set](http://www.6502.org/users/obelisk/6502/reference.html)

[VICE Monitor Manual](https://vice-emu.sourceforge.io/vice_12.html)
