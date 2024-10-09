// the multiplier takes an input and multiplies it with the given weight

module multiplier #(
    parameter int weight = 0
) (
    input logic clk,
    input logic [7:0] in,
    output logic signed [31:0] out
);  
    // multiplication is done inside a process
    // to give the fitter more possibilities
    always_ff @(posedge clk) begin
        out <= in * weight;
    end

endmodule