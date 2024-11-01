module debounce (
    input  logic clk,                 // Clock input
    input  logic reset_n,             // Active-low reset
    input  logic [5:0] noisy_signal,        // Input signal to debounce
    output logic [5:0] stable_signal        // Debounced output signal
);

    parameter int debounce_delay = 1249999;  // 25ms 1249999

    // Internal signals
    logic [31:0] counter;          // Counter for debounce delay
    logic [05:0]signal_reg;              // Registered input signal

    always_ff @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            // Reset state
            stable_signal <= 0;
            signal_reg <= 0;
            counter <= 0;
        end else begin
            // Check if input is stable
            if (noisy_signal == signal_reg) begin
                if (counter < debounce_delay) begin
                    counter <= counter + 1;
                end else begin
                    stable_signal <= signal_reg;
                end
            end else begin
                // Reset counter and update signal register
                signal_reg <= noisy_signal;
                counter <= 0;
            end
        end
    end

endmodule
