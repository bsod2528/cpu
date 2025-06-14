#!/bin/bash

clear

iverilog -o output.out \
    'src/frontend/rtl'/program_counter.v \
    'src/frontend/rtl'/instruction_memory.v \
    'src/frontend/rtl'/instruction_decoder.v \
    'src/frontend/tb'/tb_imem.v
