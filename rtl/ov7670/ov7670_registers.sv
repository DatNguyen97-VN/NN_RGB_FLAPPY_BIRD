module ov7670_registers (
    input logic clk,
    input logic rst,
    input logic resend,
    input logic advance,
    output logic [15:0] command,
    output logic finished
);
    logic [15:0] sreg;
    logic [7:0] address;

    assign command = sreg;
    assign finished = (sreg == 16'hFFFF) ? 1'b1 : 1'b0;

    always_ff @(posedge clk or negedge rst) begin
        if (!rst) begin
            address <= '0;
        end else begin
            if (resend) begin
                address <= '0;
            end else if (advance) begin
                address <= address + 1;
            end
            // Configuration of OV7670 registers with comments
            case (address)
                8'd0  : sreg <= 16'h12_80; // COM7 - Reset register
                8'd1  : sreg <= 16'h12_80; // COM7 - Re-apply reset
                8'd2  : sreg <= 16'h12_04; // COM7 - Enable size control, RGB output mode
                8'd3  : sreg <= 16'h11_00; // CLKRC - Prescaler for clock input, Fin/(0+1)
                8'd4  : sreg <= 16'h0C_00; // COM3 - Enable scaling, disable all other features
                8'd5  : sreg <= 16'h3E_00; // COM14 - PCLK scaling off
                8'd6  : sreg <= 16'h8C_00; // RGB444 - Set RGB format (RGB565)
                8'd7  : sreg <= 16'h04_00; // COM1 - Disable CCIR601
                8'd8  : sreg <= 16'h40_10; // COM15 - Full 0-255 RGB 565 output
                8'd9  : sreg <= 16'h3A_04; // TSLB - Set UV ordering, disable auto-reset window
                8'd10 : sreg <= 16'h14_18; // COM9 - Automatic Gain Control (AGC) ceiling
                8'd11 : sreg <= 16'h4F_B3; // MTX1 - Color matrix coefficient 1
                8'd12 : sreg <= 16'h50_B3; // MTX2 - Color matrix coefficient 2
                8'd13 : sreg <= 16'h51_00; // MTX3 - Color matrix coefficient 3
                8'd14 : sreg <= 16'h52_3D; // MTX4 - Color matrix coefficient 4
                8'd15 : sreg <= 16'h53_A7; // MTX5 - Color matrix coefficient 5
                8'd16 : sreg <= 16'h54_E4; // MTX6 - Color matrix coefficient 6
                8'd17 : sreg <= 16'h58_9E; // MTXS - Matrix sign and auto contrast adjustment
                8'd18 : sreg <= 16'h3D_C0; // COM13 - Enable gamma correction and UV adjustment
                8'd19 : sreg <= 16'h11_00; // CLKRC - Clock prescaler setting, Fin/(0+1)
                8'd20 : sreg <= 16'h17_11; // HSTART - Horizontal start of active image
                8'd21 : sreg <= 16'h18_61; // HSTOP - Horizontal end of active image
                8'd22 : sreg <= 16'h32_A4; // HREF - Horizontal edge offset and sync control
                8'd23 : sreg <= 16'h19_03; // VSTART - Vertical start of active image
                8'd24 : sreg <= 16'h1A_7B; // VSTOP - Vertical end of active image
                8'd25 : sreg <= 16'h03_0A; // VREF - Vertical sync position adjustment
                8'd26 : sreg <= 16'h0E_61; // COM5 - Reserved, typically 0x61
                8'd27 : sreg <= 16'h0F_4B; // COM6 - Reserved, typically 0x4B
                8'd28 : sreg <= 16'h16_02; // Reserved for special functions, default 0x02
                8'd29 : sreg <= 16'h1E_37; // MVFP - Mirror/flip image
                8'd30 : sreg <= 16'hB1_0C; // ABLC1 - Auto black level calibration setting
                8'd31 : sreg <= 16'hB3_80; // THL_ST - Threshold setting for luminance
                8'd32 : sreg <= 16'h3C_78; // COM12 - Enable HREF signal for every row
                8'd33 : sreg <= 16'h4D_40; // Reserved, typically 0x40
                8'd34 : sreg <= 16'h4E_20; // Reserved, typically 0x20
                8'd35 : sreg <= 16'h69_00; // GFIX - Set fixed gamma correction
                8'd36 : sreg <= 16'h6B_4A; // PLL control for input clock multiplier
                8'd37 : sreg <= 16'h74_10; // Reserved, typically 0x10
                8'd38 : sreg <= 16'h8D_4F; // Reserved, typically 0x4F
                8'd39 : sreg <= 16'h8E_00; // Reserved, typically 0x00
                8'd40 : sreg <= 16'h8F_00; // Reserved, typically 0x00
                8'd41 : sreg <= 16'h90_00; // Reserved, typically 0x00
                8'd42 : sreg <= 16'h91_00; // Reserved, typically 0x00
                8'd43 : sreg <= 16'h96_00; // Reserved, typically 0x00
                8'd44 : sreg <= 16'h9A_00; // Reserved, typically 0x00
                8'd45 : sreg <= 16'hB0_84; // ABLC1 - Auto black level calibration setting
                8'd46 : sreg <= 16'hB1_0C; // ABLC1 - Auto black level calibration threshold
                8'd47 : sreg <= 16'hB2_0E; // Reserved, typically 0x0E
                8'd48 : sreg <= 16'hB3_82; // THL_ST - Luminance threshold
                8'd49 : sreg <= 16'hB8_0A; // Reserved, typically 0x0A
                8'd50 : sreg <= 16'h13_E0; // COM8 - Disable AGC/AEC functions
                8'd51 : sreg <= 16'h00_00; // Gain control, set to 0 for AGC
                8'd52 : sreg <= 16'h10_00; // ARCJ - Reserved
                8'd53 : sreg <= 16'h0D_40; // COM4 - Reserved, typically 0x40
                8'd54 : sreg <= 16'h14_18; // COM9 - Maximum gain ceiling
                8'd55 : sreg <= 16'hA5_05; // BD50MAX - 50Hz Banding step
                8'd56 : sreg <= 16'hAB_07; // BD60MAX - 60Hz Banding step
                8'd57 : sreg <= 16'h24_95; // AGC upper limit setting
                8'd58 : sreg <= 16'h25_33; // AGC lower limit setting
                8'd59 : sreg <= 16'h26_E3; // AGC/AEC fast mode operational region
                8'd60 : sreg <= 16'h9F_78; // HAECC1 - Histogram-based AEC/AGC control
                8'd61 : sreg <= 16'hA0_68; // HAECC2 - Histogram-based AEC/AGC control
                8'd62 : sreg <= 16'hA1_03; // Reserved, typically 0x03
                8'd63 : sreg <= 16'hA6_D8; // HAECC3 - Histogram AEC/AGC adjustment
                8'd64 : sreg <= 16'hA7_D8; // HAECC4 - Histogram AEC/AGC adjustment
                8'd65 : sreg <= 16'hA8_F0; // HAECC5 - Histogram AEC/AGC adjustment
                8'd66 : sreg <= 16'hA9_90; // HAECC6 - Histogram AEC/AGC adjustment
                8'd67 : sreg <= 16'hAA_94; // HAECC7 - Histogram AEC/AGC adjustment
                8'd68 : sreg <= 16'h13_E5; // COM8 - Enable AGC/AEC
                8'd69 : sreg <= 16'h69_06; // Adjust gain of RGB channels manually
                default: sreg <= 16'hFFFF; // End of register list
            endcase
        end
    end
endmodule
