`timescale 1ns / 1ps

module tb_pc;
    reg clk;
    reg reset;
    reg increment;
    reg jump_enable;
    reg return_enable;
    reg flag_input;
    reg [15:0] jump_address;

    wire jump_done;
    wire [15:0] counter_reg;

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

    always #5 clk = ~clk;

    initial begin
        clk = 1'b0;
        reset = 1'b1;
        increment = 1'b0;
        jump_enable = 1'b0;
        return_enable = 1'b0;
        flag_input = 1'b0;
        jump_address = 16'h0000;

        @(posedge clk);
        reset = 1'b0;

        increment = 1'b1;
        repeat (3) @(posedge clk);
        #1;
        if (counter_reg !== 16'd4) begin
            $display("[FAIL] PC increment expected 4, got %0d", counter_reg);
            $fatal(1);
        end

        increment = 1'b0;
        jump_enable = 1'b1;
        jump_address = 16'h0033;
        @(posedge clk);
        #1;
        if (counter_reg !== 16'h0033 || jump_done !== 1'b1) begin
            $display("[FAIL] PC jump expected 0x0033 and jump_done=1, got pc=%h jump_done=%b", counter_reg, jump_done);
            $fatal(1);
        end

        jump_enable = 1'b0;
        @(posedge clk);
        #1;
        if (jump_done !== 1'b0) begin
            $display("[FAIL] jump_done should clear after jump, got %b", jump_done);
            $fatal(1);
        end

        return_enable = 1'b1;
        @(posedge clk);
        #1;
        if (counter_reg !== 16'd4) begin
            $display("[FAIL] PC return expected 4, got %0d", counter_reg);
            $fatal(1);
        end

        return_enable = 1'b0;
        flag_input = 1'b1;
        @(posedge clk);
        #1;
        if (counter_reg !== 16'd0) begin
            $display("[FAIL] PC halt flag expected 0, got %0d", counter_reg);
            $fatal(1);
        end

        // HALT (flag_input) should take priority over increment when both are asserted.
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
