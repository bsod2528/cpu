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


module control_unit(clk, reset, input_flag, ins_done, increment_ins_count);
    input [1:0] input_flag;
    input clk, reset, ins_done;
    output reg [1:0] output_flag;
    output wire increment_ins_count;

    reg _increment_ins_count;

    always @ (posedge clk or posedge reset) begin
        if (reset)
            _increment_ins_count <= 0;
        else if (ins_done)
            _increment_ins_count <= 1;
        else
            _increment_ins_count <= 0;

        case (input_flag)
            2'b00: output_flag <= 2'b00;
            2'b01: output_flag <= 2'b01;
            2'b10: output_flag <= 2'b10;
            2'b11: output_flag <= 2'b11;
        endcase
    end

    assign increment_ins_count = _increment_ins_count;
endmodule
