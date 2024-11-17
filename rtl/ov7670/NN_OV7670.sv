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
	/* VGA signals */
	input  logic vga_vsync,                        // Vertical sync signal for VGA
	output logic [7:0] vga_r,                      // Red VGA output (8-bit)
	output logic [7:0] vga_g,                      // Green VGA output (8-bit)
	output logic [7:0] vga_b,                      // Blue VGA output (8-bit)
	input  logic activeArea,                       // Indicates active area of the screen for VGA
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
	output logic [1:0] LED_done,                   // Indicates when the video processing is done
	output int   y_position,                       // centroids of the object follow y-axis
	output int   x_position                        // centroids of the object follow x-axis
);

	// Buffer 1 signals for storing video frames
	logic wren_buf_1;                              // Write enable for buffer 1
	logic [16:0] wraddress_buf_1;                  // Write address for buffer 1
	logic [15:0] wrdata_buf_1;                     // Write data for buffer 1
	logic [16:0] rdaddress_buf_1;                  // Read address for buffer 1
	logic [23:0] rddata_buf_1;                     // Read data from buffer 1

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
	logic nBlank;                                  // VGA blanking signal
	logic vSync;                                   // VGA vertical sync signal

	// Multiplexing buffer data to RGB output
	logic [15:0] data_to_rgb;                      // Data from buffer to RGB for VGA

	// Neural network signals for color dection
	logic [07:0] nn_vga_r;
	logic [07:0] nn_vga_g;
	logic [07:0] nn_vga_b;
	logic        nn_we;
	logic [16:0] nn_addr;

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
	//assign LED_done = (state_current == S4_NORMAL_VIDEO_MODE);

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
		.wraddress (nn_addr),
		.data      ({nn_vga_r, nn_vga_g, nn_vga_b}),
		.wren      (nn_we)
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
		.addr         (wraddress_buf1_from_ov7670_capture),
		.dout         (wrdata_buf1_from_ov7670_capture),
		.we           (wren_buf1_from_ov7670_capture),
		.end_of_frame ()
	);

    /*
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
	); */

	// RGB block to convert buffer data to VGA RGB signals
	RGB Inst_RGB (
		.Din    (wrdata_buf1_from_ov7670_capture),
		.Nblank (1'b1),
		.R      (red),
		.G      (green),
		.B      (blue)
	);

	// VGA signal assignments
	assign vga_r = rddata_buf_1[23:16];
	assign vga_g = rddata_buf_1[15:08];
	assign vga_b = rddata_buf_1[07:00];

	// Address generator for reading frame buffer
	Address_Generator Inst_Address_Generator (
		.rst     (btn_RESET),
		.clk25   (clk_25_vga),
		.enable  (activeArea),
		.vsync   (vga_vsync),
		.address (rdaddress_buf12_from_addr_gen)
	);

	/* Neural Network RGB */
    nn_rgb nn_rgb_inst (
        .clk       (clk_25_vga    ),
        .reset_n   (btn_RESET  ),
		.vsync_in  (ov7670_vsync),
		.href_in   (ov7670_href),
        .addr_in   (wraddress_buf1_from_ov7670_capture         ),
        .we_in     (wren_buf1_from_ov7670_capture ),
        .r_in      (red        ),
        .g_in      (green      ),
        .b_in      (blue       ),
        .addr_out  (nn_addr           ),
        .we_out    (nn_we          ),
        .r_out     (nn_vga_r   ),
        .g_out     (nn_vga_g   ),
        .b_out     (nn_vga_b   ),
        .clk_o     (           ),
        .led       (LED_done   ),
		.y_position(y_position ),
		.x_position(x_position)
    );

endmodule
