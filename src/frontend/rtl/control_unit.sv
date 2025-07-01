// VR16: A basic 16-bit RISC processor
// Copyright (C) 2025 Vishal Srivatsava AV
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program. If not, see <https://www.gnu.org/licenses/>.

`timescale 1ns / 1ps


module control_unit(
    input wire clk,
    input wire reset,

    // signals
    input wire alu_done,
    input wire reg_write_done,
    input wire jump_done,

    // from the instruction decoder
    input wire [1:0] store_at,
    input wire [1:0] operand_one,
    input wire [1:0] operand_two,
    input wire [3:0] opcode,
    input wire [15:0] immediate_value,
    input wire [15:0] jump_address,

    // output signals
    output reg enable_alu,
    output reg enable_reg_write,
    output reg enable_pc_increment,
    output reg enable_jump,
    output reg [1:0] select_operation, // 00 == register alone, 01 == immediate alone, 10 == register + immediate

    // data path controls
    output reg [1:0] reg_write_address,
    output reg [1:0] reg_read_address_one,
    output reg [1:0] reg_read_address_two,
    output reg [15:0] operand_two_out, // sometimes operand_two is an immediate value, so yeah this takes care of that.
    output reg [15:0] jump_address_out
);

    typedef enum logic [2:0] {
        FETCH = 3'b000,
        DECODE = 3'b001,
        EXECUTE = 3'b010,
        WRITE = 3'b011,
        JUMP = 3'b100,
        HALT = 3'b111
    } state_t;

    state_t current_state, next_state;

    // parameter FETCH = 3'b000;
    // parameter DECODE = 3'b001;
    // parameter EXECUTE = 3'b010;
    // parameter WRITE = 3'b011;
    // parameter JUMP = 3'b100;
    // parameter HALT = 3'b111;

    // reg [2:0] current_state, next_state;

    always @ (posedge clk or posedge reset) begin
        if (reset)
            current_state <= FETCH;
        else
            current_state <= next_state;
    end

    always @ (*) begin
        enable_alu = 1'b0;
        enable_reg_write = 1'b0;
        enable_jump = 1'b0;
        enable_pc_increment = 1'b0;
        select_operation = 2'b00;
        next_state = current_state;

        reg_write_address = store_at;
        reg_read_address_one = operand_one;
        reg_read_address_two = operand_two;
        jump_address_out = jump_address;

        case (current_state)
            FETCH: begin
                next_state = DECODE;
            end

            DECODE: begin
                next_state = EXECUTE;
            end

            EXECUTE: begin
                case (opcode)
                    // alu register operations
                    4'b0000, 4'b0010, 4'b0100, 4'b0110, 4'b1011, 4'b1100, 4'b1101, 4'b1110: begin
                        enable_alu = 1'b1;
                        select_operation = 2'b00;
                        // if (alu_done)
                        //     next_state = WRITE;
                        next_state = WRITE;
                    end

                    // alu immediate operations
                    4'b0001, 4'b0011, 4'b0101, 4'b0111: begin
                        enable_alu = 1'b1;
                        select_operation = 2'b01;
                        // if (alu_done)
                        //     next_state = WRITE;
                        next_state = WRITE;
                    end

                    // jump
                    4'b1001: next_state = JUMP;

                    // halt
                    4'b1111: next_state = HALT;
                endcase
            end

            WRITE: begin
                enable_reg_write = 1'b1;
                next_state = FETCH;
                enable_pc_increment = 1'b1;
                // if (reg_write_done) begin
                //     next_state = FETCH;
                //     enable_pc_increment = 1'b1;
                // end
            end

            JUMP: begin
                enable_jump = 1'b1;
                if (jump_done)
                    next_state = FETCH;
            end

            HALT: next_state = HALT;
        endcase

        operand_two_out = (select_operation == 2'b01 || select_operation == 2'b10) ? immediate_value: 16'h0000;
    end
endmodule
