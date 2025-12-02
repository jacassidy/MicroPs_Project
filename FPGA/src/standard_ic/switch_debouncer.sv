// James Kaden Cassidy 9/12/2025

// This module is designed to take in switch input directly from a real world pin and then synchronize and stablize the value to an ideal button/switch

module switch_debouncer #(parameter debounce_delay) (
    input   logic   clk,
    input   logic   reset,
    input   logic   raw_input,
    output  logic   debounced_value
);

    logic debounced_input_low;

    // Debounce Value

    always_ff @ (posedge clk, reset) begin
        if      (raw_input)  debounced_value <= 1'b1;
        else if (debounced_input_low | reset) debounced_value <= 1'b0;
    end

    clk_counter #(debounce_delay) Clk_Counter(.clk, .reset(raw_input), .count_achieved(debounced_input_low));

endmodule