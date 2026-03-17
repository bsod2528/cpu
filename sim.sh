#!/bin/bash
# =============================================================================
# File    : sim.sh
# Brief   : Run the compiled VR16 simulation and open the waveform viewer.
#
# Description:
#   Executes the Icarus VVP simulation runtime on the compiled `output.out`
#   executable.  The simulation writes a VCD waveform file (`dump.vcd`) which
#   is then opened automatically in GTKWave for visual inspection.
#
# Prerequisites:
#   - `output.out` must already exist (run ./compile.sh first).
#   - GTKWave must be installed and available on PATH.
#
# Usage:
#   ./sim.sh
# =============================================================================
clear

vvp output.out
gtkwave dump.vcd
