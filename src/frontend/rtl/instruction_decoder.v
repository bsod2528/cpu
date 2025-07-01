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

// Instruction bits be like:
// | 0000 | 00 | 00 | 00 | 00 | 0000 |
// | opcode | reg a | reg b | reg c | reg d | immediate value |

// Yeah so the above is generic split up, the format will change according to the `opcode`
// Refer to `ISA.md` on root directory to see the split-up / IS format for each opcode.

// MISC: It's 22-06-2025 as of me re-reading this, idk what i've done :skull:
module instruction_decoder(
    input wire clk,
    input wire reset,
    input wire [15:0] instruction,

    output reg [1:0] operand_one,
    output reg [1:0] operand_two,
    output reg [1:0] store_at,
    output reg [1:0] reg_to_work_on,
    output reg [3:0] opcode,
    output reg [15:0] imm_value,
    output reg [15:0] six_bit_dont_care,    // idk im raw doggin
    output reg [15:0] ten_bit_dont_care,
    output reg [15:0] twelve_bit_dont_care,
    output reg [15:0] jump_address_input
);
    always @ (posedge clk or posedge reset) begin
        if (reset) begin
            opcode <= 4'b0000;
            store_at <= 2'b00;
            operand_one <= 2'b00;
            operand_two <= 2'b00;
            reg_to_work_on <= 2'b00;
            six_bit_dont_care <= 6'b000_000;
            imm_value <= 16'b0000_0000_0000_0000;
            ten_bit_dont_care <= 10'b0000_0000_00;
            twelve_bit_dont_care <= 12'b0000_0000_0000;
            jump_address_input <= 12'b0000_0000_0000;
        end
        else begin
            opcode <= instruction[15:12];
            case (opcode)
                4'b0000: begin // ADD
                    store_at <= instruction[11:10];
                    operand_one <= instruction[9:8];
                    operand_two <= instruction[7:6];
                    six_bit_dont_care <= instruction[5:0];
                end
                4'b0001: begin // ADDI
                    store_at <= instruction[11:10];
                    imm_value <= {6'b000_000, instruction[9:0]};
                end
                4'b0010: begin // SUB
                    store_at <= instruction[11:10];
                    operand_one <= instruction[9:8];
                    operand_two <= instruction[7:6];
                    six_bit_dont_care <= instruction[5:0];
                end
                4'b0011: begin // SUBI
                    store_at <= instruction[11:10];
                    imm_value <= {6'b000_000, instruction[9:0]};
                end
                4'b0100: begin // MUL
                    store_at <= instruction[11:10];
                    operand_one <= instruction[9:8];
                    operand_two <= instruction[7:6];
                    six_bit_dont_care <= instruction[5:0];
                end
                4'b0101: begin // MULI
                    store_at <= instruction[11:10];
                    imm_value <= {6'b000_000, instruction[9:0]};
                end
                4'b0110: begin // DIV
                    store_at <= instruction[11:10];
                    operand_one <= instruction[9:8];
                    operand_two <= instruction[7:6];
                    six_bit_dont_care <= instruction[5:0];
                end
                4'b0111: begin // DIVI
                    store_at <= instruction[11:10];
                    imm_value <= {6'b000_000, instruction[9:0]};
                end
                4'b1000: begin // STOREI
                    reg_to_work_on <= instruction[9:8];
                    imm_value <= {8'b0000_0000, instruction[7:0]};
                end
                4'b1001: begin // JUMP
                    jump_address_input <= instruction[11:0];
                end
                4'b1010: begin // DELETE
                    reg_to_work_on <= instruction[11:10];
                    ten_bit_dont_care <= instruction[9:0];
                end
                4'b1011: begin // AND
                    store_at <= instruction[11:10];
                    operand_one <= instruction[9:8];
                    operand_two <= instruction[7:6];
                    six_bit_dont_care <= instruction[5:0];
                end
                4'b1100: begin // OR
                    store_at <= instruction[11:10];
                    operand_one <= instruction[9:8];
                    operand_two <= instruction[7:6];
                    six_bit_dont_care <= instruction[5:0];
                end
                4'b1101: begin // NOT
                    store_at <= instruction[11:10];
                    operand_one <= instruction[9:8];
                    operand_two <= instruction[7:6];
                    six_bit_dont_care <= instruction[5:0];
                end
                4'b1110: begin // XOR
                    store_at <= instruction[11:10];
                    operand_one <= instruction[9:8];
                    operand_two <= instruction[7:6];
                    six_bit_dont_care <= instruction[5:0];
                end
                4'b1111: twelve_bit_dont_care <= instruction[11:0]; // HALT
            endcase
        end
    end
endmodule
