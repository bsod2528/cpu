// =============================================================================
// File      : tb_cpu.v
// Module    : tb_cpu
// Brief     : Top-level integration testbench for the VR16 processor.
//
// Description:
//   Instantiates the complete `vr16_cpu` top-level and drives it for 2000 ns
//   while recording all signals to a VCD waveform file (`dump.vcd`).
//   The VCD can be opened in GTKWave to visually inspect the full pipeline.
//   No explicit pass/fail assertions are made here; correctness is verified
//   by visual waveform inspection or by the more targeted unit testbenches.
// =============================================================================
`timescale 1ns / 1ps


module tb_cpu();
    // Testbench stimulus registers.
    reg clk;
    reg reset;

    // Step 1: Instantiate the complete VR16 CPU as the Device Under Test.
    vr16_cpu uut(
        .global_clk(clk),
        .global_reset(reset)
    );

    // Step 2: Free-running clock with 10 ns period.
    always #5 clk = ~clk;

    initial begin
        // Step 3: Open a VCD dump file for waveform capture.
        $dumpfile("dump.vcd");
        $dumpvars(0, tb_cpu);

        // Step 4: Initialise signals and hold reset for half a clock cycle.
        clk = 0;
        reset = 1;

        // Step 5: Release reset; the CPU begins executing from address 0.
        #5 reset = 0;

        // Step 6: Run the simulation long enough for several instructions
        //         to complete, then terminate.
        #2000 $finish;
    end
endmodule
