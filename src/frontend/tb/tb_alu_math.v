// =============================================================================
// File      : tb_alu_math.v
// Module    : tb_alu_math
// Brief     : Testbench for the ALU — arithmetic, logical, and edge-case ops.
//
// Description:
//   Drives all supported opcodes through the `alu` module and checks:
//     - Correct result value for each operation.
//     - `alu_done` assertion after each computation.
//   Tests are grouped into: basic arithmetic, logical operations,
//   immediate-mode arithmetic paths, overflow/underflow edge cases, and
//   division-by-zero behaviour (expected to produce unknown/X bits).
// =============================================================================

`timescale 1ns / 1ps


module tb_alu_math;
    // -------------------------------------------------------------------------
    // Stimulus inputs driven by the testbench.
    // -------------------------------------------------------------------------
    reg clk;
    reg reset;
    reg alu_enable;
    reg [3:0] opcode;
    reg [15:0] operand_one;
    reg [15:0] operand_two;

    // -------------------------------------------------------------------------
    // Observed outputs from the DUT.
    // -------------------------------------------------------------------------
    wire [15:0] result;
    wire alu_done;

    // Step 1: Instantiate the Device Under Test (DUT).
    alu uut (
        .clk(clk),
        .reset(reset),
        .alu_enable(alu_enable),
        .opcode(opcode),
        .operand_one(operand_one),
        .operand_two(operand_two),
        .result(result),
        .alu_done(alu_done)
    );

    // Step 2: Free-running clock with 10 ns period (5 ns half-period).
    always #5 clk = ~clk;

    // -------------------------------------------------------------------------
    // Reusable task: apply one ALU operation and verify result + done flag.
    // Parameters:
    //   op       - 4-bit opcode to apply.
    //   a        - 16-bit first operand.
    //   b        - 16-bit second operand.
    //   expected - Expected 16-bit result.
    //   label    - Human-readable test name for failure messages.
    // -------------------------------------------------------------------------
    task run_op;
        input [3:0] op;
        input [15:0] a;
        input [15:0] b;
        input [15:0] expected;
        input [127:0] label;
        begin
            // Step 3: Apply inputs to the DUT.
            opcode = op;
            operand_one = a;
            operand_two = b;
            alu_enable = 1'b1;
            // Step 4: Wait for the rising edge so the ALU latches the operation.
            @(posedge clk);
            #1;

            // Step 5: Verify the result matches the expected value.
            if (result !== expected) begin
                $display("[FAIL] %0s expected=%h got=%h", label, expected, result);
                $fatal(1);
            end

            // Step 6: Verify the done flag was asserted.
            if (alu_done !== 1'b1) begin
                $display("[FAIL] %0s alu_done was not asserted", label);
                $fatal(1);
            end

            // Step 7: De-assert enable and wait one cycle so the done flag clears.
            alu_enable = 1'b0;
            @(posedge clk);
        end
    endtask

    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, tb_alu_math);
        
        // Step 8: Initialise all inputs to known states before releasing reset.
        clk = 1'b0;
        reset = 1'b1;
        alu_enable = 1'b0;
        opcode = 4'b0000;
        operand_one = 16'h0000;
        operand_two = 16'h0000;

        // Step 9: Release reset after one clock edge.
        @(posedge clk);
        reset = 1'b0;

        // Basic arithmetic operations.
        run_op(4'b0000, 16'd1, 16'd2, 16'd3, "ADD 1 + 2");
        run_op(4'b0010, 16'd7, 16'd5, 16'd2, "SUB 7 - 5");
        run_op(4'b0100, 16'd7, 16'd3, 16'd21, "MUL 7 * 3");
        run_op(4'b0110, 16'd21, 16'd3, 16'd7, "DIV 21 / 3");

        // Logical operations.
        run_op(4'b1011, 16'h00F0, 16'h0FF0, 16'h00F0, "AND");
        run_op(4'b1100, 16'h00F0, 16'h0F0F, 16'h0FFF, "OR");
        run_op(4'b1110, 16'h00F0, 16'h0FF0, 16'h0F00, "XOR");
        run_op(4'b1101, 16'h00F0, 16'h0000, 16'hFF0F, "NOT");

        // Immediate arithmetic uses the same ALU opcode path.
        run_op(4'b0001, 16'd10, 16'd5, 16'd15, "ADDI behavior");
        run_op(4'b0011, 16'd10, 16'd5, 16'd5, "SUBI behavior");
        run_op(4'b0101, 16'd10, 16'd5, 16'd50, "MULI behavior");
        run_op(4'b0111, 16'd10, 16'd5, 16'd2, "DIVI behavior");

        // Edge cases.
        run_op(4'b0000, 16'hFFFF, 16'h0001, 16'h0000, "ADD overflow wraps");
        run_op(4'b0010, 16'h0000, 16'h0001, 16'hFFFF, "SUB underflow wraps");
        run_op(4'b0100, 16'h0100, 16'h0100, 16'h0000, "MUL overflow truncates");
        run_op(4'b0110, 16'h0000, 16'h0007, 16'h0000, "DIV zero numerator");

        // Division by zero should produce unknown bits in simulation.
        // Step 10: Drive a divide-by-zero scenario and confirm X propagation.
        opcode = 4'b0110;
        operand_one = 16'd5;
        operand_two = 16'd0;
        alu_enable = 1'b1;
        @(posedge clk);
        #1;
        if ((^result) !== 1'bx) begin
            $display("[FAIL] DIV by zero expected unknown result, got=%h", result);
            $fatal(1);
        end

        $display("[PASS] tb_alu_math");
        $finish;
    end
endmodule
