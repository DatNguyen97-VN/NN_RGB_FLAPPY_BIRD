module my_frame_buffer_15to0(
	input logic [23:0] data,
	input logic [15:0] rdaddress,
	input logic rdclock,
	input logic [15:0] wraddress,
	input logic wrclock,
	input logic wren,
	output logic [23:0] q
);
	logic [23:0] mem_file [19200];

	// read data
	always_ff @(posedge rdclock) begin
		q <= mem_file[rdaddress];
	end

	// write data
	always_ff @(posedge wrclock) begin
		if (wren) begin
			mem_file[wraddress] <= data;
		end
	end
	
endmodule