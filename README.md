# cpu
[Documentation](https://bsod2528.github.io/pages/projects/vr16.html) | [Blogs](https://bsod2528.github.io/pages/tags.html#soc-dev)

VR16 is a basic RISC processor designed and written in Verilog. As time permits, this will be improved, and the backend design will also be updated.

# Features
- single-stage CPU
- each instruction is 16-bit.
- 4 general purpose registers (r0, r1, r2, r3).
- runs on a custom instruction set architecture called [VR16 ISA](ISA.md).
- `VRASM` for assembly and `VRScript` for writing simpler code to run on the CPU.

> [!WARNING]
> The ISA is still a work in progress, so details are subject to change.
> Documentation for `VRASM` and `VRScript` may not always be up to date because these tools are still in an early stage.

# Setup
How to run this project on your local machine.

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
If you only want to use the toolchain (`VRASM` / `VRScript`), you only need the Python setup above (virtual environment + `pip install -r requirements.txt`).
`iverilog` and `gtkwave` are not required unless you plan to run `./compile.sh` / `./sim.sh`.

## Quickstart
Run the full flow in this order:

1. Compile `examples/vrscript/add.vrs` to `examples/vr-asm/compiled.asm`:
   ```bash
   PYTHONPATH=src python3 -m compiler examples/vrscript/add.vrs examples/vr-asm/compiled.asm
   ```
2. Assemble `examples/vr-asm/compiled.asm` into `mem/imem.mem`:
   ```bash
   PYTHONPATH=src python3 -m assembler examples/vr-asm/compiled.asm mem/imem.mem
   ```
3. Build and run the RTL simulation:
   ```bash
   ./compile.sh
   ./sim.sh
   ```
4. Expected output artifacts after running the steps above:
   - `mem/imem.mem`
   - `output.out`
   - `dump.vcd`

## Troubleshooting
- **Symptom:** `ModuleNotFoundError` when running `python3 -m assembler` or `python3 -m compiler`.
  **Likely cause:** Python cannot find the project modules because `src/` is not on `PYTHONPATH`.
  **Fix:** Run commands with `PYTHONPATH=src`, for example:
  `PYTHONPATH=src python3 -m assembler examples/vr-asm/compiled.asm mem/imem.mem`.

- **Symptom:** `iverilog: command not found` or `gtkwave: command not found`.
  **Likely cause:** RTL simulation tools are not installed (or not on your shell `PATH`).
  **Fix:** Install `iverilog` and `gtkwave`, then verify they are available with `iverilog -V` and `gtkwave --version`.

- **Symptom:** `sim.sh` fails because `output.out` is missing.
  **Likely cause:** `./compile.sh` was not run first, so the simulation binary/output target was never generated.
  **Fix:** Run `./compile.sh` before `./sim.sh` each time you clean outputs or change build artifacts.

- **Symptom:** `mem/imem.mem` is empty or does not change after assembly.
  **Likely cause:** Malformed assembly boundaries, especially missing/misplaced `start:` and `end:` delimiters, so no instructions are emitted.
  **Fix:** Ensure your ASM has a valid `start:`...`end:` region containing instructions, then re-run the assembler command.

# Road-Map
- [ ] finish basic cpu
- [ ] pipeline it
- [ ] finish physical design

As of `13-10-2025` basic cpu is 90% done, just a bit more debugging is needed.

# Basic docs for VRASM and VRScript
## VRASM
1. Programs begin generating machine code when the code starts with `start:`. To stop generating machine code, use `end:`.
2. Comments can be made using `--`.
3. For program syntax, refer to [ISA.md](./ISA.md).
4. Default assembler output is `mem/imem.mem`, which matches the RTL instruction memory path.
   - Module entrypoint (recommended): `PYTHONPATH=src python3 -m assembler examples/vr-asm/add.asm mem/imem.mem`
   - Script entrypoint (also supported): `PYTHONPATH=src python3 src/assembler/assembler.py examples/vr-asm/add.asm mem/imem.mem`

## VRScript
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

## Current licensing (effective now)
1. Frontend (synthesizable Verilog RTL and testbenches) is licensed under `GPLv3`.
2. Toolchain (`src/assembler/` and `src/compiler/`) is licensed under `GPLv3`.

The canonical and legally effective license terms are in the repository's [`LICENSE`](./LICENSE) file.

## Planned future licensing (not yet effective)
1. Backend (physical design work) is planned to be licensed under `CERN-OHL-S`.
2. `CERN-OHL-S` is **not currently in effect** for this repository until its full license text is added to the repo and formally adopted.
