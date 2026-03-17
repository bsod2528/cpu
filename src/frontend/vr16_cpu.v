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
// File      : vr16_cpu.v
// Module    : vr16_cpu
// Brief     : Top-level integration module for the VR16 16-bit RISC processor.
//
// Description:
//   Instantiates and wires together all sub-modules of the VR16 pipeline:
//     - program_counter     : maintains and updates the instruction address.
//     - instruction_memory  : holds the program; outputs the current instruction.
//     - instruction_decoder : decodes the 16-bit instruction word into fields.
//     - control_unit        : FSM that drives all enable and select signals.
//     - alu                 : performs arithmetic and logical computations.
//     - gp_registers        : four 16-bit general-purpose registers (r0-r3).
//
//   An extra combinational mux (`alu_operand_two`) selects between the
//   register-file read value and the immediate value forwarded by the control
//   unit, based on `select_operation`.
//
// Parameters:
//   IMEM_FILE - Path to the binary instruction memory initialisation file.
//               Default: "mem/imem.mem".
//
// Inputs:
//   global_clk   - Master clock for the entire processor.
//   global_reset - Active-high reset; propagated to every sub-module.
// =============================================================================

module vr16_cpu #(
    parameter IMEM_FILE = "mem/imem.mem"
)(
    input wire global_clk,
    input wire global_reset
);
    // all below instantiated signals are present within for "connection" so that
    // all data is flows inside the cpu

    // -------------------------
    // program counter signals
    // -------------------------
    wire pc_increment_ip;        // Drives the PC increment input from the CU.
    wire pc_enable_jump_ip;      // Drives PC jump enable; sourced from CU.
    wire pc_enable_return_ip;    // Drives PC return enable (tied low — unused).
    wire pc_flag_input_ip;       // Drives HALT flag; asserted when opcode == HALT.
    wire [15:0] pc_jump_address_ip;  // Jump target forwarded from the CU.
    wire pc_jump_done_op;        // Acknowledges a completed jump back to the CU.
    wire [15:0] pc_counter_reg_op;   // Current instruction address fed to IMEM.

    // ---------------------------
    // instruction memory signals
    // ---------------------------
    wire im_enable_imem_ip;       // IMEM read enable; de-asserted only on reset.
    wire [15:0] im_instruction_op; // Raw 16-bit instruction word from IMEM.

    // ----------------------------
    // instruction decoder signals
    // ----------------------------
    wire [1:0] id_operand_one_op;       // Source register 1 address.
    wire [1:0] id_operand_two_op;       // Source register 2 address.
    wire [1:0] id_store_at_op;          // Destination register address.
    wire [1:0] id_reg_to_work_on_op;    // Register for CJMP condition check.
    wire [3:0] id_opcode_op;            // 4-bit opcode.
    wire [15:0] id_imm_value_op;        // Zero-extended immediate value.
    wire [15:0] id_six_bit_dont_care_op;   // Lower 6 don't-care bits (debug).
    wire [15:0] id_ten_bit_dont_care_op;   // Lower 10 don't-care bits (debug).
    wire [15:0] id_twelve_bit_dont_care_op;// Lower 12 don't-care bits (debug).
    wire [15:0] id_jump_address_input_op;  // 12-bit jump address (zero-extended).

    // -----------------------
    // control unit signals
    // -----------------------
    wire cu_enable_alu_op;           // Triggers an ALU computation.
    wire cu_enable_reg_write_op;     // Triggers a register-file write.
    wire cu_enable_pc_increment_op;  // Advances the PC by 1.
    wire cu_enable_jump_op;          // Triggers a PC jump.
    wire [1:0] cu_select_operation_op;     // ALU operand-two mux select.
    wire [1:0] cu_reg_write_address_op;    // Write port address for the reg file.
    wire [1:0] cu_reg_read_address_one_op; // Read port 1 address for the reg file.
    wire [1:0] cu_reg_read_address_two_op; // Read port 2 address for the reg file.
    wire [15:0] cu_operand_two_out_op;  // Immediate forwarded from CU to ALU mux.
    wire [15:0] cu_jump_address_out_op; // Jump target forwarded from CU to PC.
    wire        cu_shift_dir_op;        // SHIFT direction: 0=SHL, 1=SHR.
    wire [8:0]  cu_shift_amount_op;     // SHIFT amount (9-bit).

    // -----------
    // alu signals
    // -----------
    wire a_alu_done_op;       // Pulses high when the ALU result is ready.
    wire [15:0] a_result_op;  // 16-bit ALU computation result.

    // -----------------------
    // gp registers signals
    // -----------------------
    wire gpr_write_done_op;          // Pulses high when a register write is done.
    wire [15:0] gpr_reg_a_out_op;    // Current value of r0.
    wire [15:0] gpr_reg_b_out_op;    // Current value of r1.
    wire [15:0] gpr_reg_c_out_op;    // Current value of r2.
    wire [15:0] gpr_reg_d_out_op;    // Current value of r3.
    wire [15:0] gpr_operand_one_reg_op; // Combinational read of operand 1.
    wire [15:0] gpr_operand_two_reg_op; // Combinational read of operand 2.

    // CJMP: mux the correct register value based on reg_to_work_on for condition check.
    wire [15:0] cu_reg_val_ip;
    assign cu_reg_val_ip =
        (id_reg_to_work_on_op == 2'b00) ? gpr_reg_a_out_op :
        (id_reg_to_work_on_op == 2'b01) ? gpr_reg_b_out_op :
        (id_reg_to_work_on_op == 2'b10) ? gpr_reg_c_out_op :
                                           gpr_reg_d_out_op;
    // CJMP condition bits come from ten_bit_dont_care[1:0] out of the decoder.
    wire [1:0] cu_cjmp_condition_ip;
    assign cu_cjmp_condition_ip = id_ten_bit_dont_care_op[1:0];

    // -------------------------------------------------------------------------
    // default connections
    // Tie constant or derived signals that are not driven by sub-module outputs.
    // -------------------------------------------------------------------------
    // IMEM is enabled whenever reset is not active.
    assign im_enable_imem_ip = ~global_reset;
    // Route the CU jump outputs directly to the PC inputs.
    assign pc_enable_jump_ip = cu_enable_jump_op;
    assign pc_jump_address_ip = cu_jump_address_out_op;
    // Return-enable is not yet used; tied to 0.
    assign pc_enable_return_ip = 1'b0;
    // Assert the HALT flag to the PC when the current opcode is HALT (1111).
    assign pc_flag_input_ip = (id_opcode_op == 4'b1111) ? 1'b1 : 1'b0;

    // -------------------------------------------------------------------------
    // extra muxed alu operand_two
    // When the CU signals an immediate or register+immediate operation, forward
    // the immediate value from the CU; otherwise pass the register-file read.
    // -------------------------------------------------------------------------
    wire [15:0] alu_operand_two;
    assign alu_operand_two = (cu_select_operation_op == 2'b01 || cu_select_operation_op == 2'b10) ? cu_operand_two_out_op : gpr_operand_two_reg_op;

    // -------------------------------------------------------------------------
    // instantiation of modules, i.e., wiring up all parts
    // -------------------------------------------------------------------------
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

    instruction_memory #(
        .MEM_FILE(IMEM_FILE)
    ) vr16_im(
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
        .reg_val(cu_reg_val_ip),
        .cjmp_condition(cu_cjmp_condition_ip),
        .enable_alu(cu_enable_alu_op),
        .enable_reg_write(cu_enable_reg_write_op),
        .enable_pc_increment(cu_enable_pc_increment_op),
        .enable_jump(cu_enable_jump_op),
        .select_operation(cu_select_operation_op),
        .reg_write_address(cu_reg_write_address_op),
        .reg_read_address_one(cu_reg_read_address_one_op),
        .reg_read_address_two(cu_reg_read_address_two_op),
        .operand_two_out(cu_operand_two_out_op),
        .jump_address_out(cu_jump_address_out_op),
        .shift_dir(cu_shift_dir_op),
        .shift_amount(cu_shift_amount_op)
    );

    alu vr16_alu(
        .clk(global_clk),
        .reset(global_reset),
        .alu_enable(cu_enable_alu_op),
        .opcode(id_opcode_op),
        .operand_one(gpr_operand_one_reg_op),
        .operand_two(alu_operand_two),
        .shift_dir(cu_shift_dir_op),
        .shift_amount(cu_shift_amount_op),
        .result(a_result_op),
        .alu_done(a_alu_done_op)
    );

    gp_registers vr16_regs(
        .clk(global_clk),
        .reset(global_reset),
        .write_enable(cu_enable_reg_write_op),
        .store_at(cu_reg_write_address_op),
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
