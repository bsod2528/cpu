`timescale 1ns / 1ps

// Instruction bits be like:
// | 0000 | 0000 | 0000 | 0000 |
// | opcode | reg a | reg b | immediate value |

module instruction_decoder(instruction, clk, reset, opcode, reg_a, reg_b, imm_value);
    input clk, reset;
    input [15:0] instruction;
    output reg [3:0] opcode, reg_a, reg_b, imm_value; // imm_value == immediate value

    always @ (posedge clk or posedge reset) begin
        if (reset) begin
            opcode <= 4'b0000;
            reg_a <= 4'b0000;
            reg_b <= 4'b0000;
            imm_value <= 4'b0000;
        end
        else begin
            opcode <= instruction[15:12];
            reg_a <= instruction[11:8];
            reg_b <= instruction[7:4];
            imm_value <= instruction[3:0];
            $display("%b", opcode);
        end
    end
endmodule
