#!/bin/bash

clear

iverilog -o output.out \
    'design sources'/program_counter.v \
    'design sources'/instruction_memory.v \
    'design sources'/instruction_decoder.v \
    'design sources'/control_signal.v \
    testbenches/tb_cu.v
