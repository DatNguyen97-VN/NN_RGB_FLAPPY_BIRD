// Features:  
//   > Normal video mode
//   > Realtime hand tracking video mode
// 
// This design connects a CMOS camera (OV7670 module) to the DE2-115 board.
// Video frames are captured from the camera, buffered on the FPGA (using embedded RAM),
// and displayed on the VGA monitor connected to the board.

module digital_cam_impl(
	/* System signals */
	input  logic clk_50,                           // 50 MHz clock input
	input  logic btn_RESET,                        // Manual reset (KEY0)
	input  logic slide_sw_resend_reg_values,       // Rewrite all OV7670's registers (resend signal)
	input  logic slide_sw_NORMAL_OR_HANDDETECT,    // Mode selection: 0 for normal video, 1 for hand tracking
	input  logic mode_320x240_160x120,             // Mode selection: 0 for 320x240, 1 for 160x120
	/* VGA signals */
	output logic vga_hsync,                        // Horizontal sync signal for VGA
	output logic vga_vsync,                        // Vertical sync signal for VGA
	output logic [7:0] vga_r,                      // Red VGA output (8-bit)
	output logic [7:0] vga_g,                      // Green VGA output (8-bit)
	output logic [7:0] vga_b,                      // Blue VGA output (8-bit)
	output logic vga_blank_N,                      // VGA blanking signal
	output logic vga_sync_N,                       // VGA sync signal
	output logic vga_CLK,                          // VGA clock
	/* Camera signals */
	input  logic ov7670_pclk,                      // Pixel clock from OV7670 camera
	output logic ov7670_xclk,                      // Clock signal to OV7670 camera
	input  logic ov7670_vsync,                     // Vertical sync from OV7670 camera
	input  logic ov7670_href,                      // Horizontal reference signal from OV7670 camera
	input  logic [7:0] ov7670_data,                // 8-bit data from OV7670 camera
	output logic ov7670_sioc,                      // I2C clock signal to OV7670 camera
	inout  wire  ov7670_siod,                      // I2C data signal to OV7670 camera
	output logic ov7670_pwdn,                      // Power down signal for OV7670 camera
	output logic ov7670_reset,                     // Reset signal for OV7670 camera
	/* Status LEDs */
	output logic LED_config_finished,              // Indicates when OV7670 camera configuration is done
	output logic LED_dll_locked,                   // Indicates when the PLL is locked
	output logic LED_done                          // Indicates when the video processing is done
);

	// Buffer 1 signals for storing video frames
	logic wren_buf_1;                              // Write enable for buffer 1
	logic [16:0] wraddress_buf_1;                  // Write address for buffer 1
	logic [15:0] wrdata_buf_1;                     // Write data for buffer 1
	logic [16:0] rdaddress_buf_1;                  // Read address for buffer 1
	logic [15:0] rddata_buf_1;                     // Read data from buffer 1

	// Signals multiplexed into buffer 1
	logic [16:0] rdaddress_buf12_from_addr_gen;    // Address generator output for buffer 1 read address
	logic wren_buf1_from_ov7670_capture;           // Write enable from OV7670 capture
	logic [16:0] wraddress_buf1_from_ov7670_capture; // Write address from OV7670 capture
	logic [15:0] wrdata_buf1_from_ov7670_capture;  // Write data from OV7670 capture

	// User control signals
	logic resend_reg_values;                       // Resend configuration values to OV7670 camera
	logic normal_or_HandTracking;                  // Mode: 0 for normal, 1 for hand tracking
	logic clk_25_vga;                              // 25 MHz clock for VGA

	// VGA-related signals
	logic [7:0] red, green, blue;                  // RGB signals for VGA output
	logic activeArea;                              // Indicates active area of the screen for VGA
	logic nBlank;                                  // VGA blanking signal
	logic vSync;                                   // VGA vertical sync signal

	// Multiplexing buffer data to RGB output
	logic [15:0] data_to_rgb;                      // Data from buffer to RGB for VGA

	// FSM states for controlling the camera
	typedef enum int {
		S0_RESET,                                  // Reset state
		S1_RESET_HT,                               // Reset state for hand tracking
		S2_PROCESS_HT,                             // Hand tracking processing
		S3_DONE_HT,                                // Hand tracking done
		S4_NORMAL_VIDEO_MODE                       // Normal video mode
	} state_t;

	state_t state_current, state_next;             // Current and next states

	// State machine for handling video modes and process control
	/* Progress 1: State register */
	always_ff @(posedge clk_25_vga or negedge btn_RESET) begin : progress_1
		if (!btn_RESET) begin
			state_current <= S0_RESET;
		end else begin
			state_current <= state_next;
		end
	end

	/* Progress 2: Next state and output logic */
	always_comb begin : progress_2
		state_next = state_current;               // Default next state
		// Default signal values
		data_to_rgb = '0;
		wren_buf_1 = 1'b1;
		wraddress_buf_1 = '0;
		wrdata_buf_1 = '0;
		rdaddress_buf_1 = '0;

		// FSM for different modes
		case (state_current)
			S0_RESET: begin
				if (!slide_sw_NORMAL_OR_HANDDETECT) begin
					// Normal video mode
					state_next = S4_NORMAL_VIDEO_MODE;
					data_to_rgb = rddata_buf_1;       // Display buffer 1 on VGA
					wren_buf_1 = wren_buf1_from_ov7670_capture;
					wraddress_buf_1 = wraddress_buf1_from_ov7670_capture;
					wrdata_buf_1 = wrdata_buf1_from_ov7670_capture;
					rdaddress_buf_1 = rdaddress_buf12_from_addr_gen;
				end
				// Hand tracking mode can be added here
			end

			S4_NORMAL_VIDEO_MODE: begin
				// Same as S0_RESET for now, can be extended later
				state_next = S4_NORMAL_VIDEO_MODE;
				data_to_rgb = rddata_buf_1;
				wren_buf_1 = wren_buf1_from_ov7670_capture;
				wraddress_buf_1 = wraddress_buf1_from_ov7670_capture;
				wrdata_buf_1 = wrdata_buf1_from_ov7670_capture;
				rdaddress_buf_1 = rdaddress_buf12_from_addr_gen;
			end

			default: begin
				state_next = S0_RESET;
			end
		endcase
	end

	// Assign normal or hand tracking mode based on switch
	assign normal_or_HandTracking = slide_sw_NORMAL_OR_HANDDETECT;

	// Assign status LEDs
	assign LED_dll_locked = ~btn_RESET;
	assign LED_done = (state_current == S4_NORMAL_VIDEO_MODE);

	// Generate 25 MHz clock from 50 MHz clock
	always_ff @(posedge clk_50 or negedge btn_RESET) begin : clk_25mhz
		if (!btn_RESET) begin
			clk_25_vga <= 1'b0;
		end else begin
			clk_25_vga <= ~clk_25_vga;
		end
	end

	// Frame buffer to store video frames
	frame_buffer Inst_frame_buf_1 (
		.rdaddress (rdaddress_buf_1),
		.rdclock   (clk_25_vga),
		.q         (rddata_buf_1),
		.wrclock   (clk_25_vga),
		.wraddress (wraddress_buf_1),
		.data      (wrdata_buf_1),
		.wren      (wren_buf_1)
	);

	// OV7670 camera controller for setting up the camera registers
	ov7670_controller Inst_ov7670_controller (
		.clk             (clk_50),
		.rst             (btn_RESET),
		.resend          (slide_sw_resend_reg_values),
		.config_finished (LED_config_finished),
		.sioc            (ov7670_sioc),
		.siod            (ov7670_siod),
		.reset           (ov7670_reset),
		.pwdn            (ov7670_pwdn),
		.xclk            (ov7670_xclk)
	);

	// OV7670 capture block to capture frames from the camera
	ov7670_capture Inst_ov7670_capture (
		.pclk         (ov7670_pclk),
		.vsync        (ov7670_vsync),
		.href         (ov7670_href),
		.d            (ov7670_data),
		.mode         (mode_320x240_160x120),
		.addr         (wraddress_buf1_from_ov7670_capture),
		.dout         (wrdata_buf1_from_ov7670_capture),
		.we           (wren_buf1_from_ov7670_capture),
		.end_of_frame ()
	);

	// VGA block to drive VGA signals
	VGA Inst_VGA (
		.rst        (btn_RESET),
		.clk25      (clk_25_vga),
		.mode       (mode_320x240_160x120),
		.clkout     (vga_CLK),
		.Hsync      (vga_hsync),
		.Vsync      (vSync),
		.Nblank     (nBlank),
		.Nsync      (vga_sync_N),
		.activeArea (activeArea)
	);

	// RGB block to convert buffer data to VGA RGB signals
	RGB Inst_RGB (
		.Din    (data_to_rgb),
		.Nblank (activeArea),
		.R      (red),
		.G      (green),
		.B      (blue)
	);

	// VGA signal assignments
	assign vga_r = red;
	assign vga_g = green;
	assign vga_b = blue;
	assign vga_vsync = vSync;
	assign vga_blank_N = nBlank;

	// Address generator for reading frame buffer
	Address_Generator Inst_Address_Generator (
		.rst     (btn_RESET),
		.clk25   (clk_25_vga),
		.enable  (activeArea),
		.mode    (mode_320x240_160x120),
		.vsync   (vSync),
		.address (rdaddress_buf12_from_addr_gen)
	);

endmodule
