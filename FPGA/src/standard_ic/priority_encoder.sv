// priority_encoder.sv
// James Kaden Cassidy
// kacassidy@hmc.edu
// 12/1/2025

module priority_encoder #(
    parameter int WIDTH         = 8,   // number of input bits
    parameter bit MSB_PRIORITY  = 1    // 1 = MSB has highest priority, 0 = LSB
)(
    input  logic [WIDTH-1:0]                 in,
    output logic [$clog2(WIDTH)-1:0]         idx,    // index of selected bit
    output logic                             valid   // 1 if any bit is set
);

    // Combinational priority encoder
    always_comb begin
        valid = (in != '0);
        idx   = '0;

        if (MSB_PRIORITY) begin
            // Highest set bit wins (MSB priority)
            for (int i = WIDTH-1; i >= 0; i--) begin
                if (in[i]) idx = i[$clog2(WIDTH)-1:0];
            end
        end else begin
            // Lowest set bit wins (LSB priority)
            for (int i = 0; i < WIDTH; i++) begin
                if (in[i]) idx = i[$clog2(WIDTH)-1:0];
            end
        end
    end

endmodule
