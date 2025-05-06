# Changelog
All notable changes will be logged here.

---

## 03-03-2025
### Added
- [Program counter](/design%20sources/program_counter.v) && [testbench for it](/testbenches/tb_pc.v): The PC essentially points to the next instruction. Support for branching is also present (jumping to different instructions).

## 08-03-2025
### Added
- [Instruction memory](/design%20sources/instruction_memory.v), [testbench](/testbenches/tb_imem.v), including the [memory file](/memory%20files/imem.mem): PC points the address, this gives the instruction.

## 13-03-2025
### Added
- [Instruction decoder](/design%20sources/instruction_decoder.v), [testbench](/testbenches/tb_id.v), including the [memory file](/memory%20files/imem_two.mem): The instruction given by the Instruction memory is further split into 4 parts. This is the main decoding stage.

## 19-03-2025
### Chore
- Updated workflow for using `iverilog` and `gtkwave` cause life is easier now.

## 24-04-2025
### Added
- Basic assembler has been created. Check out the `assembler/` in the root directory.

## 06-05-2025
### Updated
- The assembler now sends out errors like a real compiler. It's pretty petty but yeah. It's not a CLI tool yet but uh yeah. Soon.
---

### Known Behavior
There is a 1-cycle delay in the waveform of the instruction memory. This happens as all parts as of now.