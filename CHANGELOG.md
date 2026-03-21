# Changelog

All notable changes to VR16 are documented here, following the [Keep a Changelog](https://keepachangelog.com/en/1.0.0/) convention and [ISO 8601](https://en.wikipedia.org/wiki/ISO_8601) date formatting (`YYYY-MM-DD`).

Active contributors:
- [bsod2528](https://github.com/bsod2528/) - RTL design, ISA, assembler
- [saint2706](https://github.com/saint2706) - tooling, CLI, documentation, code review.

---

## 2026-03-18
### Added
- `bsod2528`: Implemented `shift` (logical left/right) and `cjmp` (conditional jump with `jeq`, `jne`, `jgt`, `jlt`) instructions, completing the VR16 instruction set.
### Fixed
- `bsod2528`: Resolved FSM bug in `control_unit` where `do_cjmp_reg` was cleared by the combinational default on the second cycle in the JUMP state, causing CJMP to always take the false branch. Fix preserves `do_cjmp_reg` across JUMP state cycles.
- `bsod2528`: Added REFETCH state after JUMP to allow instruction memory to latch the instruction at the new PC address before DECODE begins.
- `bsod2528`: Restored `instruction_memory` to a clocked `always @(posedge clk)` block, replacing the prior `always @(*)` which caused a `$display` simulation loop and injected NOP bubbles into the pipeline when enable was deasserted.

---

## 2026-03-05
### Added
- `saint2706`: Implemented unconditional `jmp` instruction with full assembler and testbench support.
### Changed
- `saint2706`: Refactored assembler and compiler into proper CLI tools with argument parsing.
- `saint2706`: Added structured documentation across all assembler modules.
### Fixed
- `saint2706`: Corrected signal assignments across multiple RTL modules.

[Pull Request #1](https://github.com/bsod2528/cpu/pull/1)

---

## 2026-03-02
### Fixed
- `bsod2528`: Converted `always` blocks in `control_unit`, `gp_registers`, and `instruction_decoder` from clocked to combinational where appropriate, resolving pipeline timing issues.

---

## 2025-05-06
### Changed
- `bsod2528`: Improved assembler error reporting with colourised, line-accurate diagnostics and fuzzy opcode suggestions.
- `bsod2528`: Known behaviour: one-cycle output delay present in instruction memory at this stage.

---

## 2025-04-24
### Added
- `bsod2528`: Initial assembler implementation. Translates VR-ASM source files into 16-bit binary `.mem` files. Supports all arithmetic, logical, and data instructions defined at this stage.

---

## 2025-03-19
### Changed
- `bsod2528`: Updated CI workflow to use `iverilog` and `gtkwave` for a local simulation flow.

---

## 2025-03-13
### Added
- `bsod2528`: [Instruction decoder](src/frontend/rtl/instruction_decoder.v) and [testbench](src/frontend/tb/tb_id.v). Combinational module that splits the 16-bit instruction word into opcode, destination register, source registers, immediate value, and jump address fields.

---

## 2025-03-08
### Added
- `bsod2528`: [Instruction memory](src/frontend/rtl/instruction_memory.v) and [testbench](src/frontend/tb/tb_imem.v). 256-entry 16-bit ROM loaded from a `.mem` file via `$readmemb`. Program counter address selects the instruction to output.

---

## 2025-03-03
### Added
- `bsod2528`: [Program counter](src/frontend/rtl/program_counter.v) and [testbench](src/frontend/tb/tb_pc.v). 16-bit counter with synchronous reset, increment, jump, and return support.