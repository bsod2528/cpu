// This has been created for implementing the CPU onto the Terasic DE0 Board.
// Further documentation of sorts will be updated in future!

module de0_top (
    input wire CLOCK_50,
    input wire [2:0] KEY, // KEY is active low on DE0
    output wire [6:0] HEX0,
    output wire [6:0] HEX1,
    output wire [6:0] HEX2,
    output wire [6:0] HEX3
);

    // Reset: KEY[2] held as reset (active-low, so invert it)
    // KEY[0] = next register
    // KEY[1] = previous register
    wire reset = ~KEY[2];

    // Clock divider
    reg [25:0] div;
    always @(posedge CLOCK_50)
        div <= div + 1;
    wire cpu_clk = div[20];

    // Register selector: 2-bit counter, wraps 0 -> 1 -> 2 -> 3 -> 0
    reg [1:0] reg_sel;

    reg key0_sync1, key0_sync2, key0_prev;
    reg key1_sync1, key1_sync2, key1_prev;

    always @(posedge cpu_clk or posedge reset) begin
        if (reset) begin
            key0_sync1 <= 1'b1; key0_sync2 <= 1'b1; key0_prev <= 1'b1;
            key1_sync1 <= 1'b1; key1_sync2 <= 1'b1; key1_prev <= 1'b1;
            reg_sel <= 2'b00;
        end else begin
            key0_sync1 <= KEY[0]; key0_sync2 <= key0_sync1;
            key1_sync1 <= KEY[1]; key1_sync2 <= key1_sync1;
            key0_prev <= key0_sync2;
            key1_prev <= key1_sync2;

            if (key0_prev == 1'b1 && key0_sync2 == 1'b0)
                reg_sel <= reg_sel + 1;
            else if (key1_prev == 1'b1 && key1_sync2 == 1'b0)
                reg_sel <= reg_sel - 1;
        end
    end

    // CPU instantiation
    wire [15:0] reg_a, reg_b, reg_c, reg_d;

    vr16_cpu cpu (
        .global_clk(cpu_clk),
        .global_reset(reset),
        .reg_a_out(reg_a),
        .reg_b_out(reg_b),
        .reg_c_out(reg_c),
        .reg_d_out(reg_d)
    );

    // Mux the selected register onto the displays
    reg [15:0] display_val;
    always @(*) begin
        case (reg_sel)
            2'b00: display_val = reg_a;
            2'b01: display_val = reg_b;
            2'b10: display_val = reg_c;
            2'b11: display_val = reg_d;
        endcase
    end

    // Double dabble algorithm: binary to BCD conversion
    // 0-9999 shown as decimal, 10000-65535 falls back to hexadecimal
    function [19:0] bin_to_bcd;
        input [15:0] bin;
        integer i;
        reg [35:0] scratch;
        begin
            scratch = 36'b0;
            scratch[15:0] = bin;
            for (i = 0; i < 16; i = i + 1) begin
                if (scratch[19:16] >= 5) scratch[19:16] = scratch[19:16] + 3;
                if (scratch[23:20] >= 5) scratch[23:20] = scratch[23:20] + 3;
                if (scratch[27:24] >= 5) scratch[27:24] = scratch[27:24] + 3;
                if (scratch[31:28] >= 5) scratch[31:28] = scratch[31:28] + 3;
                if (scratch[35:32] >= 5) scratch[35:32] = scratch[35:32] + 3;
                scratch = scratch << 1;
            end
            bin_to_bcd = scratch[35:16];
        end
    endfunction

    wire [19:0] bcd = bin_to_bcd(display_val);
    wire use_decimal = (display_val <= 16'd9999);

    hex_decoder h3 (.val(use_decimal ? bcd[15:12] : display_val[15:12]), .seg(HEX3));
    hex_decoder h2 (.val(use_decimal ? bcd[11:8] : display_val[11:8]), .seg(HEX2));
    hex_decoder h1 (.val(use_decimal ? bcd[7:4] : display_val[7:4]), .seg(HEX1));
    hex_decoder h0 (.val(use_decimal ? bcd[3:0] : display_val[3:0]), .seg(HEX0));

endmodule

// 7-segment decoder - active-low segments (DE0 standard)
// Handles 0-9 for decimal and A-F for hex fallback
module hex_decoder (
    input  wire [3:0] val,
    output reg  [6:0] seg
);
    always @(*) begin
        case (val)
            4'h0: seg = 7'b100_0000;
            4'h1: seg = 7'b111_1001;
            4'h2: seg = 7'b010_0100;
            4'h3: seg = 7'b011_0000;
            4'h4: seg = 7'b001_1001;
            4'h5: seg = 7'b001_0010;
            4'h6: seg = 7'b000_0010;
            4'h7: seg = 7'b111_1000;
            4'h8: seg = 7'b000_0000;
            4'h9: seg = 7'b001_0000;
            4'hA: seg = 7'b000_1000;
            4'hB: seg = 7'b000_0011;
            4'hC: seg = 7'b100_0110;
            4'hD: seg = 7'b010_0001;
            4'hE: seg = 7'b000_0110;
            4'hF: seg = 7'b000_1110;
            default: seg = 7'b111_1111;
        endcase
    end
endmodule
