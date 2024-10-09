import sigmoid_package::*;

module sigmoid_IP (
    input logic clock,
    input logic [16:0] address,
    output logic [7:0] q
);
    // Register the address on the rising edge of the clock
    always_ff @(posedge clock) begin 
        q <= sigmoid_lut[address];
    end

endmodule