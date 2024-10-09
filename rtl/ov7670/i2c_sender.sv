// This module sends commands to the OV7670 camera over an I2C-like interface
module i2c_sender (
    input logic clk,             // System clock
    input logic rst,             // Reset signal
    inout wire siod,             // I2C data line
    output logic sioc,           // I2C clock line
    output logic taken,          // Command sent flag
    input logic send,            // Start sending command
    input logic [7:0] id,        // Camera ID
    input logic [7:0] regis,     // Camera register address
    input logic [7:0] value      // Value to write to the register
);
    // Internal signals
    logic [07:0] divider;       // Divider for clock timing
    logic [30:0] busy_sr;       // Busy shift register
    logic [30:0] data_sr;       // Data shift register of I2C frame
    logic siod_temp;

    assign siod = siod_temp;

    // SIOD line control: Outputs data or reads input for acknowledgment
    always_comb begin
        if ((busy_sr[10:09] == 2'b10) ||     // complete Sending ID field
            (busy_sr[19:18] == 2'b10) ||     // complete Sending REGIS field
            (busy_sr[28:27] == 2'b10)) begin // complete Sending VALUE field
            siod_temp = 1'bz;      // Disable driving siod (high-Z)
        end else begin
            siod_temp = data_sr[30];  // Output the MSB of data_sr
        end
    end

    // Sequential logic for handling data transmission
    always_ff @(posedge clk or negedge rst) begin
        if (!rst) begin
            // Reset values
            divider <= 8'd1;
            busy_sr <= '0;
            data_sr <= '1;
        end else begin
            taken <= 1'b0;      // Reset taken signal
            if (!busy_sr[30]) begin  // If not busy
                if (send) begin
                    if (!divider) begin
                        // Load the data shift register with the command
                        data_sr <= {2'b10, id, 1'b0, regis, 1'b0, value, 1'b0, 2'b01};
                        busy_sr <= {2'b11, 9'b111111111, 9'b111111111, 9'b111111111, 2'b11};
                        taken   <= 1'b1;  // Command accepted
                    end else begin
                        // Increment the divider (for power-up only)
                        divider <= divider + 8'd1;
                    end
                end
            end else begin
                // Handle the state machine for sending the data and control signals
                case ({busy_sr[30:28], busy_sr[2:0]})
                    {3'b111, 3'b111} : sioc <= 1'b1;              // Start sequence phase 1
                    {3'b111, 3'b110} : sioc <= ~(&divider[7:6]);  // Start sequence phase 2
                    {3'b110, 3'b000} : sioc <= |divider[7:6];     // End sequence phase 1
                    {3'b100, 3'b000} : sioc <= 1'b1;              // End sequence phase 2
                    {3'b000, 3'b000} : sioc <= 1'b1;              // Idle state
                    default: begin
                        // Handle clock toggling based on divider
                        sioc <= ^divider[7:6];
                    end
                endcase

                // Shift out data on every divider cycle completion
                if (divider == 8'hff) begin
                    busy_sr <= {busy_sr[29:0], 1'b0};  // Shift the busy status
                    data_sr <= {data_sr[29:0], 1'b1};  // Shift the data register
                    divider <= '0;                     // Reset the divider
                end else begin
                    divider <= divider + 8'd1;         // Increment the divider
                end
            end
        end
    end
endmodule
