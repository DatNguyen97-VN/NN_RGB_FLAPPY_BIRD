
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
    input   logic            vga_clk     ,   // Input working clock, frequency 25MHz
    input   logic            sys_rst_n   ,   // Input reset signal, low level is effective
    input   logic    [09:0]  pix_x       ,   // Input the X-axis coordinate of the pixel point in the VGA effective display area
    input   logic    [09:0]  pix_y       ,   // Input the Y-axis coordinate of the pixel point in the VGA effective display area
    input   logic    [03:0]  data_in     ,
    input   logic    [01:0]  sel_in      ,
    
    output  logic    [15:0]  pix_data        // Output pixel color information
);

//********************************************************************//
//****************** Parameter and Internal Signal *******************//
//********************************************************************//
//parameter define
logic           flag_tail1  ;    //Is the pixel in the upper trash can
logic           flag_tail2  ;    //Is the pixel in the lower trash can
logic           flag_head1  ;    //Is the pixel in the upper trash can head
logic           flag_head2  ;    //Is the pixel in the lower trash can head
logic           flag_bird   ;    //Is the pixel in the bird
logic           flag_back   ;    //Is the pixel in the background
logic           flag_over   ;    //Is the pixel in the end pixel
logic           flag_digit1 ;    //start digit1 pixel
logic           flag_digit2 ;    //start digit2 pixel
logic  [2:0]    num1        ;    //Length of the upper trash can 
logic  [2:0]    num2        ;    //Length of the upper trash can
logic  [3:0]    state       ;    //State of the bird up or down
logic           finish      ;    //State of the game ending
logic  [3:0]    counter     ;    //wing flag
                          
logic  [8:0]    ps_locx     ;    //bird coordinate x
logic  [8:0]    ps_locy     ;    //bird coordinate y
logic  [9:0]    bin_locx1   ;    //1st trash bin coordinate x1
logic  [9:0]    bin_locx2   ;    //2nd trash bin coordinate x2
logic  [8:0]    gnd_locx    ;    //background relative coordinate x
logic  [8:0]    gnd_locy    ;    //background relative coordinate y
                          
logic  [9:0]    addra       ;    //bird address
logic  [9:0]    addra_up    ;    //bird_up, bird uplink address
logic  [9:0]    addra_down  ;    //bird_down, bird downlink address
logic  [12:0]   addrb       ;    //background, background image address
logic  [9:0]    addr_tail   ;    //tail, trash can address
logic  [9:0]    addr_head   ;    //head, trash can head address
logic  [9:0]    addr_head1  ;
logic  [9:0]    addr_head2  ;
logic  [9:0]    addr_tail1  ;
logic  [9:0]    addr_tail2  ;
logic  [13:0]   addre       ;    //gameover, game end address
logic  [09:0]   addr        ;    //digit
logic  [09:0]   addr1       ;    //digit1
logic  [09:0]   addr2       ;    //digit2

logic [15:00]  color_filter1;    //bird down's a color background is filter as a color back
logic [15:00]  color_filter2;    //bird up's a color background is filter as a color back
logic [15:00]  color_filter3;    //game over color is filter as a blue color
                          
logic [15:0]   douta_up    ;
logic [15:0]   douta_down  ;
logic [15:0]   reddouta_up    ;
logic [15:0]   reddouta_down  ;
logic [15:0]   bluedouta_up    ;
logic [15:0]   bluedouta_down  ;
logic [15:0]   yellowdouta_up    ;
logic [15:0]   yellowdouta_down  ;
logic [15:0]   doutb       ;
logic [15:0]   doutc       ;
logic [15:0]   doutd       ;
logic [15:0]   doute       ;
logic [15:0]   dout        ;
logic  [15:0]   dout1       ;
logic  [15:0]   dout2       ;
logic [15:0]   dout_0       ;
logic [15:0]   dout_1       ;
logic [15:0]   dout_2       ;
logic [15:0]   dout_3       ;
logic [15:0]   dout_4       ;
logic [15:0]   dout_5       ;
logic [15:0]   dout_6       ;
logic [15:0]   dout_7       ;
logic [15:0]   dout_8       ;
logic [15:0]   dout_9       ;

logic [03:0]   temp1        ;
logic [03:0]   temp2        ;
logic [06:0]   score        ;

parameter   H_VALID =   12'd640 ,   // Row valid data
            V_VALID =   12'd480 ;   // Field valid data

parameter   bird_wid    = 8'd32,   //Width of the bird
            bird_height = 8'd32,   //Height of the bird
            tail_wid    = 8'd32,   //Width of the trash can
            tail_height = 8'd32,   //Height of the trash can
            head_wid    = 8'd32,   //Width of the head of the trash can
            head_height = 8'd16,   //Height of the head of the trash can
            speed       = 8'd1 ,   //Falling speed of the bird
            blank       = 3'd6,    //Crossing the gap
            zero_wid    = 8'd32,    //Width of the number zero
            zero_height = 8'd32;    //Height of the number zero
            

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
            if(ps_locy > 420 || ps_locx > 640)
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
        counter  <= 0;
    end
    else begin
        if(finish == 1'b1) begin
            ps_locy <= ps_locy;
            ps_locx <= ps_locx;
        end else if (pix_x == 12'h0 && pix_y == 12'h0) begin
            if (data_in[2]) begin
                // state：0-7 The bird falls down at position y with uniform acceleration. If key1 is detected, it jumps to 8 to rise.
                // state：8-15 The bird's position y rises at a uniform deceleration.
                case(state)
                    0 : begin state <= (!data_in[0])? 8:1; ps_locy  <= ps_locy + speed * 2; end
                    1 : begin state <= (!data_in[0])? 8:2; ps_locy  <= ps_locy + speed * 2; end
                    2 : begin state <= (!data_in[0])? 8:3; ps_locy  <= ps_locy + speed * 2; end
                    3 : begin state <= (!data_in[0])? 8:4; ps_locy  <= ps_locy + speed * 2; end
                    4 : begin state <= (!data_in[0])? 8:5; ps_locy  <= ps_locy + speed * 2; end
                    5 : begin state <= (!data_in[0])? 8:6; ps_locy  <= ps_locy + speed * 2; end
                    6 : begin state <= (!data_in[0])? 8:7; ps_locy  <= ps_locy + speed * 2; end
                    7 : begin state <= (!data_in[0])? 8:7; ps_locy  <= ps_locy + speed * 2; end
                    8 : begin state <= 9 ; ps_locy  <= ps_locy - 20; end
                    9 : begin state <= 10; ps_locy  <= ps_locy - 16; end
                    10: begin state <= 11; ps_locy  <= ps_locy - 12; end
                    11: begin state <= 12; ps_locy  <= ps_locy - 8 ; end
                    12: begin state <= 13; ps_locy  <= ps_locy - 6 ; end
                    13: begin state <= 14; ps_locy  <= ps_locy - 4 ; end
                    14: begin state <= 15; ps_locy  <= ps_locy - 2 ; end
                    15: begin state <= 0 ; ps_locy  <= ps_locy - 1 ; end
                endcase
                ps_locx <= (!data_in[1])? ps_locx - 5 * speed : ((!data_in[3]) ? ps_locx + 5 * speed : ps_locx);
            end
            // increate counter for wing flag
            counter <= counter + 1'b1;
        end
    end

// Trash bin location
always@(posedge vga_clk or negedge sys_rst_n)
    if(sys_rst_n == 1'b0)begin
            bin_locx1  <= 576;  //576
            bin_locx2  <= 305;  //256
            num1       <= 3  ;// Length of trash can 1
            num2       <= 5  ;// Length of trash can 2
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
            end
            //
            if(bin_locx2 > 2) begin
                bin_locx2  <= bin_locx2 - 2;
                end
            else begin
                bin_locx2  <= 640-tail_wid;
                num2 <= (num2 > 6)? 2 : num2 + 1 ;
            end
        end
    end

// Compute current score
always @(posedge vga_clk or negedge sys_rst_n) begin
    if (!sys_rst_n) begin
        score <= 0;
    end else begin
        // increate score
        if (pix_x == 12'h0 && pix_y == 12'h0 && 
          ((ps_locx == bin_locx2) || (ps_locx == bin_locx1) || // bird positions is even number
           (ps_locx+1 == bin_locx2) || (ps_locx+1 == bin_locx1))) begin // bird positions is old number
            score <= score + 1'b1;
        end
    end
end

//Draw 2-digit
always_comb begin
    // digit selection
    addr <= flag_digit2 ? addr2 :
            flag_digit1 ? addr1 : 16'h0;
    // draw digit-1 and digit-2
    temp2 <= score / 10;
    temp1 <= score % 10;
    //
    case (temp2)
        4'h0 : dout2 <= dout_0;
        4'h1 : dout2 <= dout_1;
        4'h2 : dout2 <= dout_2;
        4'h3 : dout2 <= dout_3;
        4'h4 : dout2 <= dout_4;
        4'h5 : dout2 <= dout_5;
        4'h6 : dout2 <= dout_6;
        4'h7 : dout2 <= dout_7;
        4'h8 : dout2 <= dout_8;
        4'h9 : dout2 <= dout_9;
        default: begin
               dout2 <= dout_0;
        end
    endcase
    //
    case (temp1)
        4'h0 : dout1 <= dout_0;
        4'h1 : dout1 <= dout_1;
        4'h2 : dout1 <= dout_2;
        4'h3 : dout1 <= dout_3;
        4'h4 : dout1 <= dout_4;
        4'h5 : dout1 <= dout_5;
        4'h6 : dout1 <= dout_6;
        4'h7 : dout1 <= dout_7;
        4'h8 : dout1 <= dout_8;
        4'h9 : dout1 <= dout_9;
        default: begin
               dout1 <= 16'h0;
        end
    endcase
end

// Image display
always@(posedge vga_clk or negedge sys_rst_n)
    if (sys_rst_n == 1'b0) begin     
            addra       <= 0;
            addra_up    <= 0;
            addra_down  <= 0;
            addr_tail1  <= 0;
            addr_tail2  <= 0;
            addr_head1  <= 0;
            addr_head2  <= 0;
            addre       <= 0;
            addr1       <= 0;
            addr2       <= 0;
            flag_tail1  <= 0;
            flag_tail2  <= 0;
            flag_head1  <= 0;
            flag_head2  <= 0;
            flag_bird   <= 0;
            flag_back   <= 0;
            flag_over   <= 0;
            flag_digit1 <= 0;
            flag_digit2 <= 0;
        end
    else begin
        // Trash bin 1 is divided into tail and head
        if((pix_x >= bin_locx1 && pix_x <= bin_locx1 + tail_wid - 1 && pix_y >= 0 && pix_y <= tail_height * num1 - 1) ||
           (pix_x >= bin_locx1 && pix_x <= bin_locx1 + tail_wid - 1 && pix_y >= tail_height * (num1+blank) && pix_y <= 480 - 1)) begin
            addr_tail1  <= addr_tail1 + 1;
            flag_tail1 <= 1'b1;
        end else flag_tail1 <= 1'b0;
        
        if((pix_x >= bin_locx1 && pix_x <= bin_locx1 + tail_wid - 1 && pix_y >= tail_height * num1 && pix_y <= tail_height * num1 + head_height-1)||
           (pix_x >= bin_locx1 && pix_x <= bin_locx1 + tail_wid - 1 && pix_y >= tail_height * (num1+blank)-16 && pix_y <= tail_height * (num1+blank)-1)) begin
            addr_head1 <= addr_head1 + 1;
            flag_head1 <= 1'b1;
        end else flag_head1 <= 1'b0;
        
        // Trash can 2 judgment
        if((pix_x >= bin_locx2 && pix_x <= bin_locx2 + tail_wid - 1 && pix_y >= 0 && pix_y <= tail_height * num2 - 1) ||
           (pix_x >= bin_locx2 && pix_x <= bin_locx2 + tail_wid - 1 && pix_y >= tail_height * (num2+blank) && pix_y <= 480 - 1)) begin
            addr_tail2 <= addr_tail2 + 1;
            flag_tail2 <= 1'b1;
        end else flag_tail2 <= 1'b0;
        
        if((pix_x >= bin_locx2 && pix_x <= bin_locx2 + tail_wid - 1 && pix_y >= tail_height * num2 && pix_y <= tail_height * num2 + head_height-1)||
           (pix_x >= bin_locx2 && pix_x <= bin_locx2 + tail_wid - 1 && pix_y >= tail_height * (num2+blank)-16 && pix_y <= tail_height * (num2+blank)-1)) begin
            addr_head2 <= addr_head2 + 1;
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

        // Digit 2 judment
        if(pix_x >= 300 && pix_x < 300 + zero_wid && pix_y >= 2 && pix_y < 2 + zero_height) begin
            addr2       <= addr2 + 1;
            flag_digit2 <= 1'b1;
        end else flag_digit2 <= 1'b0;

        // Digit 1 judment
        if(pix_x >= 305 + zero_wid && pix_x < 305 + 2*zero_wid && pix_y >= 2 && pix_y < 2 + zero_height) begin
            addr1       <= addr1 + 1;
            flag_digit1 <= 1'b1;
        end else flag_digit1 <= 1'b0;
    end
    
assign pix_data = (finish == 1'b1 )?
                  ((flag_over  == 1'b1)? color_filter3 :                        //gameover
                  (flag_digit2 == 1'b1)? dout2 :                                //digti2
                  (flag_digit1 == 1'b1)? dout1 :                                //digti1
                  (flag_tail1  == 1'b1)? doutc :                                //tail1
                  (flag_head1  == 1'b1)? doutd :                                //head1
                  (flag_tail2  == 1'b1)? doutc :                                //tail2
                  (flag_head2  == 1'b1)? doutd :                                //head2
                  (flag_bird   == 1'b1)? ((counter <= 7)? color_filter1 : color_filter2):  //bird
                  (flag_back   == 1'b1)? doutb :                                //background
                  16'h4e19 ) :                                                  //blue_background
                  ((flag_digit2 == 1'b1)? dout2 :                               //digti2
                  (flag_digit1 == 1'b1)? dout1 :                                //digti1
                  (flag_tail2  == 1'b1)? doutc :                                //tail2
                  (flag_head2  == 1'b1)? doutd :                                //head2
                  (flag_tail1  == 1'b1)? doutc :                                //tail1
                  (flag_head1  == 1'b1)? doutd :                                //head1
                  (flag_bird   == 1'b1)? ((counter <= 7)? color_filter1 : color_filter2):  //bird
                  (flag_back   == 1'b1)? doutb :                                //background
                  16'h4e19 );                                                   //blue_background

assign addr_head = flag_head2 ? addr_head2 :
                   flag_head1 ? addr_head1 : 0;

assign addr_tail = flag_tail2 ? addr_tail2 :
                   flag_tail1 ? addr_tail1 : 0;

assign color_filter1 = (douta_down != 16'h0000) ? douta_down :
                       (pix_y >= 352 && pix_y < 480) ? doutb : 16'h4e19;

assign color_filter2 = (douta_up != 16'h0000) ? douta_up :
                       (pix_y >= 352 && pix_y < 480) ? doutb : 16'h4e19;

assign color_filter3 = (doute == 16'h0000) ? 16'h4e19 : doute;

assign douta_down = (sel_in == 2'b01) ? bluedouta_down :
                    (sel_in == 2'b10) ? yellowdouta_down :
                    reddouta_down;

assign douta_up   = (sel_in == 2'b01) ? bluedouta_up :
                    (sel_in == 2'b10) ? yellowdouta_up :
                    reddouta_up;

/* Database */
`ifndef QUESTA
   // redbird up
   redbird_up redbird_up_pix (.address(addra_up), .clock(vga_clk), .q(reddouta_up));
   
   // bluebird down
   redbird_down redbird_down_pix (.address(addra_down), .clock(vga_clk), .q(reddouta_down));

   // bluebird up
   bluebird_up bluebird_up_pix (.address(addra_up), .clock(vga_clk), .q(bluedouta_up));
   
   // bluebird down
   bluebird_down bluebird_down_pix (.address(addra_down), .clock(vga_clk), .q(bluedouta_down));

   // yellowbird up
   yellowbird_up yellowbird_up_pix (.address(addra_up), .clock(vga_clk), .q(yellowdouta_up));
   
   // yellowbird down
   yellowbird_down yellowbird_down_pix (.address(addra_down), .clock(vga_clk), .q(yellowdouta_down));
   
   // gnd pic
   gnd_pic gnd_pic_pix (.address(addrb), .clock(vga_clk), .q(doutb));
   
   // tail
   tail tail_pix (.address(addr_tail), .clock(vga_clk), .q(doutc));
   
   // head
   head head_pix (.address(addr_head), .clock(vga_clk), .q(doutd));
   
   // over
   over over_pix (.address(addre), .clock(vga_clk), .q(doute));

   // zero
   zero zero_pix (.address(addr), .clock(vga_clk), .q(dout_0));

   // one
   one one_pix (.address(addr), .clock(vga_clk), .q(dout_1));

   // two
   two two_pix (.address(addr), .clock(vga_clk), .q(dout_2));

   // three
   three three_pix (.address(addr), .clock(vga_clk), .q(dout_3));

   // four
   four four_pix (.address(addr), .clock(vga_clk), .q(dout_4));

   // five
   five five_pix (.address(addr), .clock(vga_clk), .q(dout_5));

   // six
   six six_pix (.address(addr), .clock(vga_clk), .q(dout_6));

   // seven
   seven seven_pix (.address(addr), .clock(vga_clk), .q(dout_7));

   // eight
   eight eight_pix (.address(addr), .clock(vga_clk), .q(dout_8));

   // nine
   nine nine_pix (.address(addr), .clock(vga_clk), .q(dout_9));
`else
   // bird up
   always_ff @(posedge vga_clk or negedge sys_rst_n) begin
    if (!sys_rst_n) begin
        reddouta_up <= '0;
    end else begin
        reddouta_up <= redbird_up[addra_up];
    end
   end

   // bird down
   always_ff @(posedge vga_clk or negedge sys_rst_n) begin
    if (!sys_rst_n) begin
        reddouta_down <= '0;
    end else begin
        reddouta_down <= redbird_down[addra_down];
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
        doutc <= tail[addr_tail];
    end
   end

   // head
   always_ff @(posedge vga_clk or negedge sys_rst_n) begin
    if (!sys_rst_n) begin
        doutd <= '0;
    end else begin
        doutd <= head[addr_head];
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