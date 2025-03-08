# cpu

A basic RISC processor designed in AMD Vivado and written in Verilog. As time permits, this will be made better and backend design will also be updated.

I'm calling it `VR16` 🙂👍.

## Features
- **16-bit Architecture**: All registers have 16 storage allowing higher levels of computing.
- **Program Counter:** Increments the `fetching` cycle of the CPU. Supports branching, thus one can come back to previous state.
- **Instruction Memory:** Memory to hold the instructions for the CPU.
- **General Purpose Registers:** 4x16-bit registers has been planned for now, to store values for arithmetic operations.
- **Basic Instruction Set:** I'll give this one my own name soon, cause 🙂.
    - **Arithmetic:** `ADD`, `SUB`, `MUL`, `DIV`
    - **Memory:** `LOAD`, `STORE`
    - **Control Flow:** `HALT`, `JUMP`
- **Immediate Value Support:** To simplify the arithmetic operations as of now.
- **Basic Stack** (*Future Implementation as it's really ambitious*)**:** To support function calls for easy memory management.

## Machine Instructions
- `ADD`: 0000_0000_0000_0001
- `SUB`: 0000_0000_0000_0010
- `MUL`: 0000_0000_0000_0100
- `DIV`: 0000_0000_0000_1000
- `LOAD`: 0000_0000_0001_0000
- `STORE`: 0000_0000_0010_0000
- `HALT`: 0000_0001_0000_0000
- `JUMP`: 0000_0010_0000_0000

---

# Setup
Well if you really wanna try this out go ahead. I use Vivado as I can simulate within, others like GTKWave can also be used to simulate the testbench.
- Install AMD Vivado
- Clone this repo.
- Create a project called `cpu` or whatever in Vivado.
- Use the [`design sources`](design%20sources/) for creating RTL Design modules && (haha) [`testbenches`](testbenches/) for...testbenches.
- Simulate | (again...haha) synthesize your wish.
