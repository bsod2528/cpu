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
    // all below instantiated signals are present within for "connection" so that
    // all data is flows inside the cpu

    // program counter
    wire pc_increment_ip;
    wire pc_enable_jump_ip;
    wire pc_enable_return_ip;
    wire pc_flag_input_ip;
    wire [15:0] pc_jump_address_ip;
    wire pc_jump_done_op;
    wire [15:0] pc_counter_reg_op;

    // instruction memory
    wire im_enable_imem_ip;
    wire [15:0] im_instruction_op;

    // instruction decoder
    wire [1:0] id_operand_one_op;
    wire [1:0] id_operand_two_op;
    wire [1:0] id_store_at_op;
    wire [1:0] id_reg_to_work_on_op;
    wire [3:0] id_opcode_op;
    wire [15:0] id_imm_value_op;
    wire [15:0] id_six_bit_dont_care_op;
    wire [15:0] id_ten_bit_dont_care_op;
    wire [15:0] id_twelve_bit_dont_care_op;
    wire [15:0] id_jump_address_input_op;

    // control unit
    wire cu_enable_alu_op;
    wire cu_enable_reg_write_op;
    wire cu_enable_pc_increment_op;
    wire cu_enable_jump_op;
    wire [1:0] cu_select_operation_op;
    wire [1:0] cu_reg_write_address_op;
    wire [1:0] cu_reg_read_address_one_op;
    wire [1:0] cu_reg_read_address_two_op;
    wire [15:0] cu_operand_two_out_op;
    wire [15:0] cu_jump_address_out_op;

    // alu
    wire a_alu_done_op;
    wire [15:0] a_result_op;

    // gp registers
    wire gpr_write_done_op;
    wire [15:0] gpr_reg_a_out_op;
    wire [15:0] gpr_reg_b_out_op;
    wire [15:0] gpr_reg_c_out_op;
    wire [15:0] gpr_reg_d_out_op;
    wire [15:0] gpr_operand_one_reg_op;
    wire [15:0] gpr_operand_two_reg_op;

    // default connections
    assign im_enable_imem_ip = ~global_reset;
    assign pc_enable_jump_ip = cu_enable_jump_op;
    assign pc_jump_address_ip = cu_jump_address_out_op;
    assign pc_enable_return_ip = 1'b0;
    assign pc_flag_input_ip = (id_opcode_op == 4'b1111) ? 1'b1 : 1'b0;

    // extra muxed alu operand_two
    wire [15:0] alu_operand_two;
    assign alu_operand_two = (cu_select_operation_op == 2'b01 || cu_select_operation_op == 2'b10) ? cu_operand_two_out_op : gpr_operand_two_reg_op;

    // instantiation of modules, i.e., wiring up all parts
    program_counter vr16_pc(
        .clk(global_clk),
        .reset(global_reset),
        .increment(cu_enable_pc_increment_op),
        .jump_enable(pc_enable_jump_ip),
        .jump_address(pc_jump_address_ip),
        .jump_done(pc_jump_done_op),
        .return_enable(pc_enable_return_ip),
        .flag_input(pc_flag_input_ip),
        .counter_reg(pc_counter_reg_op)
    );

    instruction_memory vr16_im(
        .clk(global_clk),
        .reset(global_reset),
        .enable(im_enable_imem_ip),
        .address(pc_counter_reg_op),
        .instruction(im_instruction_op)
    );

    instruction_decoder vr16_id(
        .clk(global_clk),
        .reset(global_reset),
        .instruction(im_instruction_op),
        .operand_one(id_operand_one_op),
        .operand_two(id_operand_two_op),
        .store_at(id_store_at_op),
        .reg_to_work_on(id_reg_to_work_on_op),
        .opcode(id_opcode_op),
        .imm_value(id_imm_value_op),
        .six_bit_dont_care(id_six_bit_dont_care_op),
        .ten_bit_dont_care(id_ten_bit_dont_care_op),
        .twelve_bit_dont_care(id_twelve_bit_dont_care_op),
        .jump_address_input(id_jump_address_input_op)
    );

    control_unit vr16_cu(
        .clk(global_clk),
        .reset(global_reset),
        .alu_done(a_alu_done_op),
        .reg_write_done(gpr_write_done_op),
        .jump_done(pc_jump_done_op),
        .store_at(id_store_at_op),
        .operand_one(id_operand_one_op),
        .operand_two(id_operand_two_op),
        .opcode(id_opcode_op),
        .immediate_value(id_imm_value_op),
        .jump_address(id_jump_address_input_op),
        .enable_alu(cu_enable_alu_op),
        .enable_reg_write(cu_enable_reg_write_op),
        .enable_pc_increment(cu_enable_pc_increment_op),
        .enable_jump(cu_enable_jump_op),
        .select_operation(cu_select_operation_op),
        .reg_write_address(cu_reg_write_address_op),
        .reg_read_address_one(cu_reg_read_address_one_op),
        .reg_read_address_two(cu_reg_read_address_two_op),
        .operand_two_out(cu_operand_two_out_op),
        .jump_address_out(cu_jump_address_out_op)
    );

    alu vr16_alu(
        .clk(global_clk),
        .reset(global_reset),
        .alu_enable(cu_enable_alu_op),
        .opcode(id_opcode_op),
        .operand_one(gpr_operand_one_reg_op),
        .operand_two(alu_operand_two),
        .result(a_result_op),
        .alu_done(a_alu_done_op)
    );

    gp_registers vr16_regs(
        .clk(global_clk),
        .reset(global_reset),
        .write_enable(cu_enable_reg_write_op),
        .store_at(id_store_at_op),
        .read_operand_one_reg(cu_reg_read_address_one_op),
        .read_operand_two_reg(cu_reg_read_address_two_op),
        .alu_result(a_result_op),
        .write_done(gpr_write_done_op),
        .reg_a_out(gpr_reg_a_out_op),
        .reg_b_out(gpr_reg_b_out_op),
        .reg_c_out(gpr_reg_c_out_op),
        .reg_d_out(gpr_reg_d_out_op),
        .operand_one_reg(gpr_operand_one_reg_op),
        .operand_two_reg(gpr_operand_two_reg_op)
    );
endmodule
