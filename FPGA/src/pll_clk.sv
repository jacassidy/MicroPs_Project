// pll_clk.sv (parameterized, inline-params drop-in)
// -------------------------------------------------------------------------------------
// iCE40 UltraPlus PLL_B pixel clock generator with ALL tunables in the PARAMETER list,
// and the PLL primitive configured via inline #() parameters (no defparams).
// Default: 48 MHz HSOSC -> ~25.5 MHz (DIVR=0, DIVF=16, DIVQ=5).
// -------------------------------------------------------------------------------------
// f_out = f_ref * (DIVF+1) / ((DIVR+1) * 2^DIVQ)  when FEEDBACK_PATH="SIMPLE"
// Reset rule of thumb:
//   * Do NOT tie LOCK back into the PLL's own RESET_N (deadlock). Keep PLL enabled.
//   * Use LOCK to release your system reset after a 2‑FF sync in the PLL clock domain.
// -------------------------------------------------------------------------------------

module pll_clk #(
    // HSOSC
    parameter string CLKHF_DIV = "0b00",     // "0b00"=48, "0b01"=24, "0b10"=12, "0b11"=6

    // External control usage
    parameter bit    USE_EXT_BYPASS = 1'b0,  // 0=force BYPASS=0, 1=use 'bypass' port
    parameter bit    USE_EXT_LATCH  = 1'b0,  // 0=force LATCH=0,  1=use 'latch'  port

    // PLL core parameters
    parameter string FEEDBACK_PATH  = "SIMPLE",
    parameter string EXTERNAL_DIVIDE_FACTOR = "NONE",
    parameter string DELAY_ADJUSTMENT_MODE_FEEDBACK = "FIXED",
    parameter string DELAY_ADJUSTMENT_MODE_RELATIVE = "FIXED",
    parameter string FDA_FEEDBACK   = "0",
    parameter string FDA_RELATIVE   = "0",
    parameter string SHIFTREG_DIV_MODE = "0",
    parameter string PLLOUT_SELECT_PORTA = "GENCLK",
    parameter string PLLOUT_SELECT_PORTB = "GENCLK",
    parameter string DIVR = "0",
    parameter string DIVF = "16",
    parameter string DIVQ = "5",
    parameter string FILTER_RANGE = "1",
    parameter string ENABLE_ICEGATE_PORTA = "0",
    parameter string ENABLE_ICEGATE_PORTB = "0"
) (
    input  logic rst_n,         // active‑low reset for the PLL primitive
    input  logic bypass,        // optional ext bypass (if enabled)
    input  logic latch,         // optional ext latch  (if enabled)
    output logic clk_internal,  // OUTGLOBALB -> fabric/global
    output logic clk_external,  // OUTCOREB   -> pad (debug)
    output logic clk_HSOSC,     // raw HSOSC for debug
    output logic locked         // PLL lock
);

    // 1) HSOSC reference (trim pins tied low to silence warnings if present)
    logic clk_ref;
    HSOSC #(.CLKHF_DIV(CLKHF_DIV)) u_hsosc (
        .CLKHFPU (1'b1),
        .CLKHFEN (1'b1),
        .CLKHF   (clk_ref)
    );
    assign clk_HSOSC = clk_ref;

    // 2) PLL_B (inline parameters)
    wire bypass_i = USE_EXT_BYPASS ? bypass : 1'b0;
    wire latch_i  = USE_EXT_LATCH  ? latch  : 1'b0;

    wire pll_lock;
    wire intfbout_wire;
    wire outcore_b_unused, outglobal_b_unused;

    PLL_B #(
        .EXTERNAL_DIVIDE_FACTOR         (EXTERNAL_DIVIDE_FACTOR),
        .FEEDBACK_PATH                  (FEEDBACK_PATH),
        .DELAY_ADJUSTMENT_MODE_FEEDBACK (DELAY_ADJUSTMENT_MODE_FEEDBACK),
        .FDA_FEEDBACK                   (FDA_FEEDBACK),
        .DELAY_ADJUSTMENT_MODE_RELATIVE (DELAY_ADJUSTMENT_MODE_RELATIVE),
        .FDA_RELATIVE                   (FDA_RELATIVE),
        .SHIFTREG_DIV_MODE              (SHIFTREG_DIV_MODE),
        .PLLOUT_SELECT_PORTA            (PLLOUT_SELECT_PORTA),
        .PLLOUT_SELECT_PORTB            (PLLOUT_SELECT_PORTB),
        .DIVR                           (DIVR),
        .DIVF                           (DIVF),
        .DIVQ                           (DIVQ),
        .FILTER_RANGE                   (FILTER_RANGE),
        .ENABLE_ICEGATE_PORTA           (ENABLE_ICEGATE_PORTA),
        .ENABLE_ICEGATE_PORTB           (ENABLE_ICEGATE_PORTB)
    ) u_pll (
        .REFERENCECLK  (clk_ref),
        .FEEDBACK      (intfbout_wire),
        .DYNAMICDELAY7 (1'b0),
        .DYNAMICDELAY6 (1'b0),
        .DYNAMICDELAY5 (1'b0),
        .DYNAMICDELAY4 (1'b0),
        .DYNAMICDELAY3 (1'b0),
        .DYNAMICDELAY2 (1'b0),
        .DYNAMICDELAY1 (1'b0),
        .DYNAMICDELAY0 (1'b0),
        .BYPASS        (bypass_i),
        .RESET_N       (rst_n),
        .SCLK          (1'b0),
        .SDI           (1'b0),
        .LATCH         (latch_i),
        .INTFBOUT      (intfbout_wire),
        .OUTCOREB      (outcore_b_unused),
        .OUTGLOBALB    (outglobal_b_unused),
        .OUTCORE       (clk_external),   // to pad
        .OUTGLOBAL     (clk_internal),   // to fabric/global
        .SDO           (/*unused*/),
        .LOCK          (pll_lock)
    );

    assign locked = pll_lock;

endmodule
