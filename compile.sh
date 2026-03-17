#!/bin/bash
# =============================================================================
# File    : compile.sh
# Brief   : Compile all VR16 RTL and testbench sources with iverilog.
#
# Description:
#   Invokes the Icarus Verilog compiler (iverilog) in SystemVerilog-2009 mode
#   (-g2009) to compile the complete set of RTL modules together with the
#   top-level CPU testbench into a single simulation executable (output.out).
#
#   Source files compiled (in dependency order):
#     1. program_counter.v       - PC module
#     2. instruction_memory.v    - IMEM module
#     3. instruction_decoder.v   - Decoder module
#     4. gp_registers.v          - Register file module
#     5. control_unit.sv         - FSM control unit (SystemVerilog)
#     6. alu.v                   - ALU module
#     7. tb/tb_cpu.v             - Top-level integration testbench
#     8. vr16_cpu.v              - Top-level CPU wrapper
#
# Output:
#   output.out  - Icarus VVP simulation executable.
#
# Usage:
#   ./compile.sh
# =============================================================================

clear

iverilog -g2009 -o output.out \
    src/frontend/rtl/program_counter.v \
    src/frontend/rtl/instruction_memory.v \
    src/frontend/rtl/instruction_decoder.v \
    src/frontend/rtl/gp_registers.v \
    src/frontend/rtl/control_unit.sv \
    src/frontend/rtl/alu.v \
    src/frontend/tb/tb_cpu.v \
    src/frontend/vr16_cpu.v
