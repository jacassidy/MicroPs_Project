// Game Decoder
// James Kaden Cassidy 
// kacassidy@hmc.edu
// 11/12/2025


module spi(
        input   logic    reset,
        input  logic sck, 
        input  logic sdi,
        output logic sdo,
        input  logic ce,
        output logic [7:0] data
    );

    logic [7:0] state;
    assign data = state;
    
    always_ff @(posedge sck) begin
        // if (reset)   state <= 0;
        // else begin
            if (ce) state[7:0] <= {state[6:0], sdi};
        // end
    end
   
endmodule