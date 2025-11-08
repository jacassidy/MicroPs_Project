// VGA Controller
// James Kaden Cassidy 
// kacassidy@hmce.edu
// 11/8/2025

module vga_controller (
    output  logic   debug_pll_clk
)

    // Ex: request a 25.175 MHz pixel clock for VGA
    pll_clk PLL_CLK(
        .rst_n(1'b1),      // active-low reset to PLL
        .bypass(1'b0),   // 1 = bypass PLL (REF clocks out)
        .latch(1'b0),    // 1 = hold last output value if ICEGATE enabled
        .clk_internal(),  // pixel clock (from OUTGLOBALB)
        .clk_external(debug_pll_clk),
        .locked()    // PLL lock indicator
    );



endmodule