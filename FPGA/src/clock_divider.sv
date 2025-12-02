// James Kaden Cassidy kacassidy@hmc.edu 8/31/2025

// this module is made to reduce the clock cycle by an arbitrary number. It functions by counting clock cycles and toggling a flop
// once a the count hits div_count

module clock_divider #(parameter div_count) (
    input   logic   clk,
    input   logic   reset,
    output  logic   clk_divided
);

 localparam bits_wide = $clog2(div_count);

 logic[bits_wide-1:0] oscillator_count, oscillator_countp1;
 logic                clear;

 assign oscillator_countp1 = oscillator_count + 1;
 
 // add one to the oscillator count on each oscillator posedge
 always_ff @ (posedge clk) begin
    if(reset | clear)  oscillator_count <= 'b0;
    else               oscillator_count <= oscillator_countp1;
 end

 // When the count reaches div_count, clear the counter and start again
 always_comb begin
    if (oscillator_count == div_count-1)   clear = 1'b1;
    else                                 clear = 1'b0;
 end
 
 // Each time the count is clear, toggle the led
 always_ff @ (posedge clk) begin
   if (reset)  clk_divided <= 1'b0;
   if (clear)  clk_divided <= ~clk_divided;
 end    

  

endmodule