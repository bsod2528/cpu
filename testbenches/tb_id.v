`timescale 1ns / 1ps


module tb_id();
    reg jump_enable, return_enable, clk, reset, imem_enable;
    reg [15:0] jump_address;
    wire [15:0] counter_reg, instruction;
    wire [3:0] opcode, reg_a, reg_b, reg_c, reg_d, imm_value;

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

    // fun fact: I SPENT 2 FU**ING DAYS CAUSE OPCODE WAS ALWAYS FLIPPING IN Z STATE.
    // turns out I didn't even connect the opcode to my testbench 🗿🗿🗿.
    // ISTG.

    always #5 clk = ~clk;

    initial begin
        clk = 0;
        reset = 1;
        jump_enable = 0;
        jump_address = 0;
        return_enable = 0;
        imem_enable = 0;

        #5 reset = 0; imem_enable = 1;
        #45 $finish;
    end
endmodule
