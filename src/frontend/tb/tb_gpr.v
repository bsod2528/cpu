`timescale 1ns / 1ps

module tb_gpr;
    reg clk;
    reg reset;
    reg write_enable;
    reg [1:0] store_at;
    reg [1:0] read_operand_one_reg;
    reg [1:0] read_operand_two_reg;
    reg [15:0] alu_result;

    wire write_done;
    wire [15:0] reg_a_out;
    wire [15:0] reg_b_out;
    wire [15:0] reg_c_out;
    wire [15:0] reg_d_out;
    wire [15:0] operand_one_reg;
    wire [15:0] operand_two_reg;

    gp_registers dut (
        .clk(clk),
        .reset(reset),
        .write_enable(write_enable),
        .store_at(store_at),
        .read_operand_one_reg(read_operand_one_reg),
        .read_operand_two_reg(read_operand_two_reg),
        .alu_result(alu_result),
        .write_done(write_done),
        .reg_a_out(reg_a_out),
        .reg_b_out(reg_b_out),
        .reg_c_out(reg_c_out),
        .reg_d_out(reg_d_out),
        .operand_one_reg(operand_one_reg),
        .operand_two_reg(operand_two_reg)
    );

    always #5 clk = ~clk;

    initial begin
        clk = 1'b0;
        reset = 1'b1;
        write_enable = 1'b0;
        store_at = 2'b00;
        read_operand_one_reg = 2'b00;
        read_operand_two_reg = 2'b01;
        alu_result = 16'h0000;

        @(posedge clk);
        reset = 1'b0;

        // Write r0.
        store_at = 2'b00;
        alu_result = 16'h1111;
        write_enable = 1'b1;
        @(posedge clk);
        #1;
        if (reg_a_out !== 16'h1111 || write_done !== 1'b1) begin
            $display("[FAIL] GPR write r0 failed r0=%h write_done=%b", reg_a_out, write_done);
            $fatal(1);
        end

        // Write r3.
        store_at = 2'b11;
        alu_result = 16'hAAAA;
        @(posedge clk);
        #1;
        if (reg_d_out !== 16'hAAAA) begin
            $display("[FAIL] GPR write r3 failed r3=%h", reg_d_out);
            $fatal(1);
        end

        // Readback mux.
        write_enable = 1'b0;
        read_operand_one_reg = 2'b00;
        read_operand_two_reg = 2'b11;
        #1;
        if (operand_one_reg !== 16'h1111 || operand_two_reg !== 16'hAAAA) begin
            $display("[FAIL] GPR read mux failed op1=%h op2=%h", operand_one_reg, operand_two_reg);
            $fatal(1);
        end

        $display("[PASS] tb_gpr");
        $finish;
    end
endmodule
