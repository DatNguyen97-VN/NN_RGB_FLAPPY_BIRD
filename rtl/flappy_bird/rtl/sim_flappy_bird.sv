`timescale  1ns/1ns

module sim_flappy_bird;
    logic vga_clk;
    logic sys_clk;
    logic reset;
    logic vsync;
    logic hsync;
    int   counter;
    logic [7:0] pixel;
    logic [3:0] sw;

    initial begin
        sys_clk = 0;
        #20;
        forever begin
            #10 sys_clk = ~sys_clk;
        end
    end

    initial begin
        vga_clk = 0;
        #20;
        forever begin
            #20 vga_clk = ~vga_clk;
        end
    end

    initial begin
        reset = 1;
        #50 
        reset = 0;
        #100
        reset = 1;
    end

    initial begin
        sw = 4'h0;
        #200 
        sw = 4'h4;
    end

    // ov7670 vertical stimulus
    initial begin
        while (1) begin
            repeat (2*002352) begin vsync = 1; @(negedge vga_clk); counter = counter + 1; end
            repeat (2*397488) begin vsync = 0; @(negedge vga_clk); counter = counter + 1; end
            #1 counter = 0;
        end
    end

    // ov7670 horizontal stimulus
    initial begin
        while (1) begin
            repeat (2*15680) begin hsync = 0; @(negedge vga_clk); end
            repeat (480) begin
                repeat (2*640) begin hsync = 1; pixel = $urandom_range(255); @(posedge vga_clk); end
                repeat (2*144) begin hsync = 0; @(negedge vga_clk); end
            end
            repeat (2*7840) begin hsync = 0; @(negedge vga_clk); end
        end
    end

    // DUT
    flappy_bird_logic dut (
        .sys_clk (sys_clk),
        .sys_rst_n (reset),
        .data_in (sw),
        .sel_in (2'b00),
        .led_out (),
        .vga_hsync (),
        .vga_vsync (),
        .Nblank (),
        .Nsync (),
        .vga_clk (),
        .vga_red (),
        .vga_green (),
        .vga_blue (),
        .slide_sw_resend_reg_values (),
        .ov7670_pclk (vga_clk), 
        .ov7670_xclk (), 
        .ov7670_vsync (vsync),
        .ov7670_href (hsync), 
        .ov7670_data (pixel),
        .ov7670_sioc (), 
        .ov7670_siod (), 
        .ov7670_pwdn (), 
        .ov7670_reset ()
    );

endmodule