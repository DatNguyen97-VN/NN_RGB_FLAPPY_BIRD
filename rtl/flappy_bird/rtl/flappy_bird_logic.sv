

module  flappy_bird_logic
(
    input   wire            sys_clk     ,   // input working clock, frequency 50MHz
    input   wire            sys_rst_n   ,   // input reset signal, low level valid
    input   wire  [3:0]     data_in     ,   // input button
    
    output  wire  [3:0]     led_out,
    output  wire            vga_hsync     ,
    output  wire            vga_vsync     ,
    output  wire            Nblank  ,
    output  wire            Nsync  ,
    output  wire            vga_clk,
    output  wire  [7:0]     vga_red,
    output  wire  [7:0]     vga_green,
    output  wire  [7:0]     vga_blue

);

//********************************************************************//
//****************** Parameter and Internal Signal *******************//
//********************************************************************//
//wire define
wire            rst_n   ;   // VGA module reset signal
wire    [09:0]  pix_x   ;   // VGA effective display area X-axis coordinate
wire    [09:0]  pix_y   ;   // VGA effective display area Y-axis coordinate
wire    [15:0]  pix_data;   // VGA pixel color information
wire            hsync   ;   // Output line synchronization signal
wire            vsync   ;   // Output field synchronization signal
wire    [15:0]  rgb     ;   // Output pixel information
wire            rgb_valid;
wire    [19:0]  score   ;
reg             vga_clk_gen;

//rst_n: VGA module reset signal
assign  rst_n   = sys_rst_n;
//********************************************************************//
//*************************** Instantiation **************************//
//********************************************************************//

// Generate 25 MHz clock from 50 MHz clock
always @(posedge sys_clk or negedge sys_rst_n) begin
	if (!sys_rst_n) begin
		vga_clk_gen <= 1'b0;
	end else begin
		vga_clk_gen <= ~vga_clk_gen;
	end
end

//The vga module is used to generate images, which are actually displayed as HDMI
//------------- vga_ctrl_inst -------------
vga_ctrl  vga_ctrl_inst
(
    .vga_clk    (vga_clk_gen    ),  // Input working clock, frequency 25MHz, 1bit
    .sys_rst_n  (rst_n      ),  // Input reset signal, low level valid, 1bit
    .pix_data   (pix_data   ),  // Input pixel color information, 16bit

    .pix_x      (pix_x      ),  // Output VGA valid display area pixel X-axis coordinate, 10bit
    .pix_y      (pix_y      ),  // Output VGA valid display area pixel Y-axis coordinate,10bit
    .hsync      (hsync      ),  // Output line synchronization signal, 1bit
    .vsync      (vsync      ),  // Output field synchronization signal, 1bit
    .rgb_valid  (rgb_valid  ),
    .rgb        (rgb        )   // Output pixel color information, 16bit
);

//------------- vga_pic_inst -------------
vga_pic vga_pic_inst
(
    .vga_clk    (vga_clk_gen    ),  // Input working clock, frequency 25MHz, 1bit
    .sys_rst_n  (rst_n      ),  // Input reset signal, low level is valid, 1bit
    .pix_x      (pix_x      ),  // Input VGA effective display area pixel point X-axis coordinate, 10bit
    .pix_y      (pix_y      ),  // Input VGA effective display area pixel point Y-axis coordinate, 10bit
    .data_in    (data_in    ),
    
    .pix_data   (pix_data   ),  // Output pixel point color information, 16bit
    .score      (score      )
);

/* RED LED */
led led_inst
(   
    .clk          (vga_clk_gen   ),
    .rst_n        (sys_rst_n ),
    .data_in      (data_in    ),  //input     key_in

    .led_out      (led_out   )   //output    led_out
);

/* VGA Signals */
assign vga_red   = {rgb[15:11], rgb[15:13]};
assign vga_green = {rgb[10:05], rgb[10:09]};
assign vga_blue  = {rgb[04:00], rgb[04:02]};

assign vga_hsync = hsync;
assign vga_vsync = vsync;

assign Nblank = rgb_valid;

assign Nsync = 1'b1;

assign vga_clk = vga_clk_gen;

endmodule
