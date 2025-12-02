// James Kaden Cassidy 9/12/2025

// This module takes in real world input and puts it through two flip flops to synchronzie the value to be much more likely a definate 1 or 0

module synchronizer #(parameter bits = 1) (
    input  logic clk,
    input  logic[bits-1:0] raw_input,
    output logic[bits-1:0] synchronized_value
);

    logic[bits-1:0] first_synchronize;

    // Synchronize Value
    always_ff @ (posedge clk) begin
        first_synchronize  <= raw_input;
        synchronized_value <= first_synchronize;
    end

endmodule