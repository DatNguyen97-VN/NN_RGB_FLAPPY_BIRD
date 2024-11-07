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
            // Select device control register
            case (address)
                8'd0  : sreg <= 16'h12_80; // COM7   Reset
                8'd1  : sreg <= 16'h12_80; // COM7   Reset
                8'd2  : sreg <= 16'h12_04; // COM7   Size & RGB output
                8'd3  : sreg <= 16'h11_00; // CLKRC  Prescaler - Fin/(1+1)
                8'd4  : sreg <= 16'h0C_00; // COM3   Lots of stuff, enable scaling, all others off
                8'd5  : sreg <= 16'h3E_00; // COM14  PCLK scaling off
                8'd6  : sreg <= 16'h8C_00; // RGB444 Set RGB format
                8'd7  : sreg <= 16'h04_00; // COM1   no CCIR601
                8'd8  : sreg <= 16'h40_10; // COM15  Full 0-255 output, RGB 565
                8'd9  : sreg <= 16'h3A_04; // TSLB   Set UV ordering, do not auto-reset window
                8'd10 : sreg <= 16'h14_18; // COM9   AGC Ceiling
                8'd11 : sreg <= 16'h4F_B3; // MTX1  Color conversion matrix
                8'd12 : sreg <= 16'h50_B3; // MTX2  Color conversion matrix
                8'd13 : sreg <= 16'h51_00; // MTX3  Color conversion matrix
                8'd14 : sreg <= 16'h52_3D; // MTX4  Color conversion matrix
                8'd15 : sreg <= 16'h53_A7; // MTX5  Color conversion matrix
                8'd16 : sreg <= 16'h54_E4; // MTX6  Color conversion matrix
                8'd17 : sreg <= 16'h58_9E; // MTXS  Matrix sign and auto contrast
                8'd18 : sreg <= 16'h3D_C0; // COM13  Turn on GAMMA and UV Auto adjust
                8'd19 : sreg <= 16'h11_00; // CLKRC  Prescaler - Fin/(1+1)
                8'd20 : sreg <= 16'h17_11; // HSTART HREF start (high 8 bits)
                8'd21 : sreg <= 16'h18_61; // HSTOP  HREF stop (high 8 bits)
                8'd22 : sreg <= 16'h32_A4; // HREF   Edge offset and low 3 bits of HSTART and HSTOP
                8'd23 : sreg <= 16'h19_03; // VSTART VSYNC start (high 8 bits)
                8'd24 : sreg <= 16'h1A_7B; // VSTOP  VSYNC stop (high 8 bits) 
                8'd25 : sreg <= 16'h03_0A; // VREF   VSYNC low two bits
                8'd26 : sreg <= 16'h0E_61; // COM5(0x0E) 0x61
                8'd27 : sreg <= 16'h0F_4B; // COM6(0x0F) 0x4B 
                8'd28 : sreg <= 16'h16_02; // 
                8'd29 : sreg <= 16'h1E_37; // MVFP Flip and mirror image
                8'd30 : sreg <= 16'hB1_0C; // ABLC1
                8'd31 : sreg <= 16'hB3_80; // THL_ST
                8'd32 : sreg <= 16'h3C_78; // COM12
                8'd33 : sreg <= 16'h4D_40; 
                8'd34 : sreg <= 16'h4E_20;
                8'd35 : sreg <= 16'h69_00; // GFIX
                8'd36 : sreg <= 16'h6B_4A;
                8'd37 : sreg <= 16'h74_10;
                8'd38 : sreg <= 16'h8D_4F;
                8'd39 : sreg <= 16'h8E_00;
                8'd40 : sreg <= 16'h8F_00;
                8'd41 : sreg <= 16'h90_00;
                8'd42 : sreg <= 16'h91_00;
                8'd43 : sreg <= 16'h96_00;
                8'd44 : sreg <= 16'h9A_00;
                8'd45 : sreg <= 16'hB0_84;
                8'd46 : sreg <= 16'hB1_0C;
                8'd47 : sreg <= 16'hB2_0E;
                8'd48 : sreg <= 16'hB3_82;
                8'd49 : sreg <= 16'hB8_0A;
                8'd50 : sreg <= 16'h13_E0; // COM8, disable AGC/AEC
                8'd51 : sreg <= 16'h00_00; // Set gain register to 0 for AGC
                8'd52 : sreg <= 16'h10_00; // Set ARCJ register to 0
                8'd53 : sreg <= 16'h0D_40; // Reserved bit for COM4
                8'd54 : sreg <= 16'h14_18; // COM9, 4x gain
                8'd55 : sreg <= 16'hA5_05; // BD50MAX
                8'd56 : sreg <= 16'hAB_07; // DB60MAX
                8'd57 : sreg <= 16'h24_95; // AGC upper limit
                8'd58 : sreg <= 16'h25_33; // AGC lower limit
                8'd59 : sreg <= 16'h26_E3; // AGC/AEC fast mode op region
                8'd60 : sreg <= 16'h9F_78; // HAECC1
                8'd61 : sreg <= 16'hA0_68; // HAECC2
                8'd62 : sreg <= 16'hA1_03; // Reserved
                8'd63 : sreg <= 16'hA6_D8; // HAECC3
                8'd64 : sreg <= 16'hA7_D8; // HAECC4
                8'd65 : sreg <= 16'hA8_F0; // HAECC5
                8'd66 : sreg <= 16'hA9_90; // HAECC6
                8'd67 : sreg <= 16'hAA_94; // HAECC7
                8'd68 : sreg <= 16'h13_E5; // COM8, enable AGC/AEC
                8'd69 : sreg <= 16'h69_06; // Gain of RGB (manually adjusted)
                default: sreg <= 16'hFFFF; // End of register list
            endcase
        end
    end
endmodule