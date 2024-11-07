module Address_Generator (
	input logic rst,
	input logic clk25, // 25 MHz clock and activation signal respectively
	input logic enable,
	input logic vsync,
	output logic [16:00] address // address generated
);
	// intermediate signal
	logic [$bits(address)-1:00] val;

	assign address = val;

	always_ff @(posedge clk25 or negedge rst) begin : address_generated
		if (!rst) begin
			val <= '0;
		end else begin
			// if enable = 0 we stop address generation
			if (enable) begin
				// if the memory space is completely scanned
				if (val < 160*120) begin
					val <= val + 1;
				end
			end
			//
			if (!vsync) begin
				val <= '0;
			end
		end
	end

endmodule