// pll_clk.sv
// ----------------------------------------------------------------------------
// iCE40 UltraPlus pixel clock generator (Radiant/LSE).
// Uses on-chip HSOSC as reference and the library PLL_B primitive.
//
// REASONABLE TARGET RANGE (practical):
// - REFERENCECLK into PLL must be 10–133 MHz (per PLL_B doc).
//   HSOSC provides: 48, 24, 12, 6 MHz via CLKHF_DIV = "0b00","0b01","0b10","0b11"
//   NOTE: 6 MHz is BELOW the 10 MHz minimum, so prefer 48/24/12 MHz.
//
// - Output frequency is limited by the device PLL (PFD/VCO) ranges in the datasheet.
//   If you stay in ~10–200+ MHz out with REF of 48/24/12 MHz, you’re typically fine.
//   (Exact limits: see iCE40 UltraPlus datasheet/sysCLOCK PLL guide for VCO/PFD details.)
//
// HOW TO CHOOSE PLL SETTINGS (FEEDBACK_PATH="SIMPLE", output on Port B):
//   Fout = Fref/(DIVR+1) * (DIVF+1) / 2^DIVQ * K
//   where K = 1 if PLLOUT_SELECT_PORTB="GENCLK", or K = 1/2 if "GENCLK_HALF"
//
// Steps:
//  1) Pick HSOSC divider so Fref ∈ {48,24,12} MHz (≥10 MHz).
//  2) Choose DIVR in [0..15] so PFD = Fref/(DIVR+1) stays within PLL limits.
//  3) Pick DIVQ in [1..6]. Then solve DIVF ≈ Fout * 2^DIVQ * (DIVR+1)/Fref − 1,
//     clamp to [0..127]. Adjust DIVQ/DIVR if needed.
//  4) Set PLLOUT_SELECT_PORTB to "GENCLK" (or "GENCLK_HALF" to divide by 2).
//  5) FILTER_RANGE: choose a reasonable value for your PFD (Radiant wizard often picks 4–6).
//
// NOTES FOR VGA:
// - Exact “dot clocks” like 25.175 MHz are not always achievable with integer PLL settings.
//   Common close choices are 24.000 or 25.500 or 27.000 MHz; most modern monitors accept them.
//
// ----------------------------------------------------------------------------

`timescale 1ns/1ps
module pll_clk #(
    // Documentation-only: desired pixel clock in Hz (not used to auto-calc)
    parameter int unsigned PIXEL_FREQ_HZ = 25_175_000,

    // HSOSC divider: "0b00"=48 MHz, "0b01"=24 MHz, "0b10"=12 MHz, "0b11"=6 MHz (avoid "0b11")
    parameter string       CLKHF_DIV      = "0b00",

    // ---------- PLL_B numeric settings as STRINGS (match library expectations) ----------
    // Example (≈25.5 MHz from 48 MHz): DIVR="0", DIVF="16", DIVQ="5", PLLOUT="GENCLK"
    // Example (27.0 MHz from 12 MHz):  CLKHF_DIV="0b10", DIVR="0", DIVF="8", DIVQ="2"
    parameter string       P_DIVR         = "0",
    parameter string       P_DIVF         = "16",
    parameter string       P_DIVQ         = "5",
    parameter string       P_FILTER_RANGE = "4",        // typical mid value; adjust as needed
    parameter string       P_PLLOUT_B     = "GENCLK",   // "GENCLK" or "GENCLK_HALF"

    // Gate/bypass controls default to disabled
    parameter string       P_ENABLE_ICEGATE_PORTB = "0" // "1" enables LATCH to hold output
) (
    input  logic rst_n,      // active-low reset to PLL
    input  logic bypass,   // 1 = bypass PLL (REF clocks out)
    input  logic latch,    // 1 = hold last output value if ICEGATE enabled
    output logic clk_internal,  // pixel clock (from OUTGLOBALB)
    output logic clk_external,  // pixel clock (from OUTCOREB)
    output logic locked    // PLL lock indicator
);

    // --------------------------------------------------------------------------
    // 1) Reference clock: HSOSC
    // --------------------------------------------------------------------------
    logic clk_ref;

    HSOSC #(
        .CLKHF_DIV(CLKHF_DIV)         // "0b00","0b01","0b10","0b11"
    ) u_hsosc (
        .CLKHFPU (1'b1),              // power up
        .CLKHFEN (1'b1),              // enable
        .CLKHF   (clk_ref)
    );

    // --------------------------------------------------------------------------
    // 2) PLL_B (internal feedback, SIMPLE path, output on Port B/global)
    //    Tie dynamic/test ports off for clarity.
    // --------------------------------------------------------------------------
    wire pll_lock;
    wire outcore_b_unused, outcore_a_unused, outglobal_a_unused;
    wire intfbout_wire;

    PLL_B u_pll (
        .REFERENCECLK  (clk_ref),
        .FEEDBACK      (intfbout_wire),   // internal feedback
        // Dynamic delay (unused in FIXED mode)
        .DYNAMICDELAY7 (1'b0),
        .DYNAMICDELAY6 (1'b0),
        .DYNAMICDELAY5 (1'b0),
        .DYNAMICDELAY4 (1'b0),
        .DYNAMICDELAY3 (1'b0),
        .DYNAMICDELAY2 (1'b0),
        .DYNAMICDELAY1 (1'b0),
        .DYNAMICDELAY0 (1'b0),
        // Controls
        .BYPASS        (bypass_i),
        .RESET_N       (rst_n),
        .SCLK          (1'b0),            // test
        .SDI           (1'b0),            // test
        .LATCH         (latch_i),         // low-power gate if enabled
        // Outputs
        .INTFBOUT      (intfbout_wire),
        .OUTCORE       (outcore_a_unused),
        .OUTGLOBAL     (outglobal_a_unused),
        .OUTCOREB      (clk_external),
        .OUTGLOBALB    (clk_internal),       // << use global net for low-skew clocking
        .SDO           (/*unused*/),
        .LOCK          (pll_lock)
    );

    // Library parameters via defparam (mirrors Radiant reference guide)
    // Internal feedback, SIMPLE path; Port B drives our clock.
    // Keep EXTERNAL_DIVIDE_FACTOR="NONE" with internal feedback.
    defparam u_pll.EXTERNAL_DIVIDE_FACTOR          = "NONE";
    defparam u_pll.FEEDBACK_PATH                   = "SIMPLE";
    defparam u_pll.DELAY_ADJUSTMENT_MODE_FEEDBACK  = "FIXED";
    defparam u_pll.FDA_FEEDBACK                    = "0";
    defparam u_pll.DELAY_ADJUSTMENT_MODE_RELATIVE  = "FIXED";
    defparam u_pll.FDA_RELATIVE                    = "0";
    defparam u_pll.SHIFTREG_DIV_MODE               = "0";
    defparam u_pll.PLLOUT_SELECT_PORTA             = "GENCLK";      // not used
    defparam u_pll.PLLOUT_SELECT_PORTB             = P_PLLOUT_B;    // "GENCLK" or "GENCLK_HALF"

    // Core dividers
    defparam u_pll.DIVR                            = P_DIVR;         // "0".."15"
    defparam u_pll.DIVF                            = P_DIVF;         // "0".."127"
    defparam u_pll.DIVQ                            = P_DIVQ;         // "1".."6"
    defparam u_pll.FILTER_RANGE                    = P_FILTER_RANGE; // "0".."7"

    // Optional output gating
    defparam u_pll.ENABLE_ICEGATE_PORTA            = "0";
    defparam u_pll.ENABLE_ICEGATE_PORTB            = P_ENABLE_ICEGATE_PORTB;

    // Lock out
    assign locked_o = pll_lock;

endmodule
