# cpu

A basic RISC processor designed and written in Verilog. As time permits, this will be made better and backend design will also be updated.

I'm calling it `VR16` 🙂👍.

## Features
- **16-bit Architecture**: All registers have 16 storage allowing higher levels of computing.
- **Program Counter:** Increments the `fetching` cycle of the CPU. Supports branching, thus one can come back to previous state.
- **Instruction Memory:** Memory to hold the instructions for the CPU.
- **General Purpose Registers:** 4x16-bit registers has been planned for now, to store values for arithmetic operations.
- **Basic Instruction Set:** Instruction Set Architecture (ISA) is called `VR16-ISA`.
    - **Arithmetic:** `ADD`, `SUB`, `MUL`, `DIV`
    - **Memory:** `LOAD`, `STORE`
    - **Control Flow:** `HALT`, `JUMP`
- **Immediate Value Support:** To simplify the arithmetic operations as of now.
- **Basic Stack** (*Future Implementation as it's really ambitious*)**:** To support function calls for easy memory management.

## Opcodes
SUBJECT TO CHANGE
1. `ADD`: 0001
2. `SUB`: 0010
3. `MUL`: 0011
4. `DIV`: 0100
5. `LOAD`: 0101
6. `STORE`: 0110
7. `HALT`: 0111
8. `JUMP`: 1000

---

# Setup
- Clone the repo.
- Ensure both [compile.sh](compile.sh) and [run_sim.sh](run_sim.sh) have rights to run (chmod +x) if you're on Linux.
- Run `compile.sh` first and then `run_sim.sh` to view the GTKwave.
- To view the waveforms on Windows, please use Vivado or Quartus. No need to run the `.sh` files in that case. 

--- 
# Licensing
All `.v` files come under the GPLv3. Hardware files will be added as time goes on, which will use the CERN-OHL-S license.
