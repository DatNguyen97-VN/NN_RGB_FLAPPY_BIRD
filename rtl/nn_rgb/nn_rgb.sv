//`ifndef  _INCL_DEFINITIONS
//  `define _INCL_DEFINITIONS
//  `include "../../nn_rgb/config.sv"
//`endif // _INCL_DEFINITIONS

module nn_rgb (
    /* control signals */
    input logic clk, // input clock 74.25 MHz, video 720p
    input logic reset_n, // reset (invoked during configuration)
    /* video in */
    input logic vsync_in, // Vertical sync from OV7670 camera
    input logic [16:0] addr_in, // data address
    input logic we_in, // write enable
    input logic [7:0] r_in, // red component of pixel
    input logic [7:0] g_in, // green component of pixel
    input logic [7:0] b_in, // blue component of pixel
    /* video out */
    output logic [16:0] addr_out, // data address
    output logic we_out, // write enable
    output logic [7:0] r_out, // red component of pixel
    output logic [7:0] g_out, // green component of pixel
    output logic [7:0] b_out, // blue component of pixel
    /* -- */
    output logic clk_o, // output clock (do not modify)
    output logic [2:0] led, // not supported by remote lab
    output int   y_position,
    output int   x_position
);
    // input FFs
    logic reset;
    logic [2:0] enable;
    logic vs_0, hs_0, de_0;

    // connection 2 downto 0 is the input of the neural network
	// connection 11 downto 10 is the output of the neural network
    logic [11:0][7:0] connection;

    // output of signal processing
    logic vs_1, hs_1, de_1;
    logic [7:0] result_r, result_g, result_b;
    
    // RGB luminance output
    typedef logic [0:len-3][7:0] y_array_t;
    y_array_t y;

    // object centroids variable
    int num_pixel; // number of pixel
    int sum_y_axis; // sum possition of pixel at y-axis
    int sum_x_axis; // sum possition of pixel at x-axis
    int aver_y_axis; // current y-axis of object
    int aver_x_axis; // current x-axis of object
    int old_frame_y_axis; // old y-axis of object

	logic vsync_hold; // Holds the last state of the vsync signal for detecting edges

    // input FFs for video control
    logic vsync;

    // y-axis and x-axis value of frame and old-frame
    int y_frame, y_old_frame;
    int x_frame, x_old_frame;

    // object up
    logic up;


    // generate the neural network with the parameters from config.sv
    // the outer loops creates the layers and the inner loop the neurons within the layer
    // input Layer is assgined later
    genvar i,j;
    generate
        // layers
        for (i = 1; i < $size(networkStructure); i++) begin : gen_layer
            // neurons within the Layers
            for (j = 0; j < networkStructure[i]; j++) begin : gen_neuron
                neuron #(
                    .h_weight_idx(positions[j+1][i]-1),
                    .l_weight_idx(positions[j][i])
                ) knot (
                    .clk(clk),
                    .l_connection_idx(connnectionRange[i-1]),
                    .connection(connection),
                    .out(connection[connnectionRange[i]+j])
                );
            end : gen_neuron
        end : gen_layer
    endgenerate

    // delay the control signals for the time of the processing
    control #(
        .delay(($size(networkStructure)-1)*4+1)
    ) cu (
        .clk(clk),
        .vsync_i(vsync_in),
        .addr_i(addr_in),
        .we_i(we_in),
        .vsync_o(vsync),
        .addr_o(addr_out),
        .we_o(we_out)
    );
    
    // convert RGB to luminance
    always_ff @( posedge clk ) begin : RGB_compute
        // assign values of the input layer
        connection[0] <= r_in;
        connection[1] <= g_in;
        connection[2] <= b_in;

        // convert RGB to luminance: Y (5*R + 9*G + 2*B) / 16
        y[0] <= (5*connection[0] + 9*connection[1] + 2*connection[2]) / 16;
        // loop
        for (int i = 1; i <= ($size(networkStructure)-1)*4; i++) begin
            y[i] <= y[i-1];
        end
    end : RGB_compute

    logic [7:0] luminance;
    logic [7:0] r_yellow, r_blue, r_gray;
    logic [7:0] g_yellow, g_blue, g_gray;
    logic [7:0] b_yellow, b_blue, b_gray;  

    always_comb begin
        // output processing
        // assign the pixel a value depending on the output of the neural network
        luminance = y[($size(networkStructure)-1)*4]; // a hidden layer delay is 4 cycle
        // yellow: amplify red and green
        r_yellow = {1'b1, luminance[7:1]};
        g_yellow = {1'b1, luminance[7:1]};
        b_yellow = {1'b0, luminance[7:1]};
        // blue: amplify blue
        r_blue = {1'b0, luminance[7:1]};
        g_blue = {1'b0, luminance[7:1]};
        b_blue = {1'b1, luminance[7:1]};
        // gray: use luminance
        r_gray = luminance;
        g_gray = luminance;
        b_gray = luminance;
    end
    
    // RGB output
    always_ff @(posedge clk) begin
        if (connection[len-1] > 55) begin
            if (connection[len-1] > connection[len-2]) begin
                // yellow
                result_r <= r_yellow;
                result_g <= g_yellow;
                result_b <= b_yellow;
            end else begin
                // blue
                result_r <= r_blue;
                result_g <= g_blue;
                result_b <= b_blue;
            end
        end else if (connection[len-2] > 55) begin
            // blue
            result_r <= r_blue;
            result_g <= g_blue;
            result_b <= b_blue;
        end else begin
            // gray
            result_r <= r_gray;
            result_g <= g_gray;
            result_b <= b_gray;
        end

        // output FFs
        r_out   <= result_r;
        g_out   <= result_g;
        b_out   <= result_b;
    end

    /* ------------------------------------------ */
    /* Compute object centroids follow the y-axis */
    /* ------------------------------------------ */
    // detect the rising edge of vsync
    always_ff @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            vsync_hold <= 1'b0;
        end else begin
            vsync_hold <= vsync;
        end
    end

    // count the correct condition pixel
    always_ff @(posedge clk) begin  
        if (!vsync_hold && vsync) begin
            num_pixel  <= 0;
            sum_y_axis <= 0;
            sum_x_axis <= 0;
        end else begin
            if (connection[len-1] > 55 || connection[len-2] > 55) begin
                sum_y_axis <= sum_y_axis + addr_out/159;
                sum_x_axis <= sum_x_axis + addr_out%159;
                num_pixel  <= num_pixel + 32'd1;
            end
        end
    end

    // compute average y-axis value
    always_comb begin
        if (num_pixel) begin
            aver_y_axis = sum_y_axis / num_pixel;
            aver_x_axis = sum_x_axis / num_pixel;
        end else begin
            aver_y_axis = 0;
            aver_x_axis = 0;
        end
    end

    /* ------------------------------------------ */
    /* Check y-axis value of frame and old-Frame  */
    /* ------------------------------------------ */
    always_ff @(posedge clk or negedge reset_n) begin : get_y_axis_frame
        if (!reset_n) begin
            y_frame     <= 0;
            y_old_frame <= 0;
            x_frame     <= 0;
            x_old_frame <= 0;
        end else if (!vsync_hold && vsync) begin // check new frame
            y_frame     <= aver_y_axis;
            y_old_frame <= y_frame;
            x_frame     <= aver_x_axis;
            x_old_frame <= x_frame;
        end
    end

    always_ff @( posedge clk ) begin : check_frame_and_old_frame
        if (y_frame && y_old_frame && // both it is zero when start system
            !vsync_hold && vsync && // check at first line of third-frame
           (y_frame > y_old_frame)) begin // check increate y-axis value
            up <= 1'b1;
        end else begin
            up <= 1'b0;  
        end
    end

    /* -------------------------------------------------- */
    /* Maintain turn-up signal during on 10 milion cycles */
    /* -------------------------------------------------- */

    assign clk_o = clk;
    assign led = 3'b000;
    assign y_position = y_frame;
    assign x_position = x_frame;
    
endmodule