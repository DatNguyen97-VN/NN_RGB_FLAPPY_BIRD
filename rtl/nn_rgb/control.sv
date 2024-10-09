module control #(
    parameter int delay = 7
) (
    input logic clk,
    input logic reset,
    input logic vs_in,
    input logic hs_in,
    input logic de_in,
    output logic vs_out,
    output logic hs_out,
    output logic de_out
);
    typedef logic [delay-1:0] delay_array_t;
    delay_array_t vs_delay;
    delay_array_t hs_delay;
    delay_array_t de_delay;

    always_ff @(posedge clk) begin
        // first value of array is current input
        vs_delay[0] <= vs_in;
        hs_delay[0] <= hs_in;
        de_delay[0] <= de_in;

        // delay according to generic delay
        for (int i = 1; i < delay; i++) begin
            vs_delay[i] <= vs_delay[i-1];
            hs_delay[i] <= hs_delay[i-1];
            de_delay[i] <= de_delay[i-1];
        end
    end

    // last value of array is output
    assign vs_out = vs_delay[delay-1];
    assign hs_out = hs_delay[delay-1];
    assign de_out = de_delay[delay-1];
    
endmodule