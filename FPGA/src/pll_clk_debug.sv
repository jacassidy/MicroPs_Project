// VGA Controller
// James Kaden Cassidy 
// kacassidy@hmce.edu
// 11/8/2025

module pll_clk_debug (
	input 	logic 	reset_n,
    output  logic   debug_pll_clk,
	output  logic   debug_HSOSC_clk,
	output 	logic 	test_led,
	output	logic	confirm_locked
);

    // Ex: request a 25.175 MHz pixel clock for VGA
    pll_clk PLL_CLK(
        .rst_n(reset_n),      // active-low reset to PLL
        .bypass(1'b0),   // 1 = bypass PLL (REF clocks out)
        .latch(1'b0),    // 1 = hold last output value if ICEGATE enabled
        .clk_internal(),  // pixel clock (from OUTGLOBALB)
        .clk_external(debug_pll_clk),
		.clk_HSOSC(debug_HSOSC_clk),
        .locked()    // PLL lock indicator
    );

	assign test_led = reset_n;

endmodule