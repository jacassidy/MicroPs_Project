// pll_clk.sv (speed-only params; other strings hardcoded)
// -------------------------------------------------------------------------------------
// iCE40 UltraPlus PLL_B pixel clock generator.
// Default: 48 MHz HSOSC -> ~25.5 MHz (DIVR=0, DIVF=16, DIVQ=5).
// f_out = f_ref * (DIVF+1) / ((DIVR+1) * 2^DIVQ)  when FEEDBACK_PATH="SIMPLE"
// Reset tip: don't feed LOCK into RESET_N of the PLL. Use LOCK to release system reset.
// -------------------------------------------------------------------------------------
// James Kaden Cassidy 
// kacassidy@hmce.edu
// 11/8/2025

module pll_clk #(
    // HSOSC divider: "0b00"=48, "0b01"=24, "0b10"=12, "0b11"=6 MHz
    parameter string CLKHF_DIV,

    // PLL speed controls (Lattice expects these as strings)
    parameter string DIVR,
    parameter string DIVF,
    parameter string DIVQ
) (
    input  logic rst_n,         // active-low reset for PLL primitive
    output logic clk_internal,  // OUTGLOBAL -> fabric/global
    output logic clk_external,  // OUTCORE   -> pad (debug)
    output logic clk_HSOSC,     // raw HSOSC for debug
    output logic locked         // PLL lock
);

    // 1) HSOSC reference
    logic clk_ref;
    HSOSC #(.CLKHF_DIV(CLKHF_DIV)) u_hsosc (
        .CLKHFPU (1'b1),
        .CLKHFEN (1'b1),
        .CLKHF   (clk_ref)
    );
    assign clk_HSOSC = clk_ref;

    // 2) PLL
    wire pll_lock;
    wire intfbout_wire;
    wire outcore_b_unused, outglobal_b_unused;

    PLL_B #(
        // Hardcoded behavior / mode params
        .EXTERNAL_DIVIDE_FACTOR         ("NONE"),
        .FEEDBACK_PATH                  ("SIMPLE"),
        .DELAY_ADJUSTMENT_MODE_FEEDBACK ("FIXED"),
        .FDA_FEEDBACK                   ("0"),
        .DELAY_ADJUSTMENT_MODE_RELATIVE ("FIXED"),
        .FDA_RELATIVE                   ("0"),
        .SHIFTREG_DIV_MODE              ("0"),
        .PLLOUT_SELECT_PORTA            ("GENCLK"),
        .PLLOUT_SELECT_PORTB            ("GENCLK"),
        .FILTER_RANGE                   ("1"),
        .ENABLE_ICEGATE_PORTA           ("0"),
        .ENABLE_ICEGATE_PORTB           ("0"),

        // Speed knobs (still parameterized)
        .DIVR                           (DIVR),
        .DIVF                           (DIVF),
        .DIVQ                           (DIVQ)
    ) u_pll (
        .REFERENCECLK  (clk_ref),
        .FEEDBACK      (intfbout_wire),

        // Dynamic delay / SPI interface disabled
        .DYNAMICDELAY7 (1'b0),
        .DYNAMICDELAY6 (1'b0),
        .DYNAMICDELAY5 (1'b0),
        .DYNAMICDELAY4 (1'b0),
        .DYNAMICDELAY3 (1'b0),
        .DYNAMICDELAY2 (1'b0),
        .DYNAMICDELAY1 (1'b0),
        .DYNAMICDELAY0 (1'b0),
        .BYPASS        (1'b0),
        .RESET_N       (rst_n),
        .SCLK          (1'b0),
        .SDI           (1'b0),
        .LATCH         (1'b0),

        // Feedback and outputs
        .INTFBOUT      (intfbout_wire),
        .OUTCOREB      (outcore_b_unused),
        .OUTGLOBALB    (outglobal_b_unused),
        .OUTCORE       (clk_external),   // to pad (debug)
        .OUTGLOBAL     (clk_internal),   // to fabric/global
        .SDO           (/*unused*/),
        .LOCK          (pll_lock)
    );

    assign locked = pll_lock;

endmodule
