// VGA Controller
// James Kaden Cassidy 
// kacassidy@hmc.edu
// 11/8/2025

module vga_controller #(
    parameter vga_pkg::vga_params_t params = vga_pkg::VGA_640x480_60
) (
    input  logic                                   reset_n,              // async, active-low
    // pixel addressing (for your renderer)
    output logic [$clog2(params.h_visible)-1:0]    pixel_x_target_next,
    output logic [$clog2(params.v_visible)-1:0]    pixel_y_target_next,
    input  logic                                   pixel_value_next,     // 1=on, 0=off (next pixel)
    // VGA pins
    output logic                                   h_sync,
    output logic                                   v_sync,
    output logic                                   pixel_signal,         // gated with visible region
    output logic                                   vga_clk,              // internal/global pixel clock (PLLOUTGLOBALB)
    // optional debug outs (safe to send to pins)
    output logic                                   debug_pll_clk,        // PLLOUTCOREB (ok to PIO)
    output logic                                   debug_HSOSC_clk,      // raw HSOSC tap (optional)
    output logic                                   pll_lock,
    output logic                                   debug_v_visible,
    output logic                                   debug_h_visible
);

    // -------------------------------------------------------------------------
    // PLL: 48 MHz HSOSC -> ~25.5 MHz (DIVR=0, DIVF=16, DIVQ=5)
    // -------------------------------------------------------------------------
    logic pll_clk_internal; // global clock for fabric (PLLOUTGLOBALB)
    logic pll_clk_external;     // local/core clock (PLLOUTCOREB)

    pll_clk #(
        .CLKHF_DIV("0b00"),  // 48 MHz HSOSC
        .DIVR     ("0"),
        .DIVF     ("16"),
        .DIVQ     ("5")
    ) PLL_CLK (
        .rst_n       (reset_n),
        .clk_internal(pll_clk_internal),  // use this to clock your VGA logic
        .clk_external(pll_clk_external),      // use this if you want to drive a pin
        .clk_HSOSC   (debug_HSOSC_clk),
        .locked      (pll_lock)
    );

    // Expose clocks as requested
    assign vga_clk       = pll_clk_internal;
    assign debug_pll_clk = pll_clk_external;

    // -------------------------------------------------------------------------
    // Synchronized reset release: hold counters in reset until PLL is locked
    // -------------------------------------------------------------------------
    logic lock_sync1, lock_sync2;
    always_ff @(posedge vga_clk or negedge reset_n) begin
        if (~reset_n) begin
            lock_sync1 <= 1'b0;
            lock_sync2 <= 1'b0;
        end else begin
            lock_sync1 <= pll_lock;
            lock_sync2 <= lock_sync1;
        end
    end
    wire pix_rst_n = lock_sync2;  // active when PLL is locked and synced

    // -------------------------------------------------------------------------
    // Timing totals (all compile-time constants from params)
    // -------------------------------------------------------------------------
    localparam int H_TOTAL = params.h_visible
                           + params.h_front_porch
                           + params.h_sync_pulse
                           + params.h_back_porch;

    localparam int V_TOTAL = params.v_visible
                           + params.v_front_porch
                           + params.v_sync_pulse
                           + params.v_back_porch;

    // Counters
    logic [$clog2(H_TOTAL)-1:0] h_ctr;
    logic [$clog2(V_TOTAL)-1:0] v_ctr;

    // -------------------------------------------------------------------------
    // Pixel clock domain counters
    // -------------------------------------------------------------------------
    always_ff @(posedge vga_clk or negedge pix_rst_n) begin
        if (~pix_rst_n) begin
            h_ctr <= '0;
            v_ctr <= '0;
        end else begin
            // Advance horizontal
            if (h_ctr == H_TOTAL-1) begin
                h_ctr <= '0;
                // Advance vertical at end of line
                if (v_ctr == V_TOTAL-1) v_ctr <= '0;
                else                    v_ctr <= v_ctr + 1;
            end else begin
                h_ctr <= h_ctr + 1;
            end
        end
    end

    // -------------------------------------------------------------------------
    // Visible region and next-pixel coordinates
    // -------------------------------------------------------------------------
    wire in_h_vis = (h_ctr < params.h_visible);
    wire in_v_vis = (v_ctr < params.v_visible);
    wire video_on = in_h_vis & in_v_vis;

    // â€œnextâ€ pixel addresses = current counters in active area (else 0)
    always_comb begin
        pixel_x_target_next = in_h_vis ? h_ctr[$bits(pixel_x_target_next)-1:0] : '0;
        pixel_y_target_next = in_v_vis ? v_ctr[$bits(pixel_y_target_next)-1:0] : '0;
    end

    // Gate the incoming pixel bit with the visible window
    assign pixel_signal = video_on & pixel_value_next;

    // -------------------------------------------------------------------------
    // HSYNC / VSYNC pulses (polarity from params)
    //   HSYNC active window:  [h_vis + h_fp, h_vis + h_fp + h_sync)
    //   VSYNC active window:  [v_vis + v_fp, v_vis + v_fp + v_sync)
    // -------------------------------------------------------------------------
    wire hsync_pulse = (h_ctr >= (params.h_visible + params.h_front_porch)) &&
                       (h_ctr <  (params.h_visible + params.h_front_porch + params.h_sync_pulse));

    wire vsync_pulse = (v_ctr >= (params.v_visible + params.v_front_porch)) &&
                       (v_ctr <  (params.v_visible + params.v_front_porch + params.v_sync_pulse));

    // Assumes params.h_active_low / params.v_active_low are set for the mode
    assign h_sync = params.h_sync_active_low ? ~hsync_pulse : hsync_pulse;
    assign v_sync = params.v_sync_active_low ? ~vsync_pulse : vsync_pulse;



    assign debug_h_visible = in_h_vis;
    assign debug_v_visible = in_v_vis;
endmodule