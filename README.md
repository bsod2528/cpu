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
    - **Memory:** `LOAD`
    - **Control Flow:** `HALT`, `JUMP`
- **Immediate Value Support:** To simplify the arithmetic operations as of now.
- **Basic Stack** (*Future Implementation as it's really ambitious*)**:** To support function calls for easy memory management.

## Instruction Sets
Check out `ISA.md`.

# Setup
- Clone the repo.

## RTL Setup
- Ensure both [compile.sh](compile.sh) and [sim.sh](sim.sh) have rights to run (chmod +x) if you're on Linux.
- Run `compile.sh` first and then `sim.sh` to view the GTKwave.
- To view the waveforms on Windows, please use Vivado or Quartus. No need to run the `.sh` files in that case. 

## Assembler Setup
This has to be packaged into a CLI tool for ease, which will be done soon later on. Until then:
- Setup up a virtual environment.
- Use [requirements.txt](requirements.txt) for installing necessary packages.
- Write your own `vr16-asm` under `asm source files` and use the assembler run
```
py assembler.py
```
- The necessary `imem` file would be created, and then use the `sim.sh` to view the CPU working in ACTION!

# Disclaimer
Once you've created your own imem using the assembler, the CPU will not be executing it as I'm still figuring things out as of present commit.

The assembler, also does not account for any errors, it's not a proper compiler. This will also be updated in the future.

# Licensing
All `.v` files come under the GPLv3. Hardware files will be added as time goes on, which will use the CERN-OHL-S license.
