`timescale 1ns / 1ps

module tb_imem;
    reg clk;
    reg reset;
    reg enable;
    reg [15:0] address;

    wire [15:0] instruction;

    instruction_memory dut (
        .clk(clk),
        .reset(reset),
        .enable(enable),
        .address(address),
        .instruction(instruction)
    );

    always #5 clk = ~clk;

    initial begin
        clk = 1'b0;
        reset = 1'b1;
        enable = 1'b0;
        address = 16'd0;

        @(posedge clk);
        #1;
        if (instruction !== 16'h0000) begin
            $display("[FAIL] IMEM reset value expected 0, got %h", instruction);
            $fatal(1);
        end

        reset = 1'b0;
        enable = 1'b1;
        address = 16'd0;
        @(posedge clk);
        #1;
        if (instruction !== 16'b0001000000000110) begin
            $display("[FAIL] IMEM addr0 mismatch got %b", instruction);
            $fatal(1);
        end

        address = 16'd1;
        @(posedge clk);
        #1;
        if (instruction !== 16'b0001010000000011) begin
            $display("[FAIL] IMEM addr1 mismatch got %b", instruction);
            $fatal(1);
        end

        $display("[PASS] tb_imem");
        $finish;
    end
endmodule
