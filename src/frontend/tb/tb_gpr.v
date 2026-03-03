// =============================================================================
// File      : tb_gpr.v
// Module    : tb_gpr
// Brief     : Testbench for the general-purpose register file.
//
// Description:
//   Tests the register file write path, read-back mux, and robustness under
//   unknown (X) selector values:
//     1. Reset state — write_done must be de-asserted after reset.
//     2. Write r0 — confirm register value and write_done assertion.
//     3. Write r3 — confirm a non-adjacent register write.
//     4. Read-back mux — confirm operand_one_reg and operand_two_reg route
//        to the correct registers after write_enable is de-asserted.
//     5. Unknown selector — confirm zero is returned for X-valued addresses.
// =============================================================================
`timescale 1ns / 1ps

module tb_gpr;
    // -------------------------------------------------------------------------
    // Stimulus inputs driven by the testbench.
    // -------------------------------------------------------------------------
    reg clk;
    reg reset;
    reg write_enable;
    reg [1:0] store_at;
    reg [1:0] read_operand_one_reg;
    reg [1:0] read_operand_two_reg;
    reg [15:0] alu_result;

    // -------------------------------------------------------------------------
    // Observed outputs from the DUT.
    // -------------------------------------------------------------------------
    wire write_done;
    wire [15:0] reg_a_out;
    wire [15:0] reg_b_out;
    wire [15:0] reg_c_out;
    wire [15:0] reg_d_out;
    wire [15:0] operand_one_reg;
    wire [15:0] operand_two_reg;

    // Step 1: Instantiate the register file as the DUT.
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

    // Step 2: Free-running clock with 10 ns period.
    always #5 clk = ~clk;

    initial begin
        // Step 3: Initialise all inputs to safe values and assert reset.
        clk = 1'b0;
        reset = 1'b1;
        write_enable = 1'b0;
        store_at = 2'b00;
        read_operand_one_reg = 2'b00;
        read_operand_two_reg = 2'b01;
        alu_result = 16'h0000;

        // Step 4: After one rising edge, confirm reset cleared write_done.
        @(posedge clk);
        #1;
        if (write_done !== 1'b0) begin
            $display("[FAIL] GPR reset write_done not cleared write_done=%b", write_done);
            $fatal(1);
        end
        reset = 1'b0;

        // Write r0.
        // Step 5: Write the value 0x1111 into register r0 (store_at = 00).
        store_at = 2'b00;
        alu_result = 16'h1111;
        write_enable = 1'b1;
        @(posedge clk);
        #1;
        // Step 6: Verify reg_a_out holds the written value and write_done is set.
        if (reg_a_out !== 16'h1111 || write_done !== 1'b1) begin
            $display("[FAIL] GPR write r0 failed r0=%h write_done=%b", reg_a_out, write_done);
            $fatal(1);
        end

        // Write r3.
        // Step 7: Write the value 0xAAAA into register r3 (store_at = 11).
        store_at = 2'b11;
        alu_result = 16'hAAAA;
        @(posedge clk);
        #1;
        // Step 8: Verify reg_d_out holds the written value.
        if (reg_d_out !== 16'hAAAA) begin
            $display("[FAIL] GPR write r3 failed r3=%h", reg_d_out);
            $fatal(1);
        end

        // Readback mux.
        // Step 9: De-assert write_enable and check that the read mux returns
        //         the correct register values for each operand address.
        write_enable = 1'b0;
        read_operand_one_reg = 2'b00; // Should return r0 = 0x1111
        read_operand_two_reg = 2'b11; // Should return r3 = 0xAAAA
        #1;
        if (operand_one_reg !== 16'h1111 || operand_two_reg !== 16'hAAAA) begin
            $display("[FAIL] GPR read mux failed op1=%h op2=%h", operand_one_reg, operand_two_reg);
            $fatal(1);
        end


        // Unknown selector robustness checks.
        // Step 10: Apply X-valued selectors and verify zero is returned safely.
        read_operand_one_reg = 2'b0x;
        read_operand_two_reg = 2'bx1;
        #1;
        if (operand_one_reg !== 16'h0000 || operand_two_reg !== 16'h0000) begin
            $display("[FAIL] GPR unknown selector handling failed op1=%h op2=%h", operand_one_reg, operand_two_reg);
            $fatal(1);
        end

        $display("[PASS] tb_gpr");
        $finish;
    end
endmodule
