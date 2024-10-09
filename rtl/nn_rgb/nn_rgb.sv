// top level
`ifndef  _INCL_DEFINITIONS
  `define _INCL_DEFINITIONS
  import CONFIG::*;
`endif // _INCL_DEFINITIONS

module nn_rgb (
    /* control signals */
    input logic clk, // input clock 74.25 MHz, video 720p
    input logic reset_n, // reset (invoked during configuration)
    input logic [2:0] enable_in, // three slide switches
    /* video in */
    input logic vs_in, // vertical sync
    input logic hs_in, // horizontal sync
    input logic de_in, // data enable is '1' for valid pixel
    input logic [7:0] r_in, // red component of pixel
    input logic [7:0] g_in, // green component of pixel
    input logic [7:0] b_in, // blue component of pixel
    /* video out */
    output logic vs_out, // vertical sync
    output logic hs_out, // horizontal sync
    output logic de_out, // data enable is '1' for valid pixel
    output logic [7:0] r_out, // red component of pixel
    output logic [7:0] g_out, // green component of pixel
    output logic [7:0] b_out, // blue component of pixel
    /* -- */
    output logic clk_o, // output clock (do not modify)
    output logic [2:0] led // not supported by remote lab
);
    // input FFs
    logic reset;
    logic [2:0] enable;
    logic vs_0, hs_0, de_0;

    // output of signal processing
    logic vs_1, hs_1, de_1;
    logic [7:0] result_r, result_g, result_b;
    
    // RGB luminance output
    typedef logic [0:len-3][7:0] y_array_t;
    y_array_t y;

    // object centroids variable
    int num_pixel; // number of pixel
    int sum_y_axis; // sum possition of pixel at y-axis
    int y_axis; // y-axis value
    int aver_y_axis; // current y-axis of object
    int old_frame_y_axis; // old y-axis of object

    // endline signal and FFs 
    logic endline_ff;

    // new frame FFs
    logic frame_ff;

    // y-axis value of frame and old-frame
    logic [15:0] y_frame, y_old_frame;

    // object up
    logic up;


    // generate the neural network with the parameters from config.vhd
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
                    .out(connection[connnectionRange[i]+j])
                );
            end : gen_neuron
        end : gen_layer
    endgenerate

    // delay the control signals for the time of the processing
    control #(
        .delay(($size(networkStructure)-1)*4 + 1)
    ) cu (
        .clk(clk),
        .reset(reset),
        .vs_in(vs_0),
        .hs_in(hs_0),
        .de_in(de_0),
        .vs_out(vs_1),
        .hs_out(hs_1),
        .de_out(de_1)
    );
    
    // convert RGB to luminance
    always_ff @( posedge clk ) begin : RGB_compute
        // input FFs for control
        reset <= ~ reset_n;
        enable <= enable_in;
        // input FFs for video signal
        vs_0  <= vs_in;
        hs_0  <= hs_in;
        de_0  <= de_in;
     
        // assign values of the input layer
        connection[2:0] <= {b_in, g_in, r_in};

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
        if (connection[len-1] > 70) begin
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
        end else if (connection[len-2] > 70) begin
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
        vs_out  <= vs_1;
        hs_out  <= hs_1;
        de_out  <= de_1;
        r_out   <= result_r;
        g_out   <= result_g;
        b_out   <= result_b;
    end

    /* ------------------------------------------ */
    /* Compute object centroids follow the y-axis */
    /* ------------------------------------------ */
    always_ff @(posedge clk) begin : endline_FFs
        endline_ff <= de_1;
    end

    always_ff @(posedge clk) begin : frame_FFs
        frame_ff <= vs_1;
    end

    // increate y-axis variable
    always_ff @(posedge clk) begin
        if (!frame_ff && vs_1) begin
            y_axis <= '0;
        end else if (endline_ff && (!de_1)) begin
            y_axis <= y_axis + 32'd1;
        end
    end

    // count the correct condition pixel
    always_ff @(posedge clk) begin  
        if (!frame_ff && vs_1) begin
            num_pixel <= '0;
            sum_y_axis <= '0;
        end else begin
            if (connection[len-1] > 55) begin
               if (connection[len-1] > connection[len-2]) begin
                   sum_y_axis <= sum_y_axis + y_axis;
                   num_pixel <= num_pixel + 32'd1;
               end
            end
        end
    end

    // compute average y-axis value
    always_comb begin
        if ((num_pixel != 32'd0 ) && (sum_y_axis != 32'd0)) begin
            aver_y_axis = sum_y_axis / num_pixel;
        end else begin
            aver_y_axis = '0;
        end
    end

    /* ------------------------------------------ */
    /* Check y-axis value of frame and old-Frame  */
    /* ------------------------------------------ */
    always_ff @(posedge clk or negedge reset_n) begin : get_y_axis_frame
        if (!reset_n) begin
            y_frame <= '0;
            y_old_frame <= '0;
        end else if (!frame_ff && vs_1) begin // check new frame
            y_frame <= aver_y_axis;
            y_old_frame <= y_frame;
        end
    end

    always_ff @( posedge clk ) begin : check_frame_and_old_frame
        if ((y_frame != 0) && (y_old_frame != 0) && // both it is zero when start system
            (frame_ff && !vs_1) && // check at first line of third-frame
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
    
endmodule