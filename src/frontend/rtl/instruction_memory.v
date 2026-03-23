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
// Stores up to 256 16-bit instructions loaded at simulation start from a
// binary `.mem` file via `$readmemb`.  On each rising clock edge, when
// enable` is asserted, the instruction at `address[7:0]` is latched onto
// the `instruction` output.  Only the lower 8 bits of the 16-bit address
// bus are used, giving an effective address space of 256 entries.
//
// The memory file path is parameterisable so that different programs can
// be loaded without modifying the RTL source.
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
    reg [15:0] imem [0:255]; // just 256 instructions for now which will.
    // Saint: "which will" — will grow! Agreed. A future version could page this.

    initial begin
        instruction = 16'b0000_0000_0000_0000;
        $readmemb(MEM_FILE, imem);
    end
    
    // Terasic DE0 implementation involved the following:
    // - commenting out lines 77 - 80
    // - commenting out the actual logic the IMEM.
    // - utilise the code below
    // 
    // always @ (posedge clk or posedge reset) begin
    //     if (reset)
    //         instruction <= 16'b0000_0000_0000_0000;
    //     else if (enable) begin
    //         case (address[7:0])
    //             8'd0: instruction <=16'b0000_0000_0000_0000;
    //             ...
    //         default: instruction <= 16'b1111000000000000; // halt for everything else
    //     endcase
    //     end else
    //         instruction <= 16'h0000;
    //     end
    // 
    // This could've been done using a memory initialisation file in quartus, but I struggled with it.
    // So I just raw dogged it.
    
    always @ (posedge clk or posedge reset) begin
        $display("AT: %t", $time);
        if (reset)
            instruction = 16'b0000_0000_0000_0000;
        else if (enable)
            instruction = imem[address[7:0]];
        else
            instruction = 16'h0000;
    end
endmodule
