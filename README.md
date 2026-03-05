# cpu
[Documentation](https://bsod2528.github.io/pages/projects/vr16.html) | [Blogs](https://bsod2528.github.io/pages/tags.html#soc-dev)

VR16, a basic RISC processor designed and written in verilog. As time permits, this will be made better and backend design will also be updated.

# Features
- single stage cpu
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

# Road-Map
- [ ] finish basic cpu
- [ ] pipeline it
- [ ] finish physical design

As of `13-10-2025` basic cpu is 90% done, just a bit more debugging is needed.

# Basic docs for VRASM and VRSCRIPT
## VRASM
1. Actual `programs` start generating machine code by starting the code with `start:`, similary to stop generating machine code use `end:`.
2. Comments can be made using `--`.
3. For program syntax, kindly refer [isa.md](./ISA.md)
4. Default assembler output is `mem/imem.mem`, which matches the RTL instruction memory path.
   - Example: `cd src/assembler && python3 assembler.py ../../examples/vr-asm/add.asm`

## VRSCRIPT
1. Comments can be made using ` `` ` (double backtick).
2. Register assignments: `<register> = <int>` — only `r0`, `r1`, `r2`, `r3` are valid left-hand sides.
3. Arithmetic calls: `<instruction>(<store_at>, <operand_one>, <operand_two>)` — supported instructions are `add`, `sub`, `mul`, `div`.
4. For loops: `for <var> in <n> { <reg> <op> <value> }` — runs the body `n` times.
   - `<n>` must be an integer in range `0..VR16_MAX_FOR_LOOP_ITERATIONS` (default max: `10000`) to prevent huge compile-time unroll output.
   - Supported loop body operators: `++` → `addi`, `--` → `subi`, `**` → `muli`, `//` → `divi`.
   - Example: `for i in 4 { r3 ++ 2 }` emits `addi r3, 2;` four times.
5. Compile a script with: `cd src/compiler && python3 compiler.py ../../examples/vrscript/add.vrs ../../examples/vr-asm/compiled.asm`
6. For regression examples, see `examples/vrscript/loop_fixture.vrs` and `examples/vr-asm/loop_fixture_expected.asm`.

# Licensing
There are three parts to this CPU:
- frontend
- backend
- toolchain

1. Frontend deals with the synthesizable code written in verilog, the rtl and the corresponding testbenches, which are licensed under `GPLv3`. 
2. Backend (will start soon) deals with the actual physical design of the cpu, which will be licensed under the `CERN-OHL-S`.
3. Toolchain deals with the software side of the project, the `src/assembler/` and `src/compiler/` which makes programming on the CPU, which also come under `GPLv3`. 
