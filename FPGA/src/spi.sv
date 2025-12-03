// Game Decoder
// James Kaden Cassidy 
// kacassidy@hmc.edu
// 11/12/2025


module spi #(
    parameter int WIDTH = 8
) (
    input  logic              reset,   // async reset, active high
    input  logic              clk,
    input  logic              sck,     // SPI clock
    input  logic              sdi,     // serial data in
    output logic              sdo,     // serial data out (MSB)
    input  logic              ce,      // chip enable, active high
    input  logic              clear,   // pulse to clear data_valid
    output logic [WIDTH-1:0]  data,    // last completed word
    output logic              data_valid
);
    // logic [7:0] state;
    // assign data = state;
    
    // always_ff @(posedge sck) begin
    //     // if (reset)   state <= 0;
    //     // else begin
    //         if (ce) state[7:0] <= {state[6:0], sdi};
    //     // end
    // end

    logic             ce_q;  // previous value of ce in sck domain

    logic [WIDTH:0] shift_reg;
    //logic [WIDTH-1:0] shift_reg;
    
    always_ff @(posedge sck) begin
        if (reset) begin
             shift_reg  <= 0;
             ce_q       <= 1'b0;
        end else begin
            if (ce) shift_reg[WIDTH:0] <= {shift_reg[WIDTH-1:0], sdi}; //shift_reg[WIDTH-1:0] <= {shift_reg[WIDTH-2:0], sdi};
            // remember previous CE to detect edge
            ce_q <= ce;
        end
    end

    logic new_transaction;

    always_ff @(posedge clk) begin
        if (reset) begin
            data       <= '0;
            data_valid <= 1'b0;
            new_transaction <= 1'b0;
        end else begin
        // detect CE de-assert (1 -> 0) and latch new data
            if (ce) new_transaction <= 1'b1;
            // "chip de_enables" in your wording
            if (ce_q & ~ce & new_transaction) begin
                //data       <= shift_reg[WIDTH:1];
                data       <= shift_reg[WIDTH-1:0];
                data_valid <= 1'b1;

                new_transaction <= 1'b0;
            end

            // external logic can clear the valid flag
            if (clear) begin
                data_valid <= 1'b0;
            end
        end
    end

endmodule
