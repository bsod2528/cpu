`timescale 1ns / 1ps

module tb_cu;
    reg clk;
    reg reset;

    reg alu_done;
    reg reg_write_done;
    reg jump_done;

    reg [1:0] store_at;
    reg [1:0] operand_one;
    reg [1:0] operand_two;
    reg [3:0] opcode;
    reg [15:0] immediate_value;
    reg [15:0] jump_address;

    wire enable_alu;
    wire enable_reg_write;
    wire enable_pc_increment;
    wire enable_jump;
    wire [1:0] select_operation;
    wire [1:0] reg_write_address;
    wire [1:0] reg_read_address_one;
    wire [1:0] reg_read_address_two;
    wire [15:0] operand_two_out;
    wire [15:0] jump_address_out;

    control_unit dut (
        .clk(clk),
        .reset(reset),
        .alu_done(alu_done),
        .reg_write_done(reg_write_done),
        .jump_done(jump_done),
        .store_at(store_at),
        .operand_one(operand_one),
        .operand_two(operand_two),
        .opcode(opcode),
        .immediate_value(immediate_value),
        .jump_address(jump_address),
        .enable_alu(enable_alu),
        .enable_reg_write(enable_reg_write),
        .enable_pc_increment(enable_pc_increment),
        .enable_jump(enable_jump),
        .select_operation(select_operation),
        .reg_write_address(reg_write_address),
        .reg_read_address_one(reg_read_address_one),
        .reg_read_address_two(reg_read_address_two),
        .operand_two_out(operand_two_out),
        .jump_address_out(jump_address_out)
    );

    always #5 clk = ~clk;

    initial begin
        clk = 1'b0;
        reset = 1'b1;
        alu_done = 1'b0;
        reg_write_done = 1'b0;
        jump_done = 1'b0;
        store_at = 2'b10;
        operand_one = 2'b00;
        operand_two = 2'b01;
        opcode = 4'b0000;
        immediate_value = 16'd5;
        jump_address = 16'd12;

        @(posedge clk);
        reset = 1'b0;

        // FETCH -> DECODE -> EXECUTE(ADD)
        @(posedge clk);
        @(posedge clk);
        #1;
        if (enable_alu !== 1'b1 || select_operation !== 2'b00) begin
            $display("[FAIL] CU EXECUTE(ADD) expected ALU enable and register mode");
            $fatal(1);
        end

        alu_done = 1'b1;
        @(posedge clk); // transition to WRITE
        #1;
        if (enable_reg_write !== 1'b1 || enable_pc_increment !== 1'b1) begin
            $display("[FAIL] CU WRITE expected reg_write and pc increment");
            $fatal(1);
        end

        alu_done = 1'b0;

        // Now test immediate path.
        opcode = 4'b0001; // ADDI
        @(posedge clk); // FETCH
        @(posedge clk); // DECODE
        @(posedge clk); // EXECUTE
        #1;
        if (enable_alu !== 1'b1 || select_operation !== 2'b01 || operand_two_out !== 16'd5) begin
            $display("[FAIL] CU EXECUTE(ADDI) expected immediate mode and imm operand");
            $fatal(1);
        end

        // Test jump path.
        opcode = 4'b1001;
        jump_done = 1'b0;
        @(posedge clk); // execute loop to jump state then assert enable_jump
        @(posedge clk);
        @(posedge clk);
        #1;
        if (enable_jump !== 1'b1 || jump_address_out !== 16'd12) begin
            $display("[FAIL] CU JUMP expected enable_jump and propagated jump_address");
            $fatal(1);
        end

        $display("[PASS] tb_cu");
        $finish;
    end
endmodule
