// pll_clk_debug.sv — Example top that instantiates the parameterized PLL
// --------------------------------------------------------------------------------------
// This is a small debug top that:
//   * Drives a pixel/system clock from the PLL.
//   * Exposes the raw HFOSC and the PLL clock to top-level pins for probing.
//   * Includes a clean, parameterized instantiation so you can tweak divides per build.
// --------------------------------------------------------------------------------------
// James Kaden Cassidy 
// kacassidy@hmce.edu
// 11/8/2025

module pll_clk_debug (
    input  logic reset_n,
    output logic debug_pll_clk,
    output logic debug_HSOSC_clk,
    output logic test_led,
    output logic debug_derived_pll_clk
);

    // Wire the module outputs
    logic pll_clk_internal;
    logic pll_lock;

    // Instantiate parameterized PLL wrapper, instantiated 25.5MHz
    pll_clk #(
		.CLKHF_DIV("0b00"),
        .DIVR("0"),
		.DIVF("16"),
		.DIVQ("5")
    ) PLL_CLK (
        .rst_n       (reset_n),
        .clk_internal(pll_clk_internal),
        .clk_external(debug_pll_clk),
        .clk_HSOSC   (debug_HSOSC_clk),
        .locked      (pll_lock)
    );

    // Example: generate a visible /2 toggle in the PLL domain for scope probing
    always_ff @(posedge pll_clk_internal or negedge reset_n) begin
        if (!reset_n) debug_derived_pll_clk <= 1'b0;
        else          debug_derived_pll_clk <= ~debug_derived_pll_clk;
    end

    // For a quick sanity light: show LOCK (safest to sync before wide use; LED is okay)
    assign test_led = pll_lock;

endmodule
