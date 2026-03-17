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

// =============================================================================
// File      : new_cpu.v
// Module    : vr16_cpu  (draft / work-in-progress)
// Brief     : Early-stage top-level module for the VR16 processor.
//
// Description:
//   This is a skeletal draft of the VR16 CPU top-level.  It instantiates the
//   program counter, instruction memory, and a stub instruction decoder with
//   an unconnected instruction port.  Signal widths on several wires are not
//   yet correct (e.g. pc_ip_jump_address is 1-bit; will be 16-bit in the
//   final design).
//
//   Refer to `vr16_cpu.v` for the current complete implementation.
//
// Inputs:
//   global_clk   - Master clock.
//   global_reset - Active-high reset.
// =============================================================================

module vr16_cpu(
    input wire global_clk,
    input wire global_reset
);

    // Internal wires connecting the program counter sub-module.
    wire pc_ip_increment;      // PC increment enable (not yet driven).
    wire pc_ip_jump_enable;    // PC jump enable (not yet driven).
    wire pc_ip_jump_address;   // Jump target address — NOTE: should be [15:0].
    wire pc_ip_return_enable;  // Return enable (not yet driven).
    wire pc_ip_flag_input;     // HALT flag (not yet driven).
    wire pc_op_jump_done;      // Jump-done acknowledgement from the PC.
    wire pc_op_counter_reg;    // PC output — NOTE: should be [15:0].

    // Internal wires connecting the instruction memory sub-module.
    wire im_ip_enable;         // IMEM read enable (not yet driven).
    wire im_ip_address;        // IMEM address — NOTE: should be [15:0].
    wire im_op_instruction;    // IMEM instruction output — NOTE: should be [15:0].
    
    // Step 1: Instantiate the program counter.
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

    // Step 2: Instantiate instruction memory.
    instruction_memory vr16_im(
        .clk(global_clk),
        .reset(global_reset),
        .enable(im_ip_enable),
        .address(im_ip_address),
        .instruction(im_op_instruction)
    );

    // Step 3: Instantiate instruction decoder (instruction port not yet connected).
    instruction_decoder vr16_id(
        .clk(global_clk),
        .reset(global_reset),
        .instruction()
    );



endmodule
