// 16-CPU: A basic 16-bit RISC processor
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

// Instruction bits be like:
// | 0000 | 00 | 00 | 00 | 00 | 0000 |
// | opcode | reg a | reg b | reg c | reg d | immediate value |

module instruction_decoder(instruction, clk, reset, opcode, reg_a, reg_b, reg_c, reg_d, imm_value);
    input clk, reset;
    input [15:0] instruction;
    output reg [3:0] opcode, reg_a, reg_b, reg_c, reg_d, imm_value; // imm_value == immediate value

    always @ (posedge clk or posedge reset) begin
        if (reset) begin
            opcode <= 4'b0000;
            reg_a <= 2'b00;
            reg_b <= 2'b00;
            reg_c <= 2'b00;
            reg_d <= 2'b00;
            imm_value <= 4'b0000;
        end
        else begin
            opcode <= instruction[15:12];
            reg_a <= instruction[11:10];
            reg_b <= instruction[9:8];
            reg_c <= instruction[7:6];
            reg_d <= instruction[5:4];
            imm_value <= instruction[3:0];
            $display("%b", opcode);
        end
    end
endmodule
