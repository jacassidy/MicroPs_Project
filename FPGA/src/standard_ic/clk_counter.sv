// James Kaden Cassidy kacassidy@hmc.edu 8/31/2025

// this module is made to count to an arbitrary number. It functions by counting counting possitive and toggling a flop
// once a the count hits count

module clk_counter #(parameter count_target) (
    input   logic   clk,
    input   logic   reset,
    output  logic   count_achieved
);

 localparam bits_wide = $clog2(count_target);

 logic[bits_wide-1:0] count, countp1;
 logic                set;

 assign countp1 = count + 1;
 
 // add one to the count on each posedge
 always_ff @ (posedge clk) begin
    if(reset)  count <= 'b0;
    else       count <= countp1;
 end

 assign set = count >= count_target-1;
  
 // Only track when the count has been hit, rely on reset to restart the count
 always_ff @ (posedge clk) begin
   if (reset)  count_achieved <= 1'b0;
   if (set)    count_achieved <= 1'b1;
 end    

  

endmodule