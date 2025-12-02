// msb_index.sv 
// James Kaden Cassidy
// kacassidy@hmc.edu
// 12/1/2025

module msb_index #(
    parameter int WIDTH = 8
)(
    input  logic [WIDTH-1:0]         in,
    output logic [$clog2(WIDTH)-1:0] idx,    // index of MSB '1'
    output logic                     valid   // 1 if any bit is set
);

    always_comb begin
        valid = (in != '0);
        idx   = '0;

        // Scan from MSB down to LSB; first '1' we see wins.
        for (int i = WIDTH-1; i >= 0; i--) begin
            if (in[i]) begin
                idx = i[$clog2(WIDTH)-1:0];
            end
        end
    end

endmodule

module lsb_index #(
    parameter int WIDTH = 8
)(
    input  logic [WIDTH-1:0]         in,
    output logic [$clog2(WIDTH)-1:0] idx    // index of MSB '1'
    //output logic                     valid   // 1 if any bit is set
);

    always_comb begin
        //valid = (in != '0);
        idx   = WIDTH[$clog2(WIDTH)-1:0];

        // Scan from MSB down to LSB; first '1' we see wins.
        for (int i = 0; i < WIDTH; i++) begin
            if (in[i]) begin
                idx = i[$clog2(WIDTH)-1:0];
            end
        end
    end

endmodule