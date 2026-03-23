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
// Description:
//  Holds four 16-bit general-purpose registers: r0 (reg_a), r1 (reg_b),
//  r2 (reg_c), and r3 (reg_d).
//
//  Write path (clocked):
//      On a rising clock edge, if `write_enable` is asserted, the value on
//      `alu_result` is stored into the register selected by `store_at`.
//      `write_done` is pulsed high for one clock cycle to acknowledge the write.
//
//  Read path (combinational):
//      `operand_one_reg` and `operand_two_reg` are continuously driven by the
//      registers addressed by `read_operand_one_reg` and `read_operand_two_reg`
//      respectively.  Reads are zero-latency; they reflect the current register
//      state immediately.
//
//  All four register values are also exposed on individual output wires
//  (reg_a_out … reg_d_out) for debug and result observation.
// =============================================================================

module gp_registers(
    input wire clk,
    input wire reset,
    input wire write_enable,
    input wire [1:0] store_at,
    input wire [1:0] read_operand_one_reg,
    input wire [1:0] read_operand_two_reg,
    input wire [15:0] alu_result,

    output wire write_done,
    output wire [15:0] reg_a_out,
    output wire [15:0] reg_b_out,
    output wire [15:0] reg_c_out,
    output wire [15:0] reg_d_out,
    output reg [15:0] operand_one_reg,
    output reg [15:0] operand_two_reg
);
    // Internal storage for the four 16-bit general-purpose registers.
    reg write_done_reg;
    reg [15:0] reg_a; // r0
    reg [15:0] reg_b; // r1
    reg [15:0] reg_c; // r2
    reg [15:0] reg_d; // r3

    // -------------------------------------------------------------------------
    // Combinational read path.
    // Selects the correct register value for each of the two operand outputs
    // based on the read-address inputs. Default to zero on unrecognised address.
    // -------------------------------------------------------------------------
    always @ (*) begin
        // Step 1: Default operand outputs to zero before the mux logic below
        //         overrides them, preventing latches.
        operand_one_reg = 16'b0000_0000_0000_0000;
        operand_two_reg = 16'b0000_0000_0000_0000;

        // Step 2: Route the correct register to operand_one_reg.
        case (read_operand_one_reg)
            2'b00: operand_one_reg = reg_a;
            2'b01: operand_one_reg = reg_b;
            2'b10: operand_one_reg = reg_c;
            2'b11: operand_one_reg = reg_d;
            default: operand_one_reg = 16'b0000_0000_0000_0000;
        endcase

        // Step 3: Route the correct register to operand_two_reg.
        case (read_operand_two_reg)
            2'b00: operand_two_reg = reg_a;
            2'b01: operand_two_reg = reg_b;
            2'b10: operand_two_reg = reg_c;
            2'b11: operand_two_reg = reg_d;
            default: operand_two_reg = 16'b0000_0000_0000_0000;
        endcase
    end

    // -------------------------------------------------------------------------
    // Clocked write path.
    // -------------------------------------------------------------------------
    //always @(*) begin  // Saint: switched to clocked write to avoid glitches.
    always @(posedge clk or posedge reset) begin
        // Step 4: On reset, clear every register and the done flag.
        if (reset) begin
            reg_a <= 16'b0000_0000_0000_0000;
            reg_b <= 16'b0000_0000_0000_0000;
            reg_c <= 16'b0000_0000_0000_0000;
            reg_d <= 16'b0000_0000_0000_0000;
            write_done_reg <= 1'b0;
        end

        // Step 5: When write_enable is asserted, store alu_result into the
        //         register selected by store_at, then assert write_done.
        else if (write_enable) begin
            case (store_at)
                2'b00: reg_a <= alu_result;
                2'b01: reg_b <= alu_result;
                2'b10: reg_c <= alu_result;
                2'b11: reg_d <= alu_result;
                // Step 5a: Default keeps registers unchanged; unreachable with
                //          a 2-bit address but included for completeness.
                default: begin
                    reg_a <= reg_a;
                    reg_b <= reg_b;
                    reg_c <= reg_c;
                    reg_d <= reg_d;
                end
            endcase
            // Step 6: Pulse write_done so the control unit can observe completion.
            write_done_reg <= 1'b1;
        end

        // Step 7: When write_enable is de-asserted, clear write_done so it
        //         does not persist across cycles.
        else
            write_done_reg <= 1'b0;
    end

    // Continuous wire assignments expose internal registers for observation.
    assign reg_a_out = reg_a;
    assign reg_b_out = reg_b;
    assign reg_c_out = reg_c;
    assign reg_d_out = reg_d;
    assign write_done = write_done_reg;
endmodule
