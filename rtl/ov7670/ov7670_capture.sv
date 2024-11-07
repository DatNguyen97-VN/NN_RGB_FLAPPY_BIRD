// Captures the pixels data of each frame coming from the OV7670 camera and 
// Stores them in block RAM
// The length of href controls how often pixels are captive - (2 downto 0) stores
// one pixel every 4 cycles.
// "line" is used to control how often data is captured. In this case every second or fourth line

module ov7670_capture (
	input logic pclk,                 // Pixel clock input from the OV7670 camera
	input logic vsync,                // Vertical sync signal, used to indicate the end of a frame
	input logic href,                 // Horizontal reference signal, indicates the start and end of a scanline
	input logic [7:0] d,              // 8-bit data bus from the camera carrying pixel data
	output logic [16:0] addr,         // Address output to store the captured pixels in memory
	output logic [15:0] dout,         // 12-bit data output containing RGB pixel data
	output logic we,                  // Write enable signal for writing data to memory
	output logic end_of_frame         // Indicates when the entire frame has been captured
);

	// Internal variables
	logic [15:0] d_latch;             // Latches the 16-bit pixel data (two 8-bit samples)
	logic [16:0] address;             // Stores the current address for memory write
	logic [1:0] line;                 // Keeps track of the current line number (every 4th line is captured)
	logic [6:0] href_last;            // Stores the href signal's history to detect transitions and control pixel capture
	logic we_reg;                     // Internal register to control write enable (delayed assignment to output)
	logic end_of_frame_reg;           // Register to signal the end of frame after a vsync pulse
	logic href_hold;                  // Holds the last state of the href signal for detecting edges
	logic latched_vsync;              // Latches the vsync signal to align with pclk
	logic latched_href;               // Latches the href signal to align with pclk
	logic [7:0] latched_d;            // Latches the 8-bit data from the camera to align with pclk

	// Address assignment
	assign addr = address;            // Output the current memory address
	assign we = we_reg;               // Output the write enable signal
	assign dout = {d_latch[15:11], d_latch[10:05], d_latch[04:00]}; // Format the 16-bit RGB output from latched pixel data
	assign end_of_frame = end_of_frame_reg; // Output the end-of-frame signal when a frame has been captured

	// Main capture process
	always_ff @(posedge pclk) begin : capture_process
		if (we_reg) begin
			address <= address + 17'd1;   // Increment the memory address after writing a pixel
		end

        // This is a bit tricky href starts a pixel transfer that takes 3 cycles
        //        Input   | state after clock tick   
        //         href   | wr_hold    d_latch           dout          we  address  address_next
        // cycle -1  x    |    xx      xxxxxxxxxxxxxxxx  xxxxxxxxxxxx  x   xxxx     xxxx
        // cycle 0   1    |    x1      xxxxxxxxRRRRRGGG  xxxxxxxxxxxx  x   xxxx     addr
        // cycle 1   0    |    10      RRRRRGGGGGGBBBBB  xxxxxxxxxxxx  x   addr     addr
        // cycle 2   x    |    0x      GGGBBBBBxxxxxxxx  RRRRGGGGBBBB  1   addr     addr+1

		// Detect the rising edge of href (start of a scanline)
		if (!href_hold && latched_href) begin
			case (line)
				2'b00 :  line <= 2'b01;    // 1st row of pixels
				2'b01 :  line <= 2'b10;    // 2nd row of pixels
				2'b10 :  line <= 2'b11;    // 3rd row of pixels
				default: line <= 2'b00;    // 4th row of pixels
			endcase
		end
		href_hold <= latched_href;        // Hold the href state for edge detection

		// Capture the 12-bit RGB data (two 8-bit samples per pixel)
		if (latched_href) begin
			d_latch <= {d_latch[7:0], latched_d}; // Store the pixel data (concatenate previous and current samples)
		end
		we_reg <= 1'b0;                    // Default write enable is disabled

		// Handle frame capture and reset on vsync
		if (latched_vsync) begin
			address   <= '0;              // Reset the address to 0 on vsync (new frame)
			href_last <= '0;              // Reset href history
			line      <= '0;              // Reset line counter
			end_of_frame_reg <= 1'b1;     // Signal the end of the frame
		end else begin
			// Capture pixel data when href_last[2] (320x240)
			// and href_last[6] (160x120) indicates valid pixel transfer
			if (href_last[6]) begin
				// 160x120
				if (line == 2'b11) begin  // Every 8 byte get 2 byte
					we_reg <= 1'b1;       // Enable writing to memory when capturing valid pixels
				end
				href_last <= '0;          // Reset href_last after capture
			end else begin
				href_last <= {href_last[5:0], latched_href}; // Shift href history
			end
			end_of_frame_reg <= 1'b0;     // Reset end-of-frame signal after handling
		end
	end : capture_process

	// Capture the camera data on the negative edge of pclk
	always_ff @(negedge pclk) begin
		latched_d     <= d;               // Latch the data input on the negative edge of pclk
        latched_href  <= href;            // Latch the href input
        latched_vsync <= vsync;           // Latch the vsync input
	end
	
endmodule
