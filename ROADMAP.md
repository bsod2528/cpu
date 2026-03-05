# VR16 Roadmap

> This document translates the three top-level road-map goals from the README
> into concrete, week-by-week deliverables spread across two months.

---

## Current project state (baseline)

| Area | Component | Status |
|---|---|---|
| **Frontend RTL** | Program Counter | ✅ Implemented |
| | Instruction Memory | ✅ Implemented |
| | Instruction Decoder | ✅ Implemented |
| | ALU (arithmetic + logic) | ✅ Implemented |
| | Control Unit (6-state FSM) | ✅ Implemented |
| | General-Purpose Registers (r0–r3) | ✅ Implemented |
| | Top-level integration (`vr16_cpu.v`) | ✅ Implemented |
| | Draft skeleton (`new_cpu.v`) | 🗑️ Legacy artefact, to be removed |
| **ISA** | ADD / SUB / MUL / DIV (reg-reg) | ✅ Implemented |
| | ADDI / SUBI / MULI / DIVI (immediate) | ✅ Implemented |
| | AND / OR / NOT / XOR | ✅ Implemented |
| | JUMP / HALT | ✅ Implemented |
| | STOREI | ⚠️ Decoder-only (control unit + assembler missing) |
| | DELETE | 📋 Planned, not started |
| **Toolchain** | VRASM assembler | ✅ Implemented (module entry point) |
| | VRScript compiler | ✅ Implemented |
| **Testing** | Verilog testbenches (all RTL modules) | ✅ Present |
| | Python `pytest` (assembler + compiler) | ✅ Present |
| **Backend** | Physical design | ❌ Not started |

The CPU is a **single-stage (non-pipelined)** design running a custom 16-bit ISA
called VR16 ISA. As of the most recent changelog entry the basic CPU is estimated
to be ~90 % complete; a handful of instruction implementations and integration
tests remain before it can be considered production-ready.

---

## Goal 1 — Finish the basic CPU  *(Month 1, Weeks 1 – 4)*

### Week 1 — Complete missing ISA instructions

| # | Task | Deliverable |
|---|---|---|
| 1.1 | Implement `STOREI` in the control unit — add a new FSM branch in the `EXECUTE` state that loads the 8-bit immediate directly into the destination register without passing through the ALU. | Updated `control_unit.sv` |
| 1.2 | Add `STOREI` support to the assembler (`assembler.py` + `extractor.py`) so it encodes opcode `1000` with the register and 8-bit immediate fields. | Updated `assembler.py`, `extractor.py` |
| 1.3 | Add a `pytest` test that round-trips `STOREI` through the assembler and verifies the correct binary encoding. | New test in `src/frontend/tb/` |
| 1.4 | Implement `DELETE` in the RTL — add the opcode `1010` case to the control unit (zero the target register via the write path) and to the decoder. | Updated `control_unit.sv`, `instruction_decoder.v` |
| 1.5 | Add `DELETE` to the assembler and add a matching `pytest` test. | Updated assembler files + new test |

### Week 2 — Integration testing and bug fixes

| # | Task | Deliverable |
|---|---|---|
| 2.1 | Run the full Python test suite (`pytest src/frontend/tb/test_*.py`) and fix any regressions. | Green CI |
| 2.2 | Run RTL simulation (`./compile.sh && ./sim.sh`) with a program that exercises every implemented opcode at least once; record expected register values and add an assertion-based testbench. | New `tb_cpu_full_regression.v` |
| 2.3 | Verify the HALT-state behaviour: once `HALT` is reached the CPU must stay halted until reset; add a specific testbench case for this. | Test in `tb_cpu.v` or a dedicated file |
| 2.4 | Verify JUMP with a small loop program in VRScript; confirm the PC wraps to the correct address and the correct number of iterations are performed. | Example `.vrs` file + simulation run |
| 2.5 | Fix any timing or FSM bugs found during steps 2.1 – 2.4. | Patch commits to relevant RTL files |

### Week 3 — Toolchain polish

| # | Task | Deliverable |
|---|---|---|
| 3.1 | Remove the legacy `new_cpu.v` draft file (it is superseded by `vr16_cpu.v`). | Deletion commit |
| 3.2 | Add full `STOREI` and `DELETE` syntax to VRScript (`compiler.py`, `extractor.py`). | Updated compiler files |
| 3.3 | Write a VRScript example that demonstrates `STOREI` and `DELETE`; place it in `examples/vrscript/`. | New `.vrs` example |
| 3.4 | Extend `pytest` coverage to cover compiler-side `STOREI` / `DELETE` round-trips and at least one malformed-input rejection test for each new instruction. | New test files |
| 3.5 | Audit and update `ISA.md` — change `STOREI` status from *decoder-only* to *implemented*, change `DELETE` from *planned* to *implemented*, and freeze the ISA at **alpha-1**. | Updated `ISA.md` |

### Week 4 — Documentation, clean-up and v1.0 tag

| # | Task | Deliverable |
|---|---|---|
| 4.1 | Update `CHANGELOG.md` with all Week 1 – 3 changes. | Updated `CHANGELOG.md` |
| 4.2 | Update the `README.md` road-map section — mark *"finish basic CPU"* as complete. | Updated `README.md` |
| 4.3 | Confirm `pytest` and RTL simulation both pass cleanly from a fresh environment (follow the README setup steps). | Verified clean run |
| 4.4 | Tag the repository as **v1.0** — "basic CPU complete". | Git tag `v1.0` |

---

## Goal 2 — Pipeline the CPU  *(Month 2, Weeks 5 – 7)*

The current single-stage design processes one instruction per trip through
the control FSM.  A classic 4-stage in-order pipeline
(**IF → ID → EX → WB**) will increase instruction throughput, though it
requires hazard handling.

> A memory stage (MEM) is omitted for now because VR16 does not yet have a
> data memory / load-store unit; it can be added as a follow-on once the
> pipelined core is stable.

### Week 5 — Pipeline architecture design

| # | Task | Deliverable |
|---|---|---|
| 5.1 | Document the intended 4-stage pipeline (IF, ID, EX, WB) in a new `docs/pipeline.md` file, including a diagram of pipeline registers, forwarding paths, and stall/flush conditions. | New `docs/pipeline.md` |
| 5.2 | Identify all data-hazard scenarios for the current ISA (RAW hazards are the primary concern because there are no memory operands yet). | Hazard table in `docs/pipeline.md` |
| 5.3 | Identify all control-hazard scenarios — specifically how JUMP and HALT interact with a filled pipeline; decide on flush vs. stall policy. | Control-hazard section in `docs/pipeline.md` |
| 5.4 | Design the interface of each pipeline register (`if_id_reg`, `id_ex_reg`, `ex_wb_reg`) — list every field that must be latched between stages. | Signal-list tables in `docs/pipeline.md` |

### Week 6 — Implement pipeline registers

| # | Task | Deliverable |
|---|---|---|
| 6.1 | Add `if_id_reg.v` — a synchronous register that latches the 16-bit raw instruction and the current PC value on every rising clock edge; supports a synchronous flush input. | New RTL file `src/frontend/rtl/if_id_reg.v` |
| 6.2 | Add `id_ex_reg.v` — latches decoded fields (opcode, operands, immediate, store_at, select_operation) from the instruction decoder and control unit decode outputs. | New RTL file `src/frontend/rtl/id_ex_reg.v` |
| 6.3 | Add `ex_wb_reg.v` — latches the ALU result, write-enable flag, and destination register address for the write-back stage. | New RTL file `src/frontend/rtl/ex_wb_reg.v` |
| 6.4 | Rewire `vr16_cpu.v` to insert the three pipeline registers between the existing sub-modules, replacing the direct wire connections. | Updated `vr16_cpu.v` |
| 6.5 | Add a basic testbench (`tb_pipeline_regs.v`) that clocks two back-to-back instructions through the `if_id_reg` and checks that the latched instruction word matches. | New testbench |

### Week 7 — Hazard detection, forwarding and stall logic

| # | Task | Deliverable |
|---|---|---|
| 7.1 | Implement a `hazard_unit.v` module that detects RAW data hazards by comparing the destination register of the instruction in EX/WB against the source registers of the instruction in ID/EX. | New RTL file `src/frontend/rtl/hazard_unit.v` |
| 7.2 | Add a forwarding path: when a hazard is detected and the result is already available in the EX_WB register, route it directly to the ALU operand input (forward-from-EX). | Updated `vr16_cpu.v` forwarding mux |
| 7.3 | When forwarding is not possible (e.g. back-to-back instructions with no intervening instruction), insert a pipeline bubble (NOP) by stalling the IF and ID stages for one cycle. | Stall logic in `hazard_unit.v` and PC |
| 7.4 | Handle control hazards: on a JUMP instruction, flush the `if_id_reg` and `id_ex_reg` pipeline registers (insert two bubbles) before the PC loads the target address. | Flush logic in `if_id_reg.v`, `id_ex_reg.v`, and `vr16_cpu.v` |
| 7.5 | Write a regression testbench (`tb_pipeline_hazards.v`) that tests: RAW hazard with forwarding, RAW hazard with stall, JUMP flush, and HALT in a pipelined context. | New testbench |

---

## Goal 3 — Finish physical design  *(Month 2, Week 8 and beyond)*

Physical design work targets the **backend** component of the project and
will be released under the **CERN-OHL-S** licence once the full licence text
is formally added to the repository.

> **Prerequisite:** Week 8 work depends on the pipelined RTL produced in
> Weeks 5 – 7.  If pipeline work is delayed, synthesis can be started
> against the non-pipelined v1.0 baseline (from Week 4) as a temporary
> stand-in, but the final backend must target the pipelined core.

### Week 8 — Synthesizability and backend bootstrapping

| # | Task | Deliverable |
|---|---|---|
| 8.1 | Audit every RTL module for synthesis compatibility: remove or guard any simulation-only constructs (`$display`, `initial` blocks outside testbenches, non-synthesisable operators). | Clean RTL files |
| 8.2 | Produce a synthesis-ready netlist for the pipelined VR16 core using a freely available open-source flow (e.g. Yosys + a generic standard-cell library or FPGA target). Document the steps in `docs/synthesis.md`. | `docs/synthesis.md` + Yosys script |
| 8.3 | Add the CERN-OHL-S licence text to the repository (`LICENSE-CERN-OHL-S`) and update the `README.md` licensing section to reflect that the backend is now formally covered. | New licence file + updated `README.md` |
| 8.4 | Create the `src/backend/` skeleton — at minimum a top-level `vr16_backend.v` wrapper and a `README` describing the target process/technology node and tool chain. | New files under `src/backend/` |
| 8.5 | Define the first milestone for physical design work: floorplanning and pin assignment; document estimated resource utilisation from step 8.2. | Section in `docs/synthesis.md` |

> **Note:** Full physical design (floorplanning, place-and-route, timing closure,
> DRC/LVS) extends well beyond two months.  Week 8 focuses on laying the
> foundation — clean RTL, a reproducible synthesis flow, and licence adoption —
> so that backend work can proceed incrementally in subsequent milestones.

---

## Summary timeline

```
Month 1                                  Month 2
Week 1   Week 2   Week 3   Week 4  |  Week 5   Week 6   Week 7   Week 8
──────────────────────────────────────────────────────────────────────────
STOREI   Integ.   Toolchn  Docs &  |  Pipeline  Pipeline  Hazards  Synth &
DELETE   testing  polish   v1.0    |  design    registers & fwd    backend
ISA ✓    RTL fix  ISA ✓    tag     |  doc       IF/ID     stalls   bootstrap
                                   |            ID/EX     JUMP     CERN lic
                                   |            EX/WB     flush
──────────────────────────────────────────────────────────────────────────
◄─────── Goal 1: Finish basic CPU ──────►◄────── Goal 2: Pipeline ──────►
                                                             ◄─ Goal 3 ──►
```

Each week builds directly on the previous one.  Weeks 1 – 4 must be completed
before pipeline work begins so that the baseline ISA is frozen and the test
suite is fully green.  Weeks 5 – 7 deliver the pipelined core.  Week 8
provides the jumping-off point for the physical design effort that follows.
