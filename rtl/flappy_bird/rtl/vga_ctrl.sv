

module  vga_ctrl
(
    input   wire            vga_clk     ,   // Input working clock, frequency 25MHz
    input   wire            sys_rst_n   ,   // Input reset signal, low level is effective
    input   wire    [15:0]  pix_data    ,   // Input pixel color information

    output  wire    [09:0]  pix_x       ,   // Output the X-axis coordinates of the pixels in the effective VGA display area
    output  wire    [09:0]  pix_y       ,   // Output the Y-axis coordinate of the pixel point in the VGA effective display area
    output  reg             hsync       ,   // Output line synchronization signal
    output  reg             vsync       ,   // Output field sync signal
    output  wire            rgb_valid   ,
	output  reg             activeArea  ,
    output  wire    [15:0]  rgb             // Output pixel color information
);

//********************************************************************//
//****************** Parameter and Internal Signal *******************//
//********************************************************************//

logic [09:00] Hcnt; // Line sync signal counter
logic [09:00] Vcnt; // Field sync signal counter

//parameter define
const int H_TOTAL = 799;   // the maximum size considers 800 (horizontal)
const int H_DISPLAY = 640; // screen size (horizontal)
const int H_FRONT = 16;    // front porch
const int H_BACK = 48;     // back porch
const int H_SYNC = 96;     // sync time

const int V_TOTAL = 524;   // the maximum size considers 525 (vertical) 
const int V_DISPLAY = 480; // screen size (vertical)
const int V_FRONT = 10;    // front porch
const int V_BACK = 33;     // back porch
const int VR = 2;          // retrace

//********************************************************************//
//***************************** Main Code ****************************//
//********************************************************************//

// initialization of a counter from 0 to 799 (800 pixels per line):
// at each clock edge increments the column counter
// i.e. from 0 to 799.
always_ff @(posedge vga_clk or negedge sys_rst_n) begin
	if (!sys_rst_n) begin
		Hcnt <= '0;
		Vcnt <= '0;
	end else begin
		if (Hcnt == H_TOTAL) begin // 799
			Hcnt <= '0;
			if (Vcnt == V_TOTAL) begin // 524
				Vcnt <= '0;
				activeArea <= 1'b1;
			end else begin
				/*// 320x240
				if (!mode && (Vcnt < 240-1)) begin
					activeArea <= 1'b1;
				end */
				// 160x120
				if (Vcnt < 120-1) begin
					activeArea <= 1'b1;
				end
				Vcnt <= Vcnt + 1;
			end
		end else begin
			/* // 320x240
			if (!mode && (Hcnt == 320-1)) begin
				activeArea <= 1'b0;
			end */
			// 160x120
			if (Hcnt == 160-1) begin
				activeArea <= 1'b0;
			end
			Hcnt <= Hcnt + 1;
		end
	end
end

// generation of the horizontal synchronization signal Hsync
always_ff @(posedge vga_clk) begin
	// check Hcnt >= 656 and Hcnt <= 751
	if ((Hcnt >= (H_DISPLAY+H_FRONT)) && (Hcnt <= (H_DISPLAY+H_FRONT+H_SYNC-1))) begin
		hsync <= 1'b0;
	end else begin
		hsync <= 1'b1;
	end
end
// generation of the vertical synchronization signal Vsync
always_ff @(posedge vga_clk) begin
	// check Vcnt >= 490 and vcnt <= 491
	if (Vcnt >= (V_DISPLAY+V_FRONT) && Vcnt <= (V_DISPLAY+V_FRONT+VR-1)) begin
		vsync <= 1'b0;
	end else begin
		vsync <= 1'b1;
	end
end

// this is to use the full resolution 640 x 480
// rgb_valid: VGA valid display area
assign rgb_valid = ((Hcnt < H_DISPLAY) && (Vcnt < V_DISPLAY)) ? 1'b1 : 1'b0;

//pix_x,pix_y: VGA effective display area pixel coordinates
assign pix_x = rgb_valid ? Hcnt : 10'h3ff;

assign pix_y = rgb_valid ? Vcnt : 10'h3ff;

//rgb: output pixel color information
assign rgb = rgb_valid ? pix_data : 16'b0;

endmodule
