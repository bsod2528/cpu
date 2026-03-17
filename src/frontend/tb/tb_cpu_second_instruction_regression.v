// =============================================================================
// File      : tb_cpu_second_instruction_regression.v
// Module    : tb_cpu_second_instruction_regression
// Brief     : Regression testbench — verifies the CPU correctly executes
//             multiple sequential instructions.
//
// Description:
//   Loads a small three-instruction program via a dedicated `.mem` file and
//   checks that all three results land in the expected registers:
//     - r0 (reg_a) should equal 1 after the first instruction.
//     - r1 (reg_b) should equal 2 after the second instruction.
//     - r2 (reg_c) should equal 3 after the third instruction.
//   This was added as a regression guard after a bug where only the first
//   instruction executed correctly and subsequent instructions were skipped.
// =============================================================================
`timescale 1ns / 1ps

module tb_cpu_second_instruction_regression;
    // Testbench stimulus registers.
    reg clk;
    reg reset;

    // Step 1: Instantiate the VR16 CPU with the regression-specific `.mem` file.
    vr16_cpu #(
        .IMEM_FILE("src/frontend/tb/data/imem_second_instruction_regression.mem")
    ) uut (
        .global_clk(clk),
        .global_reset(reset)
    );

    // Step 2: Free-running clock with 10 ns period.
    always #5 clk = ~clk;

    initial begin
        // Step 3: Initialise and assert reset for one cycle.
        clk = 1'b0;
        reset = 1'b1;

        @(posedge clk);
        reset = 1'b0;

        // Wait enough cycles for the 3 instructions to complete.
        // Step 4: Allow 20 cycles — more than enough for the 5-stage pipeline
        //         to complete three write-back operations.
        repeat (20) @(posedge clk);
        #1;

        // Step 5: Verify r0 holds the result of the first instruction.
        if (uut.gpr_reg_a_out_op !== 16'd1) begin
            $display("[FAIL] r0 expected 1, got %0d", uut.gpr_reg_a_out_op);
            $fatal(1);
        end

        // Step 6: Verify r1 holds the result of the second instruction.
        if (uut.gpr_reg_b_out_op !== 16'd2) begin
            $display("[FAIL] r1 expected 2, got %0d", uut.gpr_reg_b_out_op);
            $fatal(1);
        end

        // Step 7: Verify r2 holds the result of the third instruction.
        if (uut.gpr_reg_c_out_op !== 16'd3) begin
            $display("[FAIL] r2 expected 3, got %0d", uut.gpr_reg_c_out_op);
            $fatal(1);
        end

        $display("[PASS] tb_cpu_second_instruction_regression");
        $finish;
    end
endmodule
