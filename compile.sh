#!/bin/bash

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

