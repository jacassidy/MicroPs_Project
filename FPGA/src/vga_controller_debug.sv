// VGA Controller debug
// James Kaden Cassidy
// kacassidy@hmc.edu
// 11/8/2025

module vga_controller_debug #(
    parameter string IMG_FILE = "smiley.hex"   // 40 rows x 40-bit hex words (MSB = leftmost)
)(
    input  logic reset_n,
    output logic h_sync,
    output logic v_sync,
    output logic pixel_signal,
    output logic debug_v_visible,
    output logic debug_h_visible
);
    // --------------------------------------------------------------------------------
    // Wires to/from VGA core
    // --------------------------------------------------------------------------------
    logic        pixel_signal_inv;
    logic [9:0]  pixel_x_target_next;  // 0..639
    logic [8:0]  pixel_y_target_next;  // 0..479

    assign pixel_signal = pixel_signal_inv;

    // --------------------------------------------------------------------------------
    // 40x30 1bpp image ROM. Each line of smiley.hex is a 40-bit hex word (10 hex chars)
    // MSB is the leftmost pixel of that row.
    // --------------------------------------------------------------------------------
    localparam int SRC_W = 40;
    localparam int SRC_H = 30;

    logic [SRC_W-1:0] src_row [0:SRC_H-1];
    initial $readmemh(IMG_FILE, src_row);

    // --------------------------------------------------------------------------------
    // 1:16 mapping: screen(640x480) -> logical(40x30)
    // sx = x/16, sy = y/16  (use shifts since x,y >= 0)
    // --------------------------------------------------------------------------------
    wire [5:0] sx = pixel_x_target_next[9:4]; // 0..39
    wire [4:0] sy = pixel_y_target_next[8:4]; // 0..29

    wire in_bitmap = (sx < SRC_W) && (sy < SRC_H);
    wire src_bit   = in_bitmap ? src_row[sy][SRC_W-1 - sx] : 1'b0;

    // --------------------------------------------------------------------------------
    // VGA controller
    // --------------------------------------------------------------------------------
    vga_controller VGA_Controller (
        .reset_n,
        // pixel addressing (for renderer)
        .pixel_x_target_next (pixel_x_target_next),
        .pixel_y_target_next (pixel_y_target_next),
        .pixel_value_next    (src_bit),          // 1=on, 0=off
        // VGA pins
        .h_sync,
        .v_sync,
        .pixel_signal        (pixel_signal_inv), // core will gate to visible region
        .vga_clk(),
        // optional debug outs
        .debug_pll_clk(),
        .debug_HSOSC_clk(),
        .pll_lock(),
        .debug_v_visible,
        .debug_h_visible
    );

endmodule
