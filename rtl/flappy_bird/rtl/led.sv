`timescale  1ns/1ns

module  led
(
    input            clk  ,
    input            rst_n,
    input   [3:0]    data_in  ,   //输入按键

    output  reg [3:0]    led_out     //输出控制led灿
);

//********************************************************************//
//***************************** Main Code ****************************//
//********************************************************************//
reg [19:0] cnt;

always@(posedge clk or negedge rst_n) begin
	if(rst_n == 1'b0) begin
        led_out <= 0; 
        cnt     <= 0;
	end else
    if(data_in == 4'b0001) begin
		led_out <= 4'b0001;
        cnt <= 1;
	end else if(data_in == 4'b0010) begin
		led_out <= 4'b0010;
        cnt <= 1;
	end else if(data_in == 4'b0100) begin
		led_out <= 4'b0100;
        cnt <= 1;
	end else if(data_in == 4'b1000) begin
		led_out <= 4'b1000;
        cnt <= 1;
	end else begin
        cnt <= (cnt == 0)? cnt : cnt + 1;
        led_out <= (cnt==0)? 4'b0000:led_out;
    end
    
end

endmodule
