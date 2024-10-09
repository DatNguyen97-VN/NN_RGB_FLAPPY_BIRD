module RGB (
	input logic [15:00] Din, // 8-bit pixel gray level
	input logic Nblank, // signal indicates the display area, excluding the display area all three colors take 0
	output logic [07:00] R, // the RGB888 standard
	output logic [07:00] G, // the RGB888 standard
	output logic [07:00] B // the RGB888 standard
);
	// Convert RGB565 to RGB888
	assign R = Nblank ? {Din[15:11], Din[15:13]} : '0;
	assign G = Nblank ? {Din[10:05], Din[10:09]} : '0;
	assign B = Nblank ? {Din[04:00], Din[04:02]} : '0;

endmodule