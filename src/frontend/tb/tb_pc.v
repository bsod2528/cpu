// =============================================================================
// File      : tb_pc.v
// Module    : tb_pc
// Brief     : Testbench for the program counter module.
//
// Description:
//   Exercises all five control behaviours of the program counter in priority
//   order and verifies the expected counter value and jump_done flag:
//     1. Increment   — sequential execution advances the PC by 1 per cycle.
//     2. Jump        — loading a target address and asserting jump_done.
//     3. jump_done clear — jump_done de-asserts on the next cycle.
//     4. Return      — restoring the pre-jump address.
//     5. Halt flag   — forcing the PC to 0 when flag_input is asserted.
//     6. Halt priority — halt takes priority over increment when both are high.
// =============================================================================

`timescale 1ns / 1ps


module tb_pc;
    // -------------------------------------------------------------------------
    // Stimulus inputs driven by the testbench.
    // -------------------------------------------------------------------------
    reg clk;
    reg reset;
    reg increment;
    reg jump_enable;
    reg return_enable;
    reg flag_input;
    reg [15:0] jump_address;

    // -------------------------------------------------------------------------
    // Observed outputs from the DUT.
    // -------------------------------------------------------------------------
    wire jump_done;
    wire [15:0] counter_reg;

    // Step 1: Instantiate the program counter as the DUT.
    program_counter dut (
        .clk(clk),
        .reset(reset),
        .increment(increment),
        .jump_enable(jump_enable),
        .return_enable(return_enable),
        .flag_input(flag_input),
        .jump_address(jump_address),
        .jump_done(jump_done),
        .counter_reg(counter_reg)
    );

    // Step 2: Free-running clock with 10 ns period.
    always #5 clk = ~clk;

    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, tb_pc);

        // Step 3: Initialise all inputs to safe values and assert reset.
        clk = 1'b0;
        reset = 1'b1;
        increment = 1'b0;
        jump_enable = 1'b0;
        return_enable = 1'b0;
        flag_input = 1'b0;
        jump_address = 16'h0000;

        // Step 4: Release reset; PC should now be 0.
        @(posedge clk);
        reset = 1'b0;

        // Step 5: Increment test — assert increment for 3 cycles then verify
        //         the PC has advanced from 1 to 4 (reset cycle counts as 1).
        increment = 1'b1;
        repeat (3) @(posedge clk);
        #1;
        if (counter_reg !== 16'd4) begin
            $display("[FAIL] PC increment expected 4, got %0d", counter_reg);
            $fatal(1);
        end

        // Step 6: Jump test — de-assert increment, apply a jump, and verify
        //         the PC loads the target address with jump_done asserted.
        increment = 1'b0;
        jump_enable = 1'b1;
        jump_address = 16'h0033;
        @(posedge clk);
        #1;
        if (counter_reg !== 16'h0033 || jump_done !== 1'b1) begin
            $display("[FAIL] PC jump expected 0x0033 and jump_done=1, got pc=%h jump_done=%b", counter_reg, jump_done);
            $fatal(1);
        end

        // Step 7: jump_done clear — de-assert jump_enable and confirm
        //         jump_done clears on the next cycle.
        jump_enable = 1'b0;
        @(posedge clk);
        #1;
        if (jump_done !== 1'b0) begin
            $display("[FAIL] jump_done should clear after jump, got %b", jump_done);
            $fatal(1);
        end

        // Step 8: Return test — assert return_enable and confirm the PC
        //         restores the pre-jump address (4).
        return_enable = 1'b1;
        @(posedge clk);
        #1;
        if (counter_reg !== 16'd4) begin
            $display("[FAIL] PC return expected 4, got %0d", counter_reg);
            $fatal(1);
        end

        // Step 9: Halt flag test — assert flag_input and confirm the PC
        //         is forced to 0.
        return_enable = 1'b0;
        flag_input = 1'b1;
        @(posedge clk);
        #1;
        if (counter_reg !== 16'd0) begin
            $display("[FAIL] PC halt flag expected 0, got %0d", counter_reg);
            $fatal(1);
        end

        // HALT (flag_input) should take priority over increment when both are asserted.
        // Step 10: Assert both flag_input and increment to confirm halt has higher priority.
        flag_input = 1'b1;
        increment = 1'b1;
        @(posedge clk);
        #1;
        if (counter_reg !== 16'd0) begin
            $display("[FAIL] HALT priority expected 0 with increment+flag high, got %0d", counter_reg);
            $fatal(1);
        end

        $display("[PASS] tb_pc");
        $finish;
    end
endmodule
