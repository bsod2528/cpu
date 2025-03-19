#!/bin/bash

clear

iverilog -o output.out \
    'design sources'/program_counter.v \
    'design sources'/instruction_memory.v \
    'design sources'/instruction_decoder.v \
    testbenches/tb_id.v
