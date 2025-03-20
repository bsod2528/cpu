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

module tb_gpr();
    reg write_enable, clk, reset;
    reg [1:0] select_reg;
    reg [15:0] alu_result;

    wire [15:0] reg_a_out, reg_b_out, reg_c_out, reg_d_out;

    gp_registers dut(
        .write_enable(write_enable),
        .clk(clk),
        .reset(reset),
        .select_reg(select_reg),
        .alu_result(alu_result),
        .reg_a_out(reg_a_out),
        .reg_b_out(reg_b_out),
        .reg_c_out(reg_c_out),
        .reg_d_out(reg_d_out)
    );

    always #5 clk = ~clk;

    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, tb_gpr);

        clk = 0;
        reset = 1;
        write_enable = 0;

        #10 reset = 0; write_enable = 1; alu_result = 16'b0001_0001_0001_0001; select_reg = 2'b00;
        #10 select_reg = 2'b11;
        #10 write_enable = 0;
        #10 $finish;
    end
endmodule
