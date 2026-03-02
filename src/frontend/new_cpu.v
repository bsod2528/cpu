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


module vr16_cpu(
    input wire global_clk,
    input wire global_reset
);

    wire pc_ip_increment;
    wire pc_ip_jump_enable;
    wire pc_ip_jump_address;
    wire pc_ip_return_enable;
    wire pc_ip_flag_input;
    wire pc_op_jump_done;
    wire pc_op_counter_reg;

    wire im_ip_enable;
    wire im_ip_address;
    wire im_op_instruction;
    
    program_counter vr16_pc(
        .clk(global_clk),
        .reset(global_reset),
        .increment(pc_ip_increment),
        .jump_enable(pc_ip_jump_enable),
        .jump_address(pc_ip_jump_address),
        .jump_done(pc_op_jump_done),
        .return_enable(pc_ip_return_enable),
        .flag_input(pc_ip_flag_input),
        .counter_reg(pc_op_counter_reg)
    );

    instruction_memory vr16_im(
        .clk(global_clk),
        .reset(global_reset),
        .enable(im_ip_enable),
        .address(im_ip_address),
        .instruction(im_op_instruction)
    );

    instruction_decoder vr16_id(
        .clk(global_clk),
        .reset(global_reset),
        .instruction()
    );



endmodule
