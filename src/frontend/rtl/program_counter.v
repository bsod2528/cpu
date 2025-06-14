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

// I've been spamming can you hear the music while doing this HAHA.
module program_counter(
    input clk,
    input reset,
    input ins_count,
    input jump_enable,
    input return_enable,
    input [1:0] flag_input,
    input [15:0] jump_address,

    output reg [15:0] counter_reg
);
    reg [15:0] temp_address;

    always @ (posedge clk or posedge reset) begin
        if (reset)
            counter_reg <= 16'b0000_0000_0000_0000;
        else if (ins_count) begin
            if (jump_enable) begin
                temp_address <= counter_reg;
                counter_reg <= jump_address;
            end
            else if (return_enable)
                counter_reg <= temp_address;
            else if (flag_input == 2'b11)
                counter_reg <= 16'b0000_0000_0000_0000;
            else
                counter_reg <= counter_reg + 1;
        end
    end
endmodule
