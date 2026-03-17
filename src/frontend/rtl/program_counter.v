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
// File      : program_counter.v
// Module    : program_counter
// Brief     : Program counter (PC) for the VR16 processor.
//
// Description:
//   Maintains the current instruction address in `counter_reg`.  On each
//   rising clock edge the PC resolves one of four mutually exclusive
//   behaviours according to the following priority order (highest first):
//
//     1. reset       — clears the PC and jump_done to zero.
//     2. flag_input  — HALT behaviour; forces the PC back to address 0.
//     3. jump_enable — loads `jump_address` into the PC and asserts
//                      `jump_done` for one cycle so the control unit knows
//                      the jump has been applied.
//     4. return_enable — restores the PC to the address saved before the
//                        last jump (supports a basic subroutine return).
//     5. increment   — advances the PC by 1 for normal sequential execution.
//
//   `jump_done` is de-asserted at the start of every non-reset cycle so
//   it never stays high for more than one clock period.
//
// Inputs:
//   clk           - System clock; PC updates on the rising edge.
//   reset         - Active-high reset; clears counter_reg and jump_done.
//   increment     - Advance PC by 1 (normal sequential execution).
//   jump_enable   - Load `jump_address` into the PC.
//   return_enable - Restore the PC from the pre-jump saved address.
//   flag_input    - HALT flag; forces PC to 0 when asserted (opcode 1111).
//   jump_address  - 16-bit target address for jump instructions.
//
// Outputs:
//   jump_done   - Pulses high for one clock cycle after a jump is applied.
//   counter_reg - Current 16-bit program counter value (instruction address).
// =============================================================================

// I've been spamming can you hear the music while doing this HAHA.
// Saint: The best debugging sessions always have a good soundtrack. Respect.
module program_counter(
    input wire clk,
    input wire reset,
    input wire increment,
    input wire jump_enable,
    input wire return_enable,
    input wire flag_input, // for HALT
    input wire [15:0] jump_address,

    output reg jump_done,
    output reg [15:0] counter_reg
);
    // Temporary register used to save the PC value before a jump so that a
    // subsequent return_enable can restore it (basic subroutine support).
    reg [15:0] temp_address;

    // Control priority (highest to lowest):
    // 1) reset      -> clear program counter state
    // 2) flag_input -> HALT behavior (force PC to 0)
    // 3) jump/return-> control-flow redirection
    // 4) increment  -> normal sequential execution
    always @ (posedge clk or posedge reset) begin
        // Step 1: On reset, unconditionally zero the PC and clear jump_done.
        if (reset) begin
            jump_done <= 1'b0;
            counter_reg <= 16'b0000_0000_0000_0000;
        end
        else begin
            // Step 2: Default jump_done to 0 each cycle; it is only asserted
            //         for a single cycle when a jump is successfully applied.
            jump_done <= 1'b0;

            // Step 3: HALT — flag_input overrides all normal control flow.
            //         Force PC to 0 so the CPU idles at the first address.
            if (flag_input)
                counter_reg <= 16'b0000_0000_0000_0000;

            // Step 4: JUMP — save the current PC for a possible later return,
            //         then load the target address and signal completion.
            else if (jump_enable) begin
                temp_address <= counter_reg;    // Save return address.
                counter_reg <= jump_address;    // Load jump target.
                jump_done <= 1'b1;              // Pulse done for one cycle.
            end

            // Step 5: RETURN — restore the PC from the pre-jump snapshot.
            else if (return_enable)
                counter_reg <= temp_address;

            // Step 6: INCREMENT — normal sequential execution; advance by 1.
            else if (increment)
                counter_reg <= counter_reg + 1;
        end
    end
endmodule
