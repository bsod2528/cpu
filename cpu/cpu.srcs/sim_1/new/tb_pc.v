`timescale 1ns / 1ps


module tb_pc();
    reg jump_enable, return_enable, clk, reset;
    reg [15:0] jump_address;
    wire [15:0] counter_reg;
    
    program_counter dut(
        .counter_reg(counter_reg),
        .jump_enable(jump_enable),
        .jump_address(jump_address),
        .return_enable(return_enable),
        .clk(clk),
        .reset(reset)
    );
    
    always #5 clk = ~clk;
    
    initial begin
        clk = 0;
        reset = 1;
        jump_enable = 0;
        jump_address = 0;
        return_enable = 0;
        
        #10 reset = 0;
        
        #20 jump_enable = 1; jump_address = 16'b0011001100110011;
        #10 jump_enable = 0;
        #10 return_enable = 1;
        #10 return_enable = 0;
        #10 $finish;
    end
endmodule
