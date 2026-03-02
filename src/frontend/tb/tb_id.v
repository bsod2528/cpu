`timescale 1ns / 1ps

module tb_id;
    reg clk;
    reg reset;
    reg [15:0] instruction;

    wire [1:0] operand_one;
    wire [1:0] operand_two;
    wire [1:0] store_at;
    wire [1:0] reg_to_work_on;
    wire [3:0] opcode;
    wire [15:0] imm_value;
    wire [15:0] six_bit_dont_care;
    wire [15:0] ten_bit_dont_care;
    wire [15:0] twelve_bit_dont_care;
    wire [15:0] jump_address_input;

    instruction_decoder dut (
        .clk(clk),
        .reset(reset),
        .instruction(instruction),
        .operand_one(operand_one),
        .operand_two(operand_two),
        .store_at(store_at),
        .reg_to_work_on(reg_to_work_on),
        .opcode(opcode),
        .imm_value(imm_value),
        .six_bit_dont_care(six_bit_dont_care),
        .ten_bit_dont_care(ten_bit_dont_care),
        .twelve_bit_dont_care(twelve_bit_dont_care),
        .jump_address_input(jump_address_input)
    );

    always #5 clk = ~clk;

    initial begin
        clk = 1'b0;
        reset = 1'b1;
        instruction = 16'h0000;

        #1;
        if (opcode !== 4'b0000) begin
            $display("[FAIL] ID reset opcode mismatch");
            $fatal(1);
        end

        reset = 1'b0;

        // ADD r2, r0, r1
        instruction = 16'b0000_10_00_01_000000;
        #1;
        if (opcode !== 4'b0000 || store_at !== 2'b10 || operand_one !== 2'b00 || operand_two !== 2'b01) begin
            $display("[FAIL] ID decode ADD failed opcode=%b store=%b op1=%b op2=%b", opcode, store_at, operand_one, operand_two);
            $fatal(1);
        end

        // ADDI r1, 3
        instruction = 16'b0001_01_0000000011;
        #1;
        if (opcode !== 4'b0001 || store_at !== 2'b01 || operand_one !== 2'b01 || imm_value !== 16'd3) begin
            $display("[FAIL] ID decode ADDI failed opcode=%b store=%b op1=%b imm=%d", opcode, store_at, operand_one, imm_value);
            $fatal(1);
        end

        // JUMP immediate address
        instruction = 16'b1001_000000001010;
        #1;
        if (opcode !== 4'b1001 || jump_address_input !== 16'd10) begin
            $display("[FAIL] ID decode JUMP failed opcode=%b jump=%d", opcode, jump_address_input);
            $fatal(1);
        end

        $display("[PASS] tb_id");
        $finish;
    end
endmodule
