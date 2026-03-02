`timescale 1ns / 1ps

module tb_alu_math;
    reg clk;
    reg reset;
    reg alu_enable;
    reg [3:0] opcode;
    reg [15:0] operand_one;
    reg [15:0] operand_two;

    wire [15:0] result;
    wire alu_done;

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

    always #5 clk = ~clk;

    task run_op;
        input [3:0] op;
        input [15:0] a;
        input [15:0] b;
        input [15:0] expected;
        input [127:0] label;
        begin
            opcode = op;
            operand_one = a;
            operand_two = b;
            alu_enable = 1'b1;
            @(posedge clk);
            #1;

            if (result !== expected) begin
                $display("[FAIL] %0s expected=%h got=%h", label, expected, result);
                $fatal(1);
            end

            if (alu_done !== 1'b1) begin
                $display("[FAIL] %0s alu_done was not asserted", label);
                $fatal(1);
            end

            alu_enable = 1'b0;
            @(posedge clk);
        end
    endtask

    initial begin
        clk = 1'b0;
        reset = 1'b1;
        alu_enable = 1'b0;
        opcode = 4'b0000;
        operand_one = 16'h0000;
        operand_two = 16'h0000;

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
