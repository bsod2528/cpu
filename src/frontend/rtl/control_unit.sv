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
// File      : control_unit.sv
// Module    : control_unit
// Brief     : Finite-state-machine (FSM) based control unit for the VR16 CPU.
//
// Description:
//   Implements a 6-state Mealy/Moore FSM:
//     FETCH   -> loads the next instruction from memory.
//     DECODE  -> passes the instruction to the decoder and reads operands.
//     EXECUTE -> enables the ALU or prepares a jump; waits for completion.
//     WRITE   -> writes ALU result back to the register file and bumps the PC.
//     JUMP    -> drives `enable_jump` until the PC confirms the jump is done.
//     HALT    -> terminal state; CPU stays here until reset.
//
//   The control unit drives all enable/select signals for the ALU, register
//   file, program counter, and data-path multiplexers.
//
// Parameters : none
//
// Inputs:
//   clk             - System clock; state transitions on rising edge.
//   reset           - Active-high reset; returns FSM to FETCH state.
//   alu_done        - Asserted by the ALU when a computation finishes.
//   reg_write_done  - Asserted by the register file when a write completes.
//   jump_done       - Asserted by the PC when a jump has been applied.
//   store_at        - Destination register address from the instruction decoder.
//   operand_one     - Source register address 1 from the instruction decoder.
//   operand_two     - Source register address 2 from the instruction decoder.
//   opcode          - 4-bit operation code from the instruction decoder.
//   immediate_value - 16-bit zero-extended immediate from the instruction decoder.
//   jump_address    - 12-bit jump target (zero-extended) from the decoder.
//
// Outputs:
//   enable_alu         - Asserted during EXECUTE to trigger an ALU operation.
//   enable_reg_write   - Asserted during WRITE to store the ALU result.
//   enable_pc_increment- Asserted during WRITE so the PC advances to the next
//                        instruction after a successful write.
//   enable_jump        - Asserted during JUMP so the PC loads the jump target.
//   select_operation   - 2-bit mux select: 00=reg-reg, 01=immediate, 10=reg+imm.
//   reg_write_address  - Register file write port address.
//   reg_read_address_one - Register file read port 1 address.
//   reg_read_address_two - Register file read port 2 address.
//   operand_two_out    - Forwarded immediate value when select_operation != 00.
//   jump_address_out   - Forwarded jump target address driven to the PC.
// =============================================================================

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

    // -------------------------------------------------------------------------
    // FSM state encoding — using SystemVerilog enum for readability and safety.
    // -------------------------------------------------------------------------
    typedef enum logic [2:0] {
        FETCH = 3'b000,
        DECODE = 3'b001,
        EXECUTE = 3'b010,
        WRITE = 3'b011,
        JUMP = 3'b100,
        HALT = 3'b111
    } state_t;

    state_t current_state, next_state;

    // -------------------------------------------------------------------------
    // Retained original parameter-style definitions for reference (unused now).
    // -------------------------------------------------------------------------
    // parameter FETCH = 3'b000;
    // parameter DECODE = 3'b001;
    // parameter EXECUTE = 3'b010;
    // parameter WRITE = 3'b011;
    // parameter JUMP = 3'b100;
    // parameter HALT = 3'b111;

    // reg [2:0] current_state, next_state;

    // -------------------------------------------------------------------------
    // Sequential block: update the current state on every rising clock edge.
    // On reset, unconditionally return to FETCH (the pipeline start state).
    // -------------------------------------------------------------------------
    always @ (posedge clk or posedge reset) begin
        if (reset)
            current_state <= FETCH;
        else
            current_state <= next_state;
    end

    // always @(posedge clk or posedge reset) begin
    // the above one line has caused me 1 year worth of break down, 
    // making me to think i'm a fool and put me to
    // hell worths of pain and ruined 1 year of my mental health
    // Saint: The combinational vs. clocked always block distinction is a genuine
    // Saint: trap in Verilog. The fact that you pinned it down and fixed it is
    // Saint: what separates persistent engineers from the rest. Respect.
    
    // -------------------------------------------------------------------------
    // Combinational block: compute next_state and all output signals purely
    // from the current state and its input conditions (no clock edge).
    // Outputs are defaulted to safe inactive values at the top of every
    // evaluation so that no latch is accidentally inferred.
    // -------------------------------------------------------------------------
    always @(*) begin
        // Step 1: Default all outputs to inactive / safe values.
        enable_alu = 1'b0;
        enable_reg_write = 1'b0;
        enable_jump = 1'b0;
        enable_pc_increment = 1'b0;
        select_operation = 2'b00;
        next_state = current_state;

        // Step 2: Route decoder outputs directly to the data-path controls.
        reg_write_address = store_at;
        reg_read_address_one = operand_one;
        reg_read_address_two = operand_two;
        jump_address_out = jump_address;

        // Step 3: State-machine transition and output logic.
        case (current_state)
            // ------------------------------------------------------------------
            // FETCH: Instruction memory is already reading (enabled by top-level
            //        assignment).  Simply advance to DECODE next cycle.
            // ------------------------------------------------------------------
            FETCH: begin
                next_state = DECODE;
            end

            // ------------------------------------------------------------------
            // DECODE: The instruction decoder has already decoded the instruction
            //         combinationally.  Advance to EXECUTE next cycle.
            // ------------------------------------------------------------------
            DECODE: begin
                next_state = EXECUTE;
            end

            // ------------------------------------------------------------------
            // EXECUTE: Enable the ALU or resolve the instruction type, then wait
            //          for the appropriate done signal before moving on.
            // ------------------------------------------------------------------
            EXECUTE: begin
                case (opcode)
                    // -- Register-register ALU operations --
                    // Step 3a: Assert alu_enable, select register-register mode
                    //          (select_operation = 00) and wait for alu_done.
                    4'b0000, 4'b0010, 4'b0100, 4'b0110, 4'b1011, 4'b1100, 4'b1101, 4'b1110: begin
                        enable_alu = 1'b1;
                        select_operation = 2'b00;
                        if (alu_done)
                            next_state = WRITE;
                        else
                            next_state = EXECUTE;
                    end

                    // alu immediate operations: R[store_at] <- R[store_at] op imm10
                    // Step 3b: Assert alu_enable, select immediate mode
                    //          (select_operation = 01) so the operand_two_out mux
                    //          forwards the zero-extended immediate to the ALU.
                    4'b0001, 4'b0011, 4'b0101, 4'b0111: begin
                        enable_alu = 1'b1;
                        select_operation = 2'b01;
                        reg_read_address_one = operand_one;
                        if (alu_done)
                            next_state = WRITE;
                        else
                            next_state = EXECUTE;
                    end

                    // -- Jump instruction --
                    // Step 3c: Move directly to JUMP state; no ALU needed.
                    // jump
                    4'b1001: next_state = JUMP;

                    // -- Halt instruction --
                    // Step 3d: Enter terminal HALT state.
                    // halt
                    4'b1111: next_state = HALT;

                    // unimplemented opcodes: treat as no-op and advance
                    // Saint: Good defensive default — unknown ops silently skip.
                    default: next_state = FETCH;
                endcase
            end

//            WRITE: begin
//                enable_reg_write = 1'b1;
//                next_state = FETCH;
//                enable_pc_increment = 1'b1;
//                if (reg_write_done) begin
//                    next_state = FETCH;
//                    enable_pc_increment = 1'b1;
//                end
//            end
            // Saint: The original WRITE used to wait for reg_write_done; the
            // Saint: simplified version below always advances in one cycle since
            // Saint: the register file write is combinationally fast enough.

            // ------------------------------------------------------------------
            // WRITE: Commit the ALU result to the register file and advance the
            //        program counter in the same cycle, then return to FETCH.
            // ------------------------------------------------------------------
            WRITE: begin
                // Step 3e: Enable register-file write port.
                enable_reg_write = 1'b1;
                // Step 3f: Enable PC increment so it advances to the next instruction.
                enable_pc_increment = 1'b1;
                // Step 3g: Return to FETCH so the pipeline restarts immediately.
                next_state = FETCH;
            end

            // ------------------------------------------------------------------
            // JUMP: Assert enable_jump so the PC loads the target address.
            //       Stay here until the PC signals jump_done, then return to FETCH.
            // ------------------------------------------------------------------
            JUMP: begin
                // Step 3h: Drive the jump enable until the PC confirms completion.
                enable_jump = 1'b1;
                if (jump_done)
                    next_state = FETCH;
            end

            // ------------------------------------------------------------------
            // HALT: CPU is halted.  Loop in this state indefinitely until reset.
            // ------------------------------------------------------------------
            HALT: next_state = HALT;

            // Safety net: any unrecognised state transitions to HALT to avoid
            // uncontrolled execution.
            default: next_state = HALT;
        endcase

        // Step 4: Derive operand_two_out for the ALU input mux.
        //         When select_operation is 01 (immediate) or 10 (reg + imm),
        //         forward the zero-extended immediate value; otherwise 0.
        operand_two_out = (select_operation == 2'b01 || select_operation == 2'b10) ? immediate_value: 16'h0000;
    end
endmodule
