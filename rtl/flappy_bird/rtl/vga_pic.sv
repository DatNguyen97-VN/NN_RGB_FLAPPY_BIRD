
`ifdef QUESTA
  `include "includes/bird.svh"
  `include "includes/bird_up.svh"
  `include "includes/bird_down.svh"
  `include "includes/gnd_pic.svh"
  `include "includes/tail.svh"
  `include "includes/head.svh"
  `include "includes/over.svh"
`endif // QUSESTA

module  vga_pic
(
    input   wire            vga_clk     ,   // Input working clock, frequency 25MHz
    input   wire            sys_rst_n   ,   // Input reset signal, low level is effective
    input   wire    [09:0]  pix_x       ,   // Input the X-axis coordinate of the pixel point in the VGA effective display area
    input   wire    [09:0]  pix_y       ,   // Input the Y-axis coordinate of the pixel point in the VGA effective display area
    input   wire    [03:0]  data_in     ,
    
    output  wire    [15:0]  pix_data    ,   // Output pixel color information
    output  reg     [19:0]  score           // Output total score
);

//********************************************************************//
//****************** Parameter and Internal Signal *******************//
//********************************************************************//
//parameter define
reg           flag_tail1  ;    //Is the pixel in the upper trash can
reg           flag_tail2  ;    //Is the pixel in the lower trash can
reg           flag_head1  ;    //Is the pixel in the upper trash can head
reg           flag_head2  ;    //Is the pixel in the lower trash can head
reg           flag_bird   ;    //Is the pixel in the bird
reg           flag_back   ;    //Is the pixel in the background
reg           flag_over   ;    //Is the pixel in the end pixel
reg  [2:0]    num1        ;    //Length of the upper trash can 
reg  [2:0]    num2        ;    //Length of the upper trash can
reg  [3:0]    state       ;    //State of the bird up or down
reg           finish      ;    //State of the game ending
                          
reg  [8:0]    ps_locx     ;    //bird coordinate x
reg  [8:0]    ps_locy     ;    //bird coordinate y
reg  [9:0]    bin_locx1   ;    //1st trash bin coordinate x1
reg  [9:0]    bin_locx2   ;    //2nd trash bin coordinate x2
reg  [8:0]    gnd_locx    ;    //background relative coordinate x
reg  [8:0]    gnd_locy    ;    //background relative coordinate y
                          
reg  [9:0]    addra       ;    //bird address
reg  [9:0]    addra_up    ;    //bird_up, bird uplink address
reg  [9:0]    addra_down  ;    //bird_down, bird downlink address
reg  [12:0]   addrb       ;    //background, background image address
reg  [9:0]    addrc       ;    //tail, trash can address
reg  [8:0]    addrd       ;    //head, trash can head address
reg  [13:0]   addre       ;    //gameover, game end address

wire [15:00]  color_filter1;    //bird down's a color background is filter as a color back
wire [15:00]  color_filter2;    //bird up's a color background is filter as a color back
                          
reg [15:0]   douta       ;
reg [15:0]   douta_up    ;
reg [15:0]   douta_down  ;
reg [15:0]   doutb       ;
reg [15:0]   doutc       ;
reg [15:0]   doutd       ;
reg [15:0]   doute       ;

parameter   H_VALID =   12'd640 ,   // Row valid data
            V_VALID =   12'd480 ;   // Field valid data

parameter   bird_wid       =   8'd32,   //Width of the bird
            bird_height    =   8'd32,   //Height of the bird
            tail_wid       =   8'd32,   //Width of the trash can
            tail_height    =   8'd32,   //Height of the trash can
            head_wid       =   8'd32,   //Width of the head of the trash can
            head_height    =   8'd16,   //Height of the head of the trash can
            speed          =   8'd1 ,   //Falling speed of the bird
            blank          =   3'd6;    //Crossing the gap
            

//********************************************************************//
//***************************** Main Code ****************************//
//********************************************************************//

// Game end judgment
always@(posedge vga_clk or negedge sys_rst_n)
    if(sys_rst_n == 1'b0)
        finish <= 0 ;
    else begin
        if(finish == 1'b1)
            finish <= 1'b1; //Once 1 appears, save it
        else
            if(ps_locy > 420)
                finish <= 1; // The bird fell to the ground, GG
            else
                // The bird collided with the trash can, GG
                finish <= (flag_bird && flag_tail1) || (flag_bird && flag_head1) || (flag_bird && flag_tail2) || (flag_bird && flag_head2) ;
    end

// Background drawing
always@(posedge vga_clk or negedge sys_rst_n)
    if(sys_rst_n == 1'b0)begin
            gnd_locx  <= 0;  
            gnd_locy  <= 0;
            addrb <= 0;
        end
    else begin
        // Obtain the relative coordinates of the background. This code is one row * 10 columns
        gnd_locx <= pix_x % 64;
        gnd_locy <= pix_y % 352;
        addrb <= gnd_locy * 64 + gnd_locx;
    end


// Bird position
always@(posedge vga_clk or negedge sys_rst_n)
    if(sys_rst_n == 1'b0)begin
        // Bird's position and up and down status
        ps_locx  <= 303;  
        ps_locy  <= 223;
        state    <= 0  ;
    end
    else begin
        if(finish == 1'b1) begin
            ps_locy <= ps_locy;
            ps_locx <= ps_locx;
        end
        else if(pix_x == 12'h0 && pix_y == 12'h0 && data_in[2]) begin
            // state：0-7 The bird falls down at position y with uniform acceleration. If key1 is detected, it jumps to 8 to rise.
            // state：8-15 The bird's position y rises at a uniform deceleration.
            case(state)
                0 : begin state <= (data_in[0])? 8:1; ps_locy  <= ps_locy + speed * 2; end
                1 : begin state <= (data_in[0])? 8:2; ps_locy  <= ps_locy + speed * 2; end
                2 : begin state <= (data_in[0])? 8:3; ps_locy  <= ps_locy + speed * 2; end
                3 : begin state <= (data_in[0])? 8:4; ps_locy  <= ps_locy + speed * 2; end
                4 : begin state <= (data_in[0])? 8:5; ps_locy  <= ps_locy + speed * 2; end
                5 : begin state <= (data_in[0])? 8:6; ps_locy  <= ps_locy + speed * 2; end
                6 : begin state <= (data_in[0])? 8:7; ps_locy  <= ps_locy + speed * 2; end
                7 : begin state <= (data_in[0])? 8:7; ps_locy  <= ps_locy + speed * 2; end
                8 : begin state <= 9 ; ps_locy  <= ps_locy - 20; end
                9 : begin state <= 10; ps_locy  <= ps_locy - 16; end
                10: begin state <= 11; ps_locy  <= ps_locy - 12; end
                11: begin state <= 12; ps_locy  <= ps_locy - 8 ; end
                12: begin state <= 13; ps_locy  <= ps_locy - 6 ; end
                13: begin state <= 14; ps_locy  <= ps_locy - 4 ; end
                14: begin state <= 15; ps_locy  <= ps_locy - 2 ; end
                15: begin state <= 0 ; ps_locy  <= ps_locy - 1 ; end
            endcase
            ps_locx <= (data_in[1])? ps_locx - 5 * speed : ((data_in[3]) ? ps_locx + 5 * speed : ps_locx);
        end
    end

// Trash bin location
always@(posedge vga_clk or negedge sys_rst_n)
    if(sys_rst_n == 1'b0)begin
            bin_locx1  <= 576;  
            bin_locx2  <= 256;
            num1       <= 3  ;// Length of trash can 1
            num2       <= 5  ;// Length of trash can 2
            score      <= 0  ;// Current score
        end
    else begin
        if(finish ==1'b1) begin
            bin_locx1 <= bin_locx1;
            bin_locx2 <= bin_locx2;
        end else if(pix_x == 12'h0 && pix_y == 12'h0 && data_in[2]) 
        begin
            if(bin_locx1 > 2) begin
                bin_locx1  <= bin_locx1 - 2; // Gradually move left
                end
            else begin
                bin_locx1  <= 640-tail_wid; // Move to the far right
                num1 <= (num1 > 6)? 2 : num1 + 1 ; // The length gradually increases
                score <= (score>100)? 0 : score + 1; // Add one to the score
            end
            //
            if(bin_locx2 > 2) begin
                bin_locx2  <= bin_locx2 - 2;
                end
            else begin
                bin_locx2  <= 640-tail_wid;
                num2 <= (num2 > 6)? 2 : num2 + 1 ;
                score <= (score>100)? 0 : score + 1;
            end
        end
    end

// Image display
always@(posedge vga_clk or negedge sys_rst_n)
    if (sys_rst_n == 1'b0) begin     
            addra       <= 0;
            addra_up    <= 0;
            addra_down  <= 0;
            addrc       <= 0;
            addrd       <= 0;
            addre       <= 0;
            flag_tail1  <= 0;
            flag_tail2  <= 0;
            flag_head1  <= 0;
            flag_head2  <= 0;
            flag_bird   <= 0;
            flag_back   <= 0;
            flag_over   <= 0;
        end
    else begin
        // Trash bin 1 is divided into tail and head
        if((pix_x >= bin_locx1 && pix_x <= bin_locx1 + tail_wid - 1 && pix_y >= 0 && pix_y <= tail_height * num1 - 1) ||
           (pix_x >= bin_locx1 && pix_x <= bin_locx1 + tail_wid - 1 && pix_y >= tail_height * (num1+blank) && pix_y <= 480 - 1)) begin
            addrc    <= addrc + 1;
            flag_tail1 <= 1'b1;
        end else flag_tail1 <= 1'b0;
        
        if((pix_x >= bin_locx1 && pix_x <= bin_locx1 + tail_wid - 1 && pix_y >= tail_height * num1 && pix_y <= tail_height * num1 + head_height-1)||
           (pix_x >= bin_locx1 && pix_x <= bin_locx1 + tail_wid - 1 && pix_y >= tail_height * (num1+blank)-16 && pix_y <= tail_height * (num1+blank)-1)) begin
            addrd    <= addrd + 1;
            flag_head1 <= 1'b1;
        end else flag_head1 <= 1'b0;
        
        // Trash can 2 judgment
        if((pix_x >= bin_locx2 && pix_x <= bin_locx2 + tail_wid - 1 && pix_y >= 0 && pix_y <= tail_height * num2 - 1) ||
           (pix_x >= bin_locx2 && pix_x <= bin_locx2 + tail_wid - 1 && pix_y >= tail_height * (num2+blank) && pix_y <= 480 - 1)) begin
            addrc    <= addrc + 1;
            flag_tail2 <= 1'b1;
        end else flag_tail2 <= 1'b0;
        
        if((pix_x >= bin_locx2 && pix_x <= bin_locx2 + tail_wid - 1 && pix_y >= tail_height * num2 && pix_y <= tail_height * num2 + head_height-1)||
           (pix_x >= bin_locx2 && pix_x <= bin_locx2 + tail_wid - 1 && pix_y >= tail_height * (num2+blank)-16 && pix_y <= tail_height * (num2+blank)-1)) begin
            addrd    <= addrd + 1;
            flag_head2 <= 1'b1;
        end else flag_head2 <= 1'b0;
        
        // bird judgment
        if(pix_x >= ps_locx && pix_x <= ps_locx + bird_wid - 1 && pix_y >= ps_locy && pix_y <= ps_locy + bird_height - 1) begin
            addra     <= addra + 1;
            addra_up  <= addra_up + 1;
            addra_down<= addra_down + 1;
            flag_bird <= 1'b1;
        end else flag_bird <= 1'b0;
        
        // over judgment
        if(pix_x >= 191 && pix_x <= 446 && pix_y >= 207 && pix_y <= 270) begin
            addre     <= addre + 1;
            flag_over <= 1'b1;
        end else flag_over <= 1'b0;
        
        // Background judgment
        if(pix_y >= 352 && pix_y < 480) begin
            flag_back <= 1'b1;
        end else flag_back <= 1'b0;
    end
    
assign pix_data = (finish == 1'b1 )?
                  ((flag_over  == 1'b1)? doute :                                //gameover
                  (flag_tail1  == 1'b1)? doutc :                                //tail1
                  (flag_head1  == 1'b1)? doutd :                                //head1
                  (flag_tail2  == 1'b1)? doutc :                                //tail2
                  (flag_head2  == 1'b1)? doutd :                                //head2
                  (flag_bird   == 1'b1)? ((state <=7)? color_filter1 : color_filter2):  //bird
                  (flag_back   == 1'b1)? doutb :                                //background
                  16'h4e19 ) :                                                  //blue_background
                  ((flag_tail1 == 1'b1)? doutc :                                //tail1
                  (flag_head1  == 1'b1)? doutd :                                //head1
                  (flag_tail2  == 1'b1)? doutc :                                //tail2
                  (flag_head2  == 1'b1)? doutd :                                //head2
                  (flag_bird   == 1'b1)? ((state <=7)? color_filter1 : color_filter2):  //bird
                  (flag_back   == 1'b1)? doutb :                                //background
                  16'h4e19 );                                                   //blue_background

assign color_filter1 = (pix_y >= 352 && pix_y < 480 && douta_down == 16'h0000) ? doutb : douta_down;
assign color_filter2 = (pix_y >= 352 && pix_y < 480 && douta_up   == 16'h0000) ? doutb : douta_up;

/* Database */
`ifndef QUESTA
   // bird up
   bird_up bird_up_pix (.address(addra_up), .clock(vga_clk), .q(douta_up));
   
   // bird down
   bird_down bird_down_pix (.address(addra_down), .clock(vga_clk), .q(douta_down));
   
   // gnd pic
   gnd_pic gnd_pic_pix (.address(addrb), .clock(vga_clk), .q(doutb));
   
   // tail
   tail tail_pix (.address(addrc), .clock(vga_clk), .q(doutc));
   
   // head
   head head_pix (.address(addrd), .clock(vga_clk), .q(doutd));
   
   // over
   over over_pix (.address(addre), .clock(vga_clk), .q(doute));
`else
   // bird up
   always_ff @(posedge vga_clk or negedge sys_rst_n) begin
    if (!sys_rst_n) begin
        douta_up <= '0;
    end else begin
        douta_up <= bird_up[addra_up];
    end
   end

   // bird down
   always_ff @(posedge vga_clk or negedge sys_rst_n) begin
    if (!sys_rst_n) begin
        douta_down <= '0;
    end else begin
        douta_down <= bird_down[addra_down];
    end
   end

   // gnd pic
   always_ff @(posedge vga_clk or negedge sys_rst_n) begin
    if (!sys_rst_n) begin
        doutb <= '0;
    end else begin
        doutb <= gnd_pic[addrb];
    end
   end

   // tail
   always_ff @(posedge vga_clk or negedge sys_rst_n) begin
    if (!sys_rst_n) begin
        doutc <= '0;
    end else begin
        doutc <= tail[addrc];
    end
   end

   // head
   always_ff @(posedge vga_clk or negedge sys_rst_n) begin
    if (!sys_rst_n) begin
        doutd <= '0;
    end else begin
        doutd <= head[addrd];
    end
   end

   // over
   always_ff @(posedge vga_clk or negedge sys_rst_n) begin
    if (!sys_rst_n) begin
        doute <= '0;
    end else begin
        doute <= over[addre];
    end
   end
`endif

endmodule
