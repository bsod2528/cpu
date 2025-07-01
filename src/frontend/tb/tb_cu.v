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

// Just testing the control signal here, so no need to connect the gp registers for now.
`timescale 1ns / 1ps


module tb_cs();
    reg jump_enable, return_enable, clk, reset, imem_enable, ins_done;
    reg [15:0] jump_address;
    wire [15:0] counter_reg, instruction;
    wire [3:0] opcode, reg_a, reg_b, reg_c, reg_d, imm_value;
    wire ins_count;

    program_counter dut_pc(
        .ins_count(ins_count),
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

    instruction_decoder dut_id(
        .instruction(instruction),
        .clk(clk),
        .opcode(opcode),
        .reset(reset),
        .reg_a(reg_a),
        .reg_b(reg_b),
        .reg_c(reg_c),
        .reg_d(reg_d),
        .imm_value(imm_value)
    );

    control_unit dut_cs(
        .clk(clk),
        .reset(reset),
        .ins_done(ins_done),
        .ins_count(ins_count)
    );

    always #5 clk = ~clk;

    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, tb_cs);

        clk = 0;
        reset = 1;
        jump_enable = 0;
        jump_address = 0;
        return_enable = 0;
        imem_enable = 0;
        ins_done = 0;

        #5 reset = 0; imem_enable = 1; ins_done = 1;
        #10 ins_done = 0;
        #50 $finish;
    end
endmodule
