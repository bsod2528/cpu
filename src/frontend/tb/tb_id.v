// =============================================================================
// File      : tb_id.v
// Module    : tb_id
// Brief     : Testbench for the instruction decoder.
//
// Description:
//   Feeds manually constructed 16-bit instruction words into the decoder and
//   verifies the decoded output fields for three representative instructions:
//     1. Reset state — opcode must read as 0.
//     2. ADD  r2, r0, r1 — register-register arithmetic encoding.
//     3. ADDI r1, 3      — immediate arithmetic encoding.
//     4. JUMP 10         — jump address encoding.
// =============================================================================

`timescale 1ns / 1ps


module tb_id;
    // -------------------------------------------------------------------------
    // Stimulus inputs driven by the testbench.
    // -------------------------------------------------------------------------
    reg clk;
    reg reset;
    reg [15:0] instruction;

    // -------------------------------------------------------------------------
    // Observed outputs from the DUT.
    // -------------------------------------------------------------------------
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

    // Step 1: Instantiate the instruction decoder as the DUT.
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

    // Step 2: Free-running clock (decoder is combinational; clock not strictly
    //         needed but kept for consistency with the module port).
    always #5 clk = ~clk;

    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, tb_id);
        
        // Step 3: Initialise inputs and assert reset.
        clk = 1'b0;
        reset = 1'b1;
        instruction = 16'h0000;

        // Step 4: Confirm all outputs are zero while reset is held.
        #1;
        if (opcode !== 4'b0000) begin
            $display("[FAIL] ID reset opcode mismatch");
            $fatal(1);
        end

        // Step 5: Release reset; decoder is now live.
        reset = 1'b0;

        // ADD r2, r0, r1
        // Step 6: Drive an ADD instruction and verify all decoded fields.
        // Encoding: opcode=0000, store_at=10, op1=00, op2=01, dont_care=000000
        instruction = 16'b0000_10_00_01_000000;
        #1;
        if (opcode !== 4'b0000 || store_at !== 2'b10 || operand_one !== 2'b00 || operand_two !== 2'b01) begin
            $display("[FAIL] ID decode ADD failed opcode=%b store=%b op1=%b op2=%b", opcode, store_at, operand_one, operand_two);
            $fatal(1);
        end

        // ADDI r1, 3
        // Step 7: Drive an ADDI instruction and verify immediate field decoding.
        // Encoding: opcode=0001, store_at=01, imm10=0000000011 (= 3)
        instruction = 16'b0001_01_0000000011;
        #1;
        if (opcode !== 4'b0001 || store_at !== 2'b01 || operand_one !== 2'b01 || imm_value !== 16'd3) begin
            $display("[FAIL] ID decode ADDI failed opcode=%b store=%b op1=%b imm=%d", opcode, store_at, operand_one, imm_value);
            $fatal(1);
        end

        // JUMP immediate address
        // Step 8: Drive a JUMP instruction and verify jump_address_input decoding.
        // Encoding: opcode=1001, jump_target[11:0]=000000001010 (= 10)
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
