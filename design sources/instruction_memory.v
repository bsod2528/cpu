`timescale 1ns / 1ps

// Instruction memory, it stores all the instructions that I set. Basically my actual instruction-set for what I'm creating.
// Gonna name this v-risc cause :moyai:
// Have to mention the inspiration for this: https://www.edaplayground.com/x/iCVx
// Thanks eda playground && whoever wrote that (they won't read but still, it's from the bottom of my heart)

module instruction_memory(clk, reset, address, enable, instruction);
    input clk, reset, enable;
    input [15:0] address;
    output reg [15:0] instruction;
    
    reg [15:0] imem [255:0]; // just 256 instructions for now which will.
    
    initial begin
        instruction = 16'b0000_0000_0000_0000;
        $readmemb("C:/cpu/cpu.srcs/sources_1/new/imem.mem", imem);
    end
    
    always @ (posedge clk or reset) begin
        $display("AT: %t", $time);
        if (reset)
            instruction <= 16'b0000_0000_0000_0000;
        else if (enable)
            instruction <= imem[address];
    end
endmodule
