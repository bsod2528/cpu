`timescale 1ns / 1ps

// I've been spamming can you hear the music while doing this HAHA.
module program_counter(counter_reg, jump_enable, jump_address, return_enable, clk, reset);
    input jump_enable, return_enable, clk, reset;
    input [15:0] jump_address;
    output reg [15:0] counter_reg;

    reg [15:0] temp_address;

    always @ (posedge clk or posedge reset) begin
        if (reset)
            counter_reg <= 0;
        else if (jump_enable) begin
                temp_address <= counter_reg;
                counter_reg <= jump_address;
            end
        else if (return_enable)
            counter_reg <= temp_address;
        else
            counter_reg <= counter_reg + 1;
    end
endmodule
