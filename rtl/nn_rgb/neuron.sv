`ifndef  _INCL_DEFINITIONS
  `define _INCL_DEFINITIONS
  import CONFIG::*;
`endif // _INCL_DEFINITIONS

module neuron #(
    parameter int h_weight_idx = 0, // high index of weight element for neuron in layer
    parameter int l_weight_idx = 0  // low index of weight element for neuron in layer
) (
    input logic clk,
    input logic [31:0] l_connection_idx,
    output logic [7:0] out
);
    // adress for the lookup table
    logic [16:0] sumAdress; 
    // result of the lookup table
    logic [7:0] afterActivation; 
    // sum after accumulation of the bias plus all inputs multiplied by their weights
    logic signed [31:0] sumForActivation; 
    // Array with the results from the multiplication of input with its weight
    logic signed [h_weight_idx-l_weight_idx-1:0][31:0] accumulate;

    // Generate a multiplier for each input to multiply it with its weight
    // Save the results in the array
    // This step is necessary because otherwise the mac operations would be to slow
    genvar i;
    generate // layer
      for (i = 0; i <= h_weight_idx-l_weight_idx-1; i++) begin : mult
        multiplier #(
          .weight(weights[i+l_weight_idx])
        ) mult_i (
          .clk(clk),
          .in(connection[i+l_connection_idx]),
          .out(accumulate[i])
        );
      end
    endgenerate

    // Accumulate the results from the multiplier and the bias
    logic signed [31:0] sum;

    always_comb begin : sum_linear
      sum = '0;
      // loop
      for (int i = 0; i <= h_weight_idx-l_weight_idx-1; i++) begin
        sum = sum + accumulate[i];
      end
    end : sum_linear

    always_ff @(posedge clk) begin : adding_bias
      sumForActivation <= sum + weights[h_weight_idx];
    end : adding_bias

    // limiting result for sigmoid
    always_ff @(posedge clk) begin
      if (sumForActivation < -65536) begin
        sumAdress <= '0;
      end else if (sumForActivation > 65535) begin
        sumAdress <= '1;
      end else begin
        sumAdress <= sumForActivation + 65536;
      end
    end

    // lookup table for the sigmoid function
    sigmoid_IP sigmoid (
      .clock   (clk),
      .address (sumAdress),
      .q       (afterActivation)
    );

    // set output of the neuron
    assign out = afterActivation;
    
endmodule