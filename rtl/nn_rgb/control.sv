module control #(
    parameter int delay = 7
) (
    input  logic        clk,
    input  logic        vsync_i,
    input  logic [16:0] addr_i,
    input  logic        we_i,
    output logic        vsync_o,
    output logic [16:0] addr_o,
    output logic        we_o
);
    logic [16:0] addr_delay_array  [delay];
    logic        we_delay_array    [delay];
    logic        vsync_delay_array [delay];


    always_ff @(posedge clk) begin
        // first value of array is current input
        addr_delay_array[0]  <= addr_i;
        we_delay_array[0]    <= we_i;
        vsync_delay_array[0] <= vsync_i;

        // delay according to generic delay
        for (int i = 1; i < delay; i++) begin
            addr_delay_array[i]  <= addr_delay_array[i-1];
            we_delay_array[i]    <= we_delay_array[i-1];
            vsync_delay_array[i] <= vsync_delay_array[i-1];
        end
    end

    // last value of array is output
    assign addr_o = addr_delay_array[delay-1];
    assign we_o = we_delay_array[delay-1];
    assign vsync_o = vsync_delay_array[delay-1];
    
endmodule