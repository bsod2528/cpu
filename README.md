# cpu
[Documentation](https://bsod2528.github.io/pages/projects/vr16.html) | [Blogs](https://bsod2528.github.io/pages/tags.html#soc-dev)

VR16, a basic RISC processor designed and written in verilog. As time permits, this will be made better and backend design will also be updated.

# Features
- each instruction is 16-bit.
- 4 general purpose registers (r0, r1, r2, r3).
- runs on custom instruction set architecture called [vr-isa](ISA.md). 
- `vr-asm` as assembly and `vrscript` for writing easier code to run on the cpu.

> [!WARNING]
> The isa is very much work in progress, so things are subject to change.
> Documentation for `vr-asm` and `vrscript` may or may not be up-to-date due to extensive prematurity of their presence. 

# Setup
On how to run this project in your local machine. 

## Windows
1. Install WSL and install `gtkwave` and `iverilog`.
2. Setup venv in root directory. 
3. Run `./compile.sh` and then `./sim.sh` to view the rtl waveforms.

## Linux
1. Install `gtkwave` and `iverilog`.
2. Setup venv in root directory.
3. Run `./compile.sh` and then `./sim.sh` to view the rtl waveforms.

# Licensing
There are three parts to this CPU:
- frontend
- backend
- toolchain

1. Frontend deals with the synthesizable code written in verilog, the rtl and the corresponding testbenches, which are licensed under `GPLv3`. 
2. Backend (will start soon) deals with the actual physical design of the cpu, which will be licensed under the `CERN-OHL-S`.
3. Toolchain deals with the software side of the project, the `assembler/` and `compiler/` which makes programming on the CPU, which also come under `GPLv3`. 
