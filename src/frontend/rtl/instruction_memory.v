// VR16: A basic 16-bit RISC processor
// Copyright (C) 2025 Vishal Srivatsava AV
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program. If not, see <https://www.gnu.org/licenses/>.

`timescale 1ns / 1ps

// =============================================================================
// File      : instruction_memory.v
// Module    : instruction_memory
// Brief     : Read-only instruction memory (IMEM) for the VR16 processor.
//
// Description:
//   Stores up to 256 16-bit instructions loaded at simulation start from a
//   binary `.mem` file via `$readmemb`.  On each rising clock edge, when
//   `enable` is asserted, the instruction at `address[7:0]` is latched onto
//   the `instruction` output.  Only the lower 8 bits of the 16-bit address
//   bus are used, giving an effective address space of 256 entries.
//
//   The memory file path is parameterisable so that different programs can
//   be loaded without modifying the RTL source.
//
// Parameters:
//   MEM_FILE - Path to the binary `.mem` file loaded by `$readmemb` at time 0.
//              Default: "mem/imem.mem".
//
// Inputs:
//   clk     - System clock; instruction output is updated on the rising edge.
//   reset   - Active-high reset; clears the `instruction` output to zero.
//   enable  - Read enable; instruction is latched only when this is high.
//   address - 16-bit address bus; only bits [7:0] index the memory array.
//
// Outputs:
//   instruction - 16-bit instruction word read from the memory array.
// =============================================================================

// bsod2528: Instruction memory, it stores all the instructions that I set. Basically my actual instruction-set for what I'm creating.
// bsod2528: Gonna name this v-risc cause :moyai:
// bsod2528: Have to mention the inspiration for this: https://www.edaplayground.com/x/iCVx
// bsod2528: Thanks eda playground && whoever wrote that (they won't read but still, it's from the bottom of my heart)
// Saint: Great acknowledgement — crediting inspiration is good engineering culture.

module instruction_memory #(
    parameter MEM_FILE = "mem/imem.mem"
)(
    input wire clk,
    input wire reset,
    input wire enable,

    input [15:0] address,
    
    output reg [15:0] instruction
);
    // Instruction storage array: 256 entries, each 16 bits wide.
    // The upper bound of 255 gives address space [0:255] (256 words).
    reg [15:0] imem [0:255]; // just 256 instructions for now which will.
    // Saint: "which will" — will grow! Agreed. A future version could page this.

    // -------------------------------------------------------------------------
    // Initialisation block: runs once at simulation time 0.
    // Step 1: Pre-set instruction output to zero so no spurious instruction
    //         fires before the first valid memory read.
    // Step 2: Load the binary `.mem` file into the imem array using the
    //         parameterised path so the same RTL can run different programs.
    // -------------------------------------------------------------------------
    initial begin
        instruction = 16'b0000_0000_0000_0000;
        $readmemb(MEM_FILE, imem);
    end

    // -------------------------------------------------------------------------
    // Clocked read path.
    // Priority: reset > enable (read) > hold (output unchanged).
    // -------------------------------------------------------------------------
    always @ (posedge clk or posedge reset) begin
        // Debug timestamp display — useful during waveform analysis.
        $display("AT: %t", $time);
        // Step 3: On reset, clear the instruction output to prevent stale data
        //         from propagating into the decoder on the next active cycle.
        if (reset)
            instruction <= 16'b0000_0000_0000_0000;
        // Step 4: When enabled, latch the instruction at the requested address.
        //         Only the lower 8 bits of the address bus are used to index
        //         the 256-entry array.
        else if (enable)
            instruction <= imem[address[7:0]];
    end
endmodule
