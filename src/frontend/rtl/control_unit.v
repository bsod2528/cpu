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


module control_unit(
    clk, reset,
    opcode, six_bit_dont_care, eight_bit_imm_val, ten_bit_dont_care, ten_bit_imm_val, operand_one, operand_two, store_at, twelve_bit_dont_care, jump_address_input, store_at_input
    ins_done, increment_ins_count,
    pc_reset_done, alu_enable, jump_done, write_done, reg_to_work_on,
    alu_result
);
    input clk, reset, ins_done, write_done, jump_done, pc_reset_done, alu_enable;
    input [1:0] store_at, store_at_input, operand_one, operand_two, reg_to_work_on;
    input [3:0] opcode;
    input [5:0] six_bit_dont_care;
    input [7:0] eight_bit_imm_val;
    input [9:0] ten_bit_dont_care, ten_bit_imm_val;
    input [11:0] twelve_bit_dont_care, jump_address_input;
    input [15:0] alu_result;

    output write_enable;
    output reg [1:0] flag_output;
    output wire increment_ins_count;

    reg _increment_ins_count;

    always @ (posedge clk or posedge reset) begin
        if (reset) begin
            _increment_ins_count <= 0;
            flag_output <= 2'b00;
        end
        else
            case (opcode)
                4'b0000: begin // ADD
                    alu_enable <= 1;
                    store_at <= store_at_input;
                    if (write_done)
                        _increment_ins_count <= 1;
                end
                4'b1000: begin
                    flag_output <= 2'b00; // STOREI
                    write_enable <= 1;
                    if (write_done)
                        _increment_ins_count <= 1;
                end
                4'b1001: begin // JUMP
                    flag_output <= 2'b01;
                    if (jump_done)
                        _increment_ins_count <= 1;
                end
                4'b1010: begin // DELETE
                    flag_output <= 2'b10;
                    if (write_done)
                        _increment_ins_count <= 1;
                end
                4'b1111: begin // HALT
                    flag_output <= 2'b11;
                    if (pc_reset_done)
                        _increment_ins_count <= 1;
                end
            endcase
    end

    assign increment_ins_count = _increment_ins_count;
endmodule
