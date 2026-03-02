`timescale 1ns / 1ps

module tb_cpu_second_instruction_regression;
    reg clk;
    reg reset;

    vr16_cpu #(
        .IMEM_FILE("src/frontend/tb/data/imem_second_instruction_regression.mem")
    ) uut (
        .global_clk(clk),
        .global_reset(reset)
    );

    always #5 clk = ~clk;

    initial begin
        clk = 1'b0;
        reset = 1'b1;

        @(posedge clk);
        reset = 1'b0;

        // Wait enough cycles for the 3 instructions to complete.
        repeat (20) @(posedge clk);
        #1;

        if (uut.gpr_reg_a_out_op !== 16'd1) begin
            $display("[FAIL] r0 expected 1, got %0d", uut.gpr_reg_a_out_op);
            $fatal(1);
        end

        if (uut.gpr_reg_b_out_op !== 16'd2) begin
            $display("[FAIL] r1 expected 2, got %0d", uut.gpr_reg_b_out_op);
            $fatal(1);
        end

        if (uut.gpr_reg_c_out_op !== 16'd3) begin
            $display("[FAIL] r2 expected 3, got %0d", uut.gpr_reg_c_out_op);
            $fatal(1);
        end

        $display("[PASS] tb_cpu_second_instruction_regression");
        $finish;
    end
endmodule
