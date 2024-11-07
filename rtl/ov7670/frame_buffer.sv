// create a buffer to store pixels data for a frame of 320x240 pixels;
// data for each pixel is 12 bits;
// that is 76800 pixels; hence, address is represented on 17 bits 
// (2^17 = 131072 > 76800);
// Notes: 
// 1) If we wanted to work with 640x480 pixels, that would require
// an amount of embedded RAM that is not available on the Cyclone IV E of DE2-115;
// 2) We create the buffer with 76800 by stacking-up two blocks
// of 2^16 = 65536 addresses; 

module frame_buffer (
	input logic [23:0] data,
	input logic [16:0] rdaddress,
	input logic rdclock,
	input logic [16:0] wraddress,
	input logic wrclock,
	input logic wren,
	output logic [23:0] q
);
	// read signals
	logic [23:0] q_top;
	logic [23:0] q_bottom;

	// write signals
	logic wren_top;
	logic wren_bottom;

	my_frame_buffer_15to0 Inst_buffer_top (
		.data(data),
		.rdaddress(rdaddress[15:0]),
		.rdclock(rdclock),
		.wraddress(wraddress[15:0]),
		.wrclock(wrclock),
		.wren(wren_top),
		.q(q_top)
	);

	my_frame_buffer_15to0 Inst_buffer_bottom (
		.data(data),
		.rdaddress(rdaddress[15:0]),
		.rdclock(rdclock),
		.wraddress(wraddress[15:0]),
		.wrclock(wrclock),
		.wren(wren_bottom),
		.q(q_bottom)
	);

	always_comb begin
		case (wraddress[16])
			1'b0 : begin wren_top = wren; wren_bottom = 1'b0; end
			1'b1 : begin wren_top = 1'b0; wren_bottom = wren; end
			default: begin
				wren_top = 1'b0; wren_bottom = 1'b0;
			end
		endcase
	end

	always_comb begin
		case (rdaddress[16])
			1'b0 : q = q_top;
			1'b1 : q = q_bottom;
			default: begin
				q = '0;
			end
		endcase
	end
	
endmodule