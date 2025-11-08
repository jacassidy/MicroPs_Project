// VGA Controller
// James Kaden Cassidy 
// kacassidy@hmce.edu
// 11/8/2025

module vga_controller #(
    parameter vga_pkg::vga_params_t params = vga_pkg::VGA_640x480_60 // TODO Remove after debugging
) (
    output  logic[$clog2(params.h_visible)-1:0]     pixel_x_target_next,
    output  logic[$clog2(params.v_visible)-1:0]     pixel_y_target_next,
    input   logic                                   pixel_value_next,
    output  logic                                   h_sync,
    output  logic                                   v_sync,
    output  logic                                   pixel_signal,
    output  logic                                   vga_clk,

    output  logic                                   debug_pll_clk
);

    // Ex: request a 25.175 MHz pixel clock for VGA
    pll_clk PLL_CLK(
        .rst_n(1'b1),      // active-low reset to PLL
        .bypass(1'b0),   // 1 = bypass PLL (REF clocks out)
        .latch(1'b0),    // 1 = hold last output value if ICEGATE enabled
        .clk_internal(),  // pixel clock (from OUTGLOBALB)
        .clk_external(debug_pll_clk),
        .locked(pll_locked)    // PLL lock indicator
    );



endmodule