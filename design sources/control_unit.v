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
// For now, the ALU isn't being done cause I cannot fathom how that piece of code works.
// Just gonna write a simple control signal, based on how the ALU works, this will be changed.
module control_unit(clk, reset, ins_done, ins_count);
    // just a flag so it's 1 bit.
    input clk, reset, ins_done;
    output wire ins_count;

    reg _ins_count;

    always @ (posedge clk or posedge reset) begin
        if (reset)
            _ins_count <= 0;
        else if (ins_done)
            _ins_count <= 1;
        else 
            _ins_count <= 0;
    end

    assign ins_count = _ins_count;
endmodule
