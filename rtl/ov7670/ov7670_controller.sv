// Controller for the OV760 camera - transferes registers to the 
// camera over an I2C like bus

module ov7670_controller (
	input  logic clk,
	input  logic rst,
	input  logic resend,
	output logic config_finished,
	output logic sioc,
	inout  wire  siod, // inout type must be connected a net expression
	output logic reset,
	output logic pwdn,
	output logic xclk
);
	logic sys_clk;
	logic [15:00] command;
	logic finished;
	logic taken;
	logic send;
	/* device write ID; see datasheet of camera module */
	const logic [07:00] camera_address = 8'h42;

	assign config_finished = finished;
	assign send = ~ finished;

	i2c_sender Inst_i2c_sender (
		.clk   (clk),
		.rst   (rst),
        .taken (taken),
        .siod  (siod),
        .sioc  (sioc),
        .send  (send),
        .id    (camera_address),
        .regis (command[15:08]),
        .value (command[07:00])
	);

	// Normal mode
	assign reset = 1'b1;
	// Power device up
	assign pwdn = 1'b0;
	assign xclk = sys_clk;

	ov7670_registers Inst_ov7670_registers (
		.clk      (clk),
		.rst      (rst),
		.advance  (taken),
		.command  (command),
		.finished (finished),
		.resend   (resend)
	);

	always_ff @(posedge clk or negedge rst) begin
		if (!rst) begin
			sys_clk <= 1'b0;
		end else begin
			sys_clk <= ~ sys_clk;
		end
	end
endmodule