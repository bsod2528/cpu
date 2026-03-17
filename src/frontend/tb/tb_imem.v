// =============================================================================
// File      : tb_imem.v
// Module    : tb_imem
// Brief     : Testbench for the instruction memory module.
//
// Description:
//   Verifies that the instruction memory:
//     1. Outputs zero when reset is held.
//     2. Returns the correct 16-bit instruction word at address 0.
//     3. Returns the correct 16-bit instruction word at address 1.
//   The expected values match the first two entries in the default `.mem` file.
// =============================================================================
`timescale 1ns / 1ps

module tb_imem;
    // -------------------------------------------------------------------------
    // Stimulus inputs driven by the testbench.
    // -------------------------------------------------------------------------
    reg clk;
    reg reset;
    reg enable;
    reg [15:0] address;

    // -------------------------------------------------------------------------
    // Observed outputs from the DUT.
    // -------------------------------------------------------------------------
    wire [15:0] instruction;

    // Step 1: Instantiate the instruction memory as the DUT.
    // Uses the default MEM_FILE parameter ("mem/imem.mem").
    instruction_memory dut (
        .clk(clk),
        .reset(reset),
        .enable(enable),
        .address(address),
        .instruction(instruction)
    );

    // Step 2: Free-running clock with 10 ns period.
    always #5 clk = ~clk;

    initial begin
        // Step 3: Initialise all inputs and hold reset.
        clk = 1'b0;
        reset = 1'b1;
        enable = 1'b0;
        address = 16'd0;

        // Step 4: After one rising edge, confirm the instruction output is zero
        //         while reset is held.
        @(posedge clk);
        #1;
        if (instruction !== 16'h0000) begin
            $display("[FAIL] IMEM reset value expected 0, got %h", instruction);
            $fatal(1);
        end

        // Step 5: Release reset and enable the memory for reading at address 0.
        reset = 1'b0;
        enable = 1'b1;
        address = 16'd0;
        @(posedge clk);
        #1;
        // Step 6: Verify the instruction at address 0 matches the expected value.
        if (instruction !== 16'b0001000000000110) begin
            $display("[FAIL] IMEM addr0 mismatch got %b", instruction);
            $fatal(1);
        end

        // Step 7: Advance to address 1 and verify the next instruction.
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
