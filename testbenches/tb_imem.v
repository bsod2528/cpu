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

// This testbench combines both the PC and the IMEM as it's a CPU.
// The IMEM works with the PC cause it's a CPU.
// Thus, I've combined the PC requirements here to, cause it's a CPU :joy:

// In all seriousness, we need to connect the IMEM and the PC together in order
// to check the integrity of the IMEM.

// Since IMEM is dependant on the PC, output of the PC would drive the input
// for IMEM and give us a valid output. Too many words, cannot comprehend.

// How in the single handed wild bizzare brain, did that mad-lad design the 4004.

module tb_imem();
    reg jump_enable, return_enable, clk, reset, imem_enable;
    reg [15:0] jump_address;
    wire [15:0] counter_reg, instruction;

    program_counter dut_pc(
        .counter_reg(counter_reg),
        .jump_enable(jump_enable),
        .jump_address(jump_address),
        .return_enable(return_enable),
        .clk(clk),
        .reset(reset)
    );

    instruction_memory dut_imem(
        .clk(clk),
        .address(counter_reg),
        .enable(imem_enable),
        .instruction(instruction)
    );

    always #5 clk = ~clk;

    initial begin
        clk = 0;
        reset = 1;
        jump_enable = 0;
        jump_address = 0;
        return_enable = 0;
        imem_enable = 0;

        #5 reset = 0; imem_enable = 1; jump_enable = 1; jump_address = 16'b0000_0000_0000_0100;
        #10 jump_enable = 0;
        #10 return_enable = 1;
        #5 return_enable = 0;
        #90 $finish;
    end
endmodule
