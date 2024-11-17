//`ifndef  _INCL_DEFINITIONS
//  `define _INCL_DEFINITIONS
//  `include "../../nn_rgb/config.sv"
//`endif // _INCL_DEFINITIONS

module nn_rgb (
    /* control signals */
    input logic clk, // input clock 50 MHz, video 480p
    input logic reset_n, // reset (invoked during configuration)
    /* video in */
    input logic vsync_in, // Vertical sync from OV7670 camera
    input logic href_in, // Horizontal reference signal from OV7670 camera
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
    output logic [1:0] led, // not supported by remote lab
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

    // normal RGB output
    logic [23:00] nor_rgb [($size(networkStructure)-1)*4];

    // object centroids variable
    int num_pixel; // number of pixel
    int sum_y_axis; // sum possition of pixel at y-axis
    int aver_y_axis; // current y-axis of object
    int sum_x_axis; // sum possition of pixel at y-axis
    int aver_x_axis; // current y-axis of object

    // delay frame
    int yFrame_prev [7];
    int xFrame_prev [7];

    int debounce_jumping_delay;
    logic jumping;
    int debounce_backup_delay;
    logic backup;

	logic vsync_hold; // Holds the last state of the vsync signal for detecting edges

    // input FFs for video control
    logic vsync;
    logic href;

    // object up and back
    logic up;
    logic back;


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
        .href_i(href_in),
        .addr_i(addr_in),
        .we_i(we_in),
        .vsync_o(vsync),
        .href_o(href),
        .addr_o(addr_out),
        .we_o(we_out)
    );
    
    // convert RGB to luminance
    always_ff @( posedge clk ) begin : RGB_compute
        // assign values of the input layer
        connection[0] <= r_in;
        connection[1] <= g_in;
        connection[2] <= b_in;

        nor_rgb[0] <= {r_in, g_in, b_in};

        // convert RGB to luminance: Y (5*R + 9*G + 2*B) / 16
        y[0] <= (5*connection[0] + 9*connection[1] + 2*connection[2]) / 16;
        // loop
        for (int i = 1; i <= ($size(networkStructure)-1)*4; i++) begin
            y[i] <= y[i-1];
        end
        // delay normal rgb to vga
        for (int i = 1; i < $size(nor_rgb); i++) begin
            nor_rgb[i] <= nor_rgb[i-1];
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
        r_gray = nor_rgb[$size(nor_rgb)-1][23:16];
        g_gray = nor_rgb[$size(nor_rgb)-1][15:08];
        b_gray = nor_rgb[$size(nor_rgb)-1][07:00];
    end
    
    // RGB output
    always_ff @(posedge clk) begin
        if (connection[len-1] > 95) begin
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
        end else if (connection[len-2] > 95) begin
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
            if (we_out && (connection[len-1] > 95 || connection[len-2] > 95)) begin
                sum_y_axis <= sum_y_axis + addr_out/160;
                sum_x_axis <= sum_x_axis + addr_out%160;
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
    always_ff @(posedge clk or negedge reset_n) begin : get_axis_frame
        if (!reset_n) begin
            yFrame_prev <= '{default: 0};
            xFrame_prev <= '{default: 0};
        end else if (!vsync_hold && vsync) begin // check new frame
            // first value of array is current input
            yFrame_prev[0] <= aver_y_axis;
            xFrame_prev[0] <= aver_x_axis;
            // the delay state
            for (int i = 1; i < $size(yFrame_prev); i++) begin
                yFrame_prev[i] <= yFrame_prev[i-1];
            end
            //
            for (int i = 1; i < $size(xFrame_prev); i++) begin
                xFrame_prev[i] <= xFrame_prev[i-1];
            end
        end
    end : get_axis_frame

    always_ff @( posedge clk or negedge reset_n) begin : check_yAxis   
        if (!reset_n) begin
            up <= 1'b0;
        end else if (yFrame_prev[0] && yFrame_prev[$size(yFrame_prev)-1] && // both it is zero when start system
                     !vsync_hold && vsync && // check at first line of third-frame
                    (yFrame_prev[0] + 13 < yFrame_prev[$size(yFrame_prev)-1])) begin // check increate y-axis value
            up <= 1'b1;
        end else begin
            up <= 1'b0;  
        end
    end : check_yAxis

    always_ff @( posedge clk or negedge reset_n) begin : check_xAxis   
        if (!reset_n) begin
            back <= 1'b0;
        end else if (yFrame_prev[0] && yFrame_prev[$size(xFrame_prev)-1] && // both it is zero when start system
                     !vsync_hold && vsync && // check at first line of third-frame
                    (xFrame_prev[0] > xFrame_prev[$size(xFrame_prev)-1] + 15)) begin // check increate y-axis value
            back <= 1'b1;
        end else begin
            back <= 1'b0;  
        end
    end : check_xAxis

    /* ------------------------------------------------- */
    /* Maintain jumping signal during on 25 milliseconds */
    /* ------------------------------------------------- */
    always_ff @( posedge clk or negedge reset_n ) begin : gen_jumping
        if (!reset_n) begin
            debounce_jumping_delay <= 0;
            jumping <= 1'b0;
        end else begin
            if (!debounce_jumping_delay) begin
                if (up) begin
                    debounce_jumping_delay <= 1249999;
                    jumping <= 1'b1;
                end else begin           
                    jumping <= 1'b0;
                end
            end else begin
                debounce_jumping_delay <=  debounce_jumping_delay - 1;
            end
        end
    end : gen_jumping

    /* ------------------------------------------------ */
    /* Maintain backup signal during on 25 milliseconds */
    /* ------------------------------------------------ */
    always_ff @( posedge clk or negedge reset_n ) begin : gen_backup
        if (!reset_n) begin
            debounce_backup_delay <= 0;
            backup <= 1'b0;
        end else begin
            if (!debounce_backup_delay) begin
                if (back) begin
                    debounce_backup_delay <= 1249999;
                    backup <= 1'b1;
                end else begin           
                    backup <= 1'b0;
                end
            end else begin
                debounce_backup_delay <=  debounce_backup_delay - 1;
            end
        end
    end : gen_backup

    assign clk_o = clk;
    assign led = backup ? 2'b10 : jumping ? 2'b01 : 2'b00;
    assign y_position = yFrame_prev[0];
    assign x_position = xFrame_prev[0] + 3; // add a bias of Horizontal
    
endmodule