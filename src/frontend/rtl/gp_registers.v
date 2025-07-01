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


module gp_registers(
    input wire clk,
    input wire reset,
    input wire write_enable,
    input wire [1:0] store_at,
    input wire [1:0] read_operand_one_reg,
    input wire [1:0] read_operand_two_reg,
    input wire [15:0] alu_result,

    output wire write_done,
    output wire [15:0] reg_a_out,
    output wire [15:0] reg_b_out,
    output wire [15:0] reg_c_out,
    output wire [15:0] reg_d_out,
    output reg [15:0] operand_one_reg,
    output reg [15:0] operand_two_reg
);
    reg write_done_reg;
    reg [15:0] reg_a;
    reg [15:0] reg_b;
    reg [15:0] reg_c;
    reg [15:0] reg_d;

    always @ (*) begin
        case (read_operand_one_reg)
            2'b00: operand_one_reg = reg_a;
            2'b01: operand_one_reg = reg_b;
            2'b10: operand_one_reg = reg_c;
            2'b11: operand_one_reg = reg_d;
        endcase
        case (read_operand_two_reg)
            2'b00: operand_two_reg = reg_a;
            2'b01: operand_two_reg = reg_b;
            2'b10: operand_two_reg = reg_c;
            2'b11: operand_two_reg = reg_d;
        endcase
    end

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            reg_a <= 16'b0000_0000_0000_0000;
            reg_b <= 16'b0000_0000_0000_0000;
            reg_c <= 16'b0000_0000_0000_0000;
            reg_d <= 16'b0000_0000_0000_0000;
            operand_one_reg <= 16'b0000_0000_0000_0000;
            operand_two_reg <= 16'b0000_0000_0000_0000;
        end

        else if (write_enable) begin
            case (store_at)
                2'b00: reg_a <= alu_result;
                2'b01: reg_b <= alu_result;
                2'b10: reg_c <= alu_result;
                2'b11: reg_d <= alu_result;
            endcase
            write_done_reg = 1'b1;
        end

        else
            write_done_reg = 1'b0;
    end

    assign reg_a_out = reg_a;
    assign reg_b_out = reg_b;
    assign reg_c_out = reg_c;
    assign reg_d_out = reg_d;
    assign write_done = write_done_reg;
endmodule
