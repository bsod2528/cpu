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
// File      : alu.v
// Module    : alu
// Brief     : Arithmetic and Logic Unit (ALU) for the VR16 processor.
//
// Description:
//   Performs arithmetic (ADD, ADDI, SUB, SUBI, MUL, MULI, DIV, DIVI) and
//   logical (AND, OR, NOT, XOR) operations on two 16-bit operands.
//   Operations are clocked and gated by `alu_enable`. When an operation
//   completes, `alu_done` is driven high for one clock cycle.
//   On reset, the result register is cleared to zero.
//
// Inputs:
//   clk         - System clock; operations sample on the rising edge.
//   reset       - Active-high synchronous reset; clears `result` to 0.
//   alu_enable  - Operation enable; the ALU computes only when this is high.
//   opcode      - 4-bit selector that chooses the arithmetic or logic op.
//   operand_one - 16-bit left-hand operand.
//   operand_two - 16-bit right-hand operand (unused by NOT).
//
// Outputs:
//   result   - 16-bit registered computation result.
//   alu_done - Pulses high for exactly one clock cycle once the result is ready;
//              driven low again when `alu_enable` is de-asserted.
// =============================================================================

// It's happening ladies and gentlemen
// Saint: And indeed it did! Great milestone getting the ALU up and running.
module alu(
    input wire clk,
    input wire reset,
    input wire alu_enable,
    input wire [3:0] opcode,
    input wire [15:0] operand_one,
    input wire [15:0] operand_two,

    output reg [15:0] result,
    output wire alu_done
);

    // Internal register that holds the done status for one cycle.
    reg alu_done_reg;

    // -------------------------------------------------------------------------
    // Clocked operation block.
    // Priority: reset > alu_enable (compute) > idle (clear done flag).
    // -------------------------------------------------------------------------
    always @ (posedge clk or posedge reset) begin
        // Step 1: On reset, clear the result register to a known-zero state.
        if (reset)
            result <= 16'b0000_0000_0000_0000;
        // Step 2: When the enable signal is asserted, select and execute the
        //         operation corresponding to the 4-bit opcode.
        else if (alu_enable) begin
            case (opcode)
                4'b0000: result <= operand_one + operand_two;   // ADD
                4'b0001: result <= operand_one + operand_two;   // ADDI
                4'b0010: result <= operand_one - operand_two;   // SUB
                4'b0011: result <= operand_one - operand_two;   // SUBI
                4'b0100: result <= operand_one * operand_two;   // MUL
                4'b0101: result <= operand_one * operand_two;   // MULI
                4'b0110: result <= operand_one / operand_two;   // DIV
                4'b0111: result <= operand_one / operand_two;   // DIVI - good thing `immediate values` weren't named absolute values, otherwise this would've been DIVA *winks*. It's a joke.
                // Saint: Ha! DIVA would have been a legendary opcode name.
                4'b1011: result <= operand_one & operand_two;   // AND
                4'b1100: result <= operand_one | operand_two;   // OR
                4'b1101: result <= ~operand_one;                // NOT - only operand_one is used; operand_two is ignored.
                4'b1110: result <= operand_one ^ operand_two;   // XOR
                // Step 2a: Unknown opcodes produce zero to avoid undefined state.
                default: result <= 16'b0000_0000_0000_0000;
            endcase
            // Step 3: Signal completion; downstream modules detect this rising edge.
            alu_done_reg <= 1'b1;
        end
        // Step 4: When idle (enable de-asserted), clear the done flag so it
        //         does not remain permanently high.
        else
            alu_done_reg <= 1'b0;
    end

    // Expose the internal done register as a continuous wire assignment.
    assign alu_done = alu_done_reg;
endmodule
