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


module gp_registers (
    write_enable, write_done, clk, reset, store_at, alu_result, opcode,
    reg_a_out, reg_b_out, reg_c_out, reg_d_out
);
    input write_enable, write_done, clk, reset;
    input [1:0] store_at;
    input [15:0] alu_result;

    reg [15:0] reg_a;
    reg [15:0] reg_b;
    reg [15:0] reg_c;
    reg [15:0] reg_d;

    output [15:0] reg_a_out;
    output [15:0] reg_b_out;
    output [15:0] reg_c_out;
    output [15:0] reg_d_out;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            reg_a <= 16'b0000_0000_0000_0000;
            reg_b <= 16'b0000_0000_0000_0000;
            reg_c <= 16'b0000_0000_0000_0000;
            reg_d <= 16'b0000_0000_0000_0000;
        end
        else if (write_enable) begin
            case (store_at)
                2'b00: reg_a <= alu_result;
                2'b01: reg_b <= alu_result;
                2'b10: reg_c <= alu_result;
                2'b11: reg_d <= alu_result;
            endcase
            write_done <= 1;
        else
            write_done <= 0;
        end
    end

    assign reg_a_out = reg_a;
    assign reg_b_out = reg_b;
    assign reg_c_out = reg_c;
    assign reg_d_out = reg_d;
endmodule
