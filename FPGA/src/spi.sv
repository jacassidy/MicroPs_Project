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

    logic             ce_q;  // previous value of ce in sck domain
    logic             synced_sclk;

    logic [WIDTH:0] shift_reg;
    //logic [WIDTH-1:0] shift_reg;
    synchronizer #(
        .bits(1)
    ) Sclk_sync (
        .clk               (clk),
        .raw_input         (sck),
        .synchronized_value(synced_sclk)
    );
    
    always_ff @(posedge synced_sclk) begin
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
            //data       <= '0;
            data_valid <= 1'b0;
            new_transaction <= 1'b0;
        end else begin
        // detect CE de-assert (1 -> 0) and latch new data
            if (ce) begin
                new_transaction <= 1'b1;
            end
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
