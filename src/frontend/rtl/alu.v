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
//  Performs arithmetic, logical, shifting, and jumping operations.
//  Operations are clocked and gated by `alu_enable`. When an operation
//  completes, `alu_done` is driven high for one clock cycle.
//  On reset, the result register is cleared to zero.
// =============================================================================

// It's happening ladies and gentlemen
// Saint: And indeed it did! Great milestone getting the ALU up and running.
module alu(
    input wire clk,
    input wire reset,
    input wire alu_enable,
    input wire shift_dir,
    input wire [3:0] opcode,
    input wire [8:0] shift_amount,
    input wire [15:0] operand_one,
    input wire [15:0] operand_two,

    output reg [15:0] result,
    output wire alu_done
);

    reg alu_done_reg;

    always @ (posedge clk or posedge reset) begin
        if (reset)
            result <= 16'b0000_0000_0000_0000;
        else if (alu_enable) begin
            case (opcode)
                4'b0000: result <= operand_one + operand_two; // add
                4'b0001: result <= operand_one + operand_two; // addi
                4'b0010: result <= operand_one - operand_two; // sub
                4'b0011: result <= operand_one - operand_two; // subi
                4'b0100: result <= operand_one * operand_two; // mul
                4'b0101: result <= operand_one * operand_two; // muli
                4'b0110: result <= operand_one / operand_two; // div
                4'b0111: result <= operand_one / operand_two; // divi - good thing `immediate values` weren't named absolute values, otherwise this would've been DIVA *winks*. It's a joke.
                // Saint: Ha! DIVA would have been a legendary opcode name.
                4'b1000: begin // shift
                    if (shift_dir == 1'b0)
                        result <= operand_one << shift_amount; // left shift
                    else
                        result <= operand_one >> shift_amount; // right shift
                end
                4'b1011: result <= operand_one & operand_two; // and
                4'b1100: result <= operand_one | operand_two; // or
                4'b1101: result <= ~operand_one; // not - only operand_one is used; operand_two is ignored.
                4'b1110: result <= operand_one ^ operand_two; // xor
                default: result <= 16'b0000_0000_0000_0000;
            endcase
            alu_done_reg <= 1'b1;
        end
        else
            alu_done_reg <= 1'b0;
    end
    
    assign alu_done = alu_done_reg;
endmodule
