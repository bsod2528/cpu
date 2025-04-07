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

// It's happening ladies and gentlemen

// These instructions will not work:
// - `1000`: LOAD
// - `1001`: JUMP
// - `1010`: STORE
// - `1111`: HALT
// as they're meant to be executed by the Control Unit

module alu(clk, reset, operand_one, operand_two, _opcode, _imm_value, result);
    input clk, reset;
    input [3:0] _opcode, _imm_value;
    input [15:0] operand_one, operand_two;
    output reg [15:0] result;

    always @ (posedge clk or posedge reset) begin
        if (reset)
            result <= 16'b0000_0000_0000_0000;
        else begin
            case (_opcode)
                4'b0000: result <= operand_one + operand_two; // ADD
                4'b0001: result <= operand_one + _imm_value; // ADDI
                4'b0010: result <= operand_one - operand_two; // SUB
                4'b0011: result <= operand_one - _imm_value; // SUBI
                4'b0100: result <= operand_one * operand_two; // MUL
                4'b0101: result <= operand_one * _imm_value; // MULI
                4'b0110: result <= operand_one / operand_two; // DIV
                4'b0111: result <= operand_one / _imm_value; // DIVI - good thing `immediate values` weren't named absolute values, otherwise this would've been DIVA *winks*. It's a joke.
                4'b1011: result <= operand_one & operand_two; // AND
                4'b1100: result <= operand_one | operand_two; // OR
                4'b1101: result <= ~operand_one; // NOT
                4'b1110: result <= operand_one ^ operand_two;
            endcase
        end
    end
endmodule
