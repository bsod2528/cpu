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

// =============================================================================
// File      : instruction_decoder.v
// Module    : instruction_decoder
// Brief     : Combinational instruction decoder for the VR16 processor.
//
// Description:
//   Decodes a 16-bit instruction word into its constituent fields so that
//   the control unit and data-path can act on them independently.
//   The decoder is fully combinational (always @(*)) so decoded fields
//   are valid one gate-delay after the instruction input changes.
//
//   On reset, all output registers are forced to zero.
//
//   Instruction format (generic layout — see ISA.md for per-opcode details):
//     [15:12] opcode          (4 bits)
//     [11:10] store_at        (destination register address)
//     [ 9: 8] operand_one     (source register 1 address)
//     [ 7: 6] operand_two     (source register 2 address)
//     [ 5: 0] dont-care / immediate / jump address (depends on opcode)
//
// Inputs:
//   clk         - Clock (connected but decoder is combinational; unused here).
//   reset       - Active-high reset; forces all outputs to zero.
//   instruction - 16-bit instruction word from the instruction memory.
//
// Outputs:
//   operand_one         - 2-bit source register 1 address.
//   operand_two         - 2-bit source register 2 address.
//   store_at            - 2-bit destination register address.
//   reg_to_work_on      - 2-bit register address for STOREI / DELETE ops.
//   opcode              - 4-bit operation code.
//   imm_value           - 16-bit zero-extended immediate value.
//   six_bit_dont_care   - 16-bit zero-extended lower 6 bits (unused fields).
//   ten_bit_dont_care   - 16-bit zero-extended lower 10 bits (unused fields).
//   twelve_bit_dont_care- 16-bit zero-extended lower 12 bits (unused fields).
//   jump_address_input  - 16-bit zero-extended 12-bit jump target address.
// =============================================================================

// Instruction bits be like:
// | 0000 | 00 | 00 | 00 | 00 | 0000 |
// | opcode | reg a | reg b | reg c | reg d | immediate value |

// bsod2528: Yeah so the above is generic split up, the format will change according to the `opcode`
// bsod2528: Refer to `ISA.md` on root directory to see the split-up / IS format for each opcode.

// bsod2528: MISC: It's 22-06-2025 as of me re-reading this, idk what i've done :skull:
// Saint: You've built a working instruction decoder — that's what you've done!
module instruction_decoder(
    input wire clk,
    input wire reset,
    input wire [15:0] instruction,

    output reg [1:0] operand_one,
    output reg [1:0] operand_two,
    output reg [1:0] store_at,
    output reg [1:0] reg_to_work_on,
    output reg [3:0] opcode,
    output reg [15:0] imm_value,
    output reg [15:0] six_bit_dont_care,    // idk im raw doggin
    output reg [15:0] ten_bit_dont_care,
    output reg [15:0] twelve_bit_dont_care,
    output reg [15:0] jump_address_input
);
    // -------------------------------------------------------------------------
    // Combinational decode block.
    // Note: originally clocked (posedge clk); changed to always @(*) so that
    //       decoded fields update immediately when `instruction` changes.
    // -------------------------------------------------------------------------
    // always @ (posedge clk or posedge reset) begin
    always @ (*) begin
        // Step 1: On reset, force every output to a known-zero state.
        if (reset) begin
            opcode = 4'b0000;
            store_at = 2'b00;
            operand_one = 2'b00;
            operand_two = 2'b00;
            reg_to_work_on = 2'b00;
            six_bit_dont_care = 16'h0000;
            imm_value = 16'b0000_0000_0000_0000;
            ten_bit_dont_care = 16'h0000;
            twelve_bit_dont_care = 16'h0000;
            jump_address_input = 16'h0000;
        end
        else begin

            // Step 2: Default all output fields to zero so that fields not
            //         used by the current opcode are never left undefined.
            store_at = 2'b00;
            operand_one = 2'b00;
            operand_two = 2'b00;
            reg_to_work_on = 2'b00;
            imm_value = 16'b0000_0000_0000_0000;
            six_bit_dont_care = 16'b0000_0000_0000_0000;
            ten_bit_dont_care = 16'b0000_0000_0000_0000;
            twelve_bit_dont_care = 16'b0000_0000_0000_0000;
            jump_address_input = 16'b0000_0000_0000_0000;

            // this was previous `opcode <= instruction[15:12]`
            // Saint: Good note — the blocking vs non-blocking distinction matters
            // Saint: a lot in combinational blocks. `=` is correct here.
            // Step 3: Extract the 4-bit opcode from the top nibble.
            opcode = instruction[15:12];
            // Step 4: Decode remaining fields based on the opcode.
            case (opcode)
                4'b0000: begin // ADD
                    // R[store_at] <- R[operand_one] + R[operand_two]
                    store_at = instruction[11:10];
                    operand_one = instruction[9:8];
                    operand_two = instruction[7:6];
                    six_bit_dont_care = {10'b0, instruction[5:0]};
                end
                4'b0001: begin // ADDI
                    // R[store_at] <- R[store_at] + zero_extend(imm10)
                    store_at = instruction[11:10];
                    operand_one = instruction[11:10];  // accumulator source == destination register
                    operand_two = 2'b00;               // unused for immediate arithmetic encoding
                    imm_value = {6'b000_000, instruction[9:0]};
                end
                4'b0010: begin // SUB
                    // R[store_at] <- R[operand_one] - R[operand_two]
                    store_at = instruction[11:10];
                    operand_one = instruction[9:8];
                    operand_two = instruction[7:6];
                    six_bit_dont_care = {10'b0, instruction[5:0]};
                end
                4'b0011: begin // SUBI
                    // R[store_at] <- R[store_at] - zero_extend(imm10)
                    store_at = instruction[11:10];
                    operand_one = instruction[11:10];  // accumulator source == destination register
                    operand_two = 2'b00;               // unused for immediate arithmetic encoding
                    imm_value = {6'b000_000, instruction[9:0]};
                end
                4'b0100: begin // MUL
                    // R[store_at] <- R[operand_one] * R[operand_two]
                    store_at = instruction[11:10];
                    operand_one = instruction[9:8];
                    operand_two = instruction[7:6];
                    six_bit_dont_care = {10'b0, instruction[5:0]};
                end
                4'b0101: begin // MULI
                    // R[store_at] <- R[store_at] * zero_extend(imm10)
                    store_at = instruction[11:10];
                    operand_one = instruction[11:10];  // accumulator source == destination register
                    operand_two = 2'b00;               // unused for immediate arithmetic encoding
                    imm_value = {6'b000_000, instruction[9:0]};
                end
                4'b0110: begin // DIV
                    // R[store_at] <- R[operand_one] / R[operand_two]
                    store_at = instruction[11:10];
                    operand_one = instruction[9:8];
                    operand_two = instruction[7:6];
                    six_bit_dont_care = {10'b0, instruction[5:0]};
                end
                4'b0111: begin // DIVI
                    // R[store_at] <- R[store_at] / zero_extend(imm10)
                    store_at = instruction[11:10];
                    operand_one = instruction[11:10];  // accumulator source == destination register
                    operand_two = 2'b00;               // unused for immediate arithmetic encoding
                    imm_value = {6'b000_000, instruction[9:0]};
                end
                4'b1000: begin // SHIFT
                    store_at = instruction[11:10];
                    imm_value = {6'b0, instruction[9], instruction[8:0]};
                end
                4'b1001: begin // JUMP
                    // PC <- zero_extend(instruction[11:0])
                    jump_address_input = {4'b0, instruction[11:0]};
                end
                4'b1010: begin // CJMP (conditional jump)
                    reg_to_work_on = instruction[11:10];
                    imm_value      = {8'b0, instruction[7:0]};
                    ten_bit_dont_care = {14'b0, instruction[9:8]};
                end

                4'b1011: begin // AND
                    // R[store_at] <- R[operand_one] & R[operand_two]
                    store_at = instruction[11:10];
                    operand_one = instruction[9:8];
                    operand_two = instruction[7:6];
                    six_bit_dont_care = {10'b0, instruction[5:0]};
                end
                4'b1100: begin // OR
                    // R[store_at] <- R[operand_one] | R[operand_two]
                    store_at = instruction[11:10];
                    operand_one = instruction[9:8];
                    operand_two = instruction[7:6];
                    six_bit_dont_care = {10'b0, instruction[5:0]};
                end
                4'b1101: begin // NOT
                    // R[store_at] <- ~R[operand_one]  (operand_two unused)
                    store_at = instruction[11:10];
                    operand_one = instruction[9:8];
                    operand_two = instruction[7:6];
                    six_bit_dont_care = {10'b0, instruction[5:0]};
                end
                4'b1110: begin // XOR
                    // R[store_at] <- R[operand_one] ^ R[operand_two]
                    store_at = instruction[11:10];
                    operand_one = instruction[9:8];
                    operand_two = instruction[7:6];
                    six_bit_dont_care = {10'b0, instruction[5:0]};
                end
                4'b1111: twelve_bit_dont_care = {4'b0, instruction[11:0]}; // HALT — lower 12 bits are don't-care.
            endcase
        end
    end
endmodule
