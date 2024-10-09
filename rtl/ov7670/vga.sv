module VGA (
	input logic rst,
	input logic clk25, // 25 MHz input clock
	input logic mode,  // mode selection 320x240 and 160x120
	output logic clkout, // Clock output to ADV7123 and TFT screen
	output logic Hsync, // the two synchronization signals for the VGA screen
	output logic Vsync, // the two synchronization signals for the VGA screen
	output logic Nblank, // ADV7123 D/A converter control signal
	output logic activeArea,
	output logic Nsync // synchronization signals and control of the TFT screen
);
	logic [09:00] Hcnt;
	logic [09:00] Vcnt;
	logic video;
	//
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

	// initialization of a counter from 0 to 799 (800 pixels per line):
    // at each clock edge increments the column counter
    // i.e. from 0 to 799.
	always_ff @(posedge clk25 or negedge rst) begin
		if (!rst) begin
			Hcnt <= '0;
			Vcnt <= '0;
		end else begin
			if (Hcnt == H_TOTAL) begin // 799
				Hcnt <= '0;
				if (Vcnt == V_TOTAL) begin // 524
					Vcnt <= '0;
					activeArea <= 1'b1;
				end else begin
					// 320x240
					if (!mode && (Vcnt < 240-1)) begin
						activeArea <= 1'b1;
					end
					// 160x120
					if (mode && (Vcnt < 120-1)) begin
						activeArea <= 1'b1;
					end
					Vcnt <= Vcnt + 1;
				end
			end else begin
				// 320x240
				if (!mode && (Hcnt == 320-1)) begin
					activeArea <= 1'b0;
				end
				// 160x120
				if (mode && (Hcnt == 160-1)) begin
					activeArea <= 1'b0;
				end
				Hcnt <= Hcnt + 1;
			end
		end
	end

	// generation of the horizontal synchronization signal Hsync
	always_ff @(posedge clk25) begin
		// check Hcnt >= 656 and Hcnt <= 751
		if ((Hcnt >= (H_DISPLAY+H_FRONT)) && (Hcnt <= (H_DISPLAY+H_FRONT+H_SYNC-1))) begin
			Hsync <= 1'b0;
		end else begin
			Hsync <= 1'b1;
		end
	end

	// generation of the vertical synchronization signal Vsync
	always_ff @(posedge clk25) begin
		// check Vcnt >= 490 and vcnt <= 491
		if (Vcnt >= (V_DISPLAY+V_FRONT) && Vcnt <= (V_DISPLAY+V_FRONT+VR-1)) begin
			Vsync <= 1'b0;
		end else begin
			Vsync <= 1'b1;
		end
	end

	// Blank and Nsync to control the ADV7123 converter
	assign Nsync = 1'b1;
	// this is to use the full resolution 640 x 480
	assign video = ((Hcnt < H_DISPLAY) && (Vcnt < V_DISPLAY)) ? 1'b1 : 1'b0;

	assign Nblank = video;
	assign clkout = clk25;

endmodule



