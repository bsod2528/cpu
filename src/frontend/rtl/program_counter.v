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
// Description:
//  Maintains the current instruction address in `counter_reg`.  On each
//  rising clock edge the PC resolves one of four mutually exclusive
//  behaviours according to the following priority order (highest first):
//
//      1. reset - clears the PC and jump_done to zero.
//      2. flag_input - HALT behaviour; forces the PC back to address 0.
//      3. jump_enable - loads `jump_address` into the PC and asserts
//                       `jump_done` for one cycle so the control unit knows
//                       the jump has been applied.
//      4. return_enable - restores the PC to the address saved before the
//                         last jump (supports a basic subroutine return).
//      5. increment - advances the PC by 1 for normal sequential execution.
//
//  `jump_done` is de-asserted at the start of every non-reset cycle so
//  it never stays high for more than one clock period.
// =============================================================================

// bsod2528: I've been spamming can you hear the music while doing this HAHA.
// Saint: The best debugging sessions always have a good soundtrack. Respect.
module program_counter(
    input wire clk,
    input wire reset,
    input wire increment,
    input wire jump_enable,
    input wire return_enable,
    input wire flag_input, // for halt
    input wire [15:0] jump_address,

    output reg jump_done,
    output reg [15:0] counter_reg
);
    reg [15:0] temp_address;

    always @ (posedge clk or posedge reset) begin
        if (reset) begin
            jump_done <= 1'b0;
            counter_reg <= 16'b0000_0000_0000_0000;
        end
        else begin
            jump_done <= 1'b0;
            
            if (flag_input)
                counter_reg <= 16'b0000_0000_0000_0000;
                
            else if (jump_enable) begin
                temp_address <= counter_reg;
                counter_reg <= jump_address; 
                jump_done <= 1'b1;
            end

            else if (return_enable)
                counter_reg <= temp_address;

            else if (increment)
                counter_reg <= counter_reg + 1;
        end
    end
endmodule
