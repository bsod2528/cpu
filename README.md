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
On how to run this project on your local machine.

## Python environment (required for assembler/compiler + helper scripts)
- Tested with Python `3.10` to `3.12`.

Create and activate a virtual environment from the repo root:

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

## RTL simulation prerequisites (`compile.sh` / `sim.sh`)
Install the simulator + waveform viewer:

- `iverilog`
- `gtkwave`

Then run:

```bash
./compile.sh
./sim.sh
```

## Assembler/compiler-only usage (no RTL simulation)
If you only want to use the toolchain (`vr-asm` / `vrscript`), you just need the Python setup above (virtual environment + `pip install -r requirements.txt`).
`iverilog` and `gtkwave` are not required unless you plan to run `./compile.sh` / `./sim.sh`.

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
   - Module entrypoint (recommended): `PYTHONPATH=src python3 -m assembler examples/vr-asm/add.asm mem/imem.mem`
   - Script entrypoint (also supported): `PYTHONPATH=src python3 src/assembler/assembler.py examples/vr-asm/add.asm mem/imem.mem`

## VRSCRIPT
1. Comments can be made using ` `` ` (double backtick).
2. Register assignments: `<register> = <int>` — only `r0`, `r1`, `r2`, `r3` are valid left-hand sides.
3. Arithmetic calls: `<instruction>(<store_at>, <operand_one>, <operand_two>)` — supported instructions are `add`, `sub`, `mul`, `div`.
4. For loops: `for <var> in <n> { <reg> <op> <value> }` — runs the body `n` times.
   - `<n>` must be an integer in range `0..VR16_MAX_FOR_LOOP_ITERATIONS` (default max: `10000`) to prevent huge compile-time unroll output.
   - Supported loop body operators: `++` → `addi`, `--` → `subi`, `**` → `muli`, `//` → `divi`.
   - Example: `for i in 4 { r3 ++ 2 }` emits `addi r3, 2;` four times.
5. Compile a script with module entrypoint: `PYTHONPATH=src python3 -m compiler examples/vrscript/add.vrs examples/vr-asm/compiled.asm`
6. Script entrypoint is also supported: `PYTHONPATH=src python3 src/compiler/compiler.py examples/vrscript/add.vrs examples/vr-asm/compiled.asm`
7. For regression examples, see `examples/vrscript/loop_fixture.vrs` and `examples/vr-asm/loop_fixture_expected.asm`.

# Licensing
There are three parts to this CPU:
- frontend
- backend
- toolchain

1. Frontend deals with the synthesizable code written in verilog, the rtl and the corresponding testbenches, which are licensed under `GPLv3`. 
2. Backend (will start soon) deals with the actual physical design of the cpu, which will be licensed under the `CERN-OHL-S`.
3. Toolchain deals with the software side of the project, the `src/assembler/` and `src/compiler/` which makes programming on the CPU, which also come under `GPLv3`. 
