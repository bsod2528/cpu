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


module tb_pc();
    reg jump_enable, return_enable, clk, reset;
    reg [15:0] jump_address;
    wire [15:0] counter_reg;

    program_counter dut(
        .counter_reg(counter_reg),
        .jump_enable(jump_enable),
        .jump_address(jump_address),
        .return_enable(return_enable),
        .clk(clk),
        .reset(reset)
    );

    always #5 clk = ~clk;

    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, tb_pc);

        clk = 0;
        reset = 1;
        jump_enable = 0;
        jump_address = 0;
        return_enable = 0;

        #10 reset = 0;

        #20 jump_enable = 1; jump_address = 16'b0011001100110011;
        #10 jump_enable = 0;
        #10 return_enable = 1;
        #10 return_enable = 0;
        #10 $finish;
    end
endmodule
