// Game Decoder
// James Kaden Cassidy 
// kacassidy@hmc.edu
// 11/12/2025

localparam int COLORS = 3;

module game_decoder #(
    parameter vga_pkg::vga_params_t params,
    parameter int                   TELEMETRY_NUM_SIGNALS,
    parameter int                   TELEMETRY_VALUE_WIDTH,
    parameter int                   TELEMETRY_BASE
)(
    input   logic                               clk,
    input   logic                               reset,

    output  logic                               VGA_new_frame_ready,

    input   game_state_pkg::game_state_t        VGA_frame,

    // 6 debug windows, each 3-color 6x6
    input   logic [5:0]                         debug_window_0 [COLORS][5:0],
    input   logic [5:0]                         debug_window_1 [COLORS][5:0],
    input   logic [5:0]                         debug_window_2 [COLORS][5:0],
    input   logic [5:0]                         debug_window_3 [COLORS][5:0],
    input   logic [5:0]                         debug_window_4 [COLORS][5:0],
    input   logic [5:0]                         debug_window_5 [COLORS][5:0],

    // 6 sets of debug signals (2Ã—8-bit each)
    input   logic [7:0]                         debug_singals_0 [2],
    input   logic [7:0]                         debug_singals_1 [2],
    input   logic [7:0]                         debug_singals_2 [2],
    input   logic [7:0]                         debug_singals_3 [2],
    input   logic [7:0]                         debug_singals_4 [2],
    input   logic [7:0]                         debug_singals_5 [2],

    input   logic [params.pixel_x_bits-1:0]     pixel_x_target_next,
    input   logic [params.pixel_y_bits-1:0]     pixel_y_target_next,
    output  logic                               pixel_value_next_R,
    output  logic                               pixel_value_next_G,
    output  logic                               pixel_value_next_B,

    input   logic                               v_sync,

    // Main 10x20 panel telemetry
    input   logic [TELEMETRY_VALUE_WIDTH-1:0]   telemetry_values [TELEMETRY_NUM_SIGNALS]
);

    // ----------------------------------------------------------------
    // Geometry constants
    // ----------------------------------------------------------------
    localparam int SCREEN_W = 640;
    localparam int SCREEN_H = 480;

    // Main 10x20 Tetris panel in the middle
    localparam int MAIN_X0         = 240;
    localparam int MAIN_Y0         = 80;
    localparam int MAIN_WIDTH      = 160;  // 10 * 2^4
    localparam int MAIN_HEIGHT     = 320;  // 20 * 2^4
    localparam int MAIN_SCALE      = 4;    // 16x16 logical cells
    localparam int MAIN_BORDER_PAD = 1;
    localparam int MAIN_BORDER_THK = 10;
    localparam int MAIN_TEL_VPAD   = 8;

    // Mini-panels for 6x6 debug windows
    localparam int DEBUG_FRAME_WIDTH  = 6;
    localparam int DEBUG_FRAME_HEIGHT = 6;

    localparam int MINI_SCALE       = 4;   // same cell size as main (16x16)
    localparam int MINI_WIDTH       = DEBUG_FRAME_WIDTH  << MINI_SCALE; // 6*16 = 96
    localparam int MINI_HEIGHT      = DEBUG_FRAME_HEIGHT << MINI_SCALE; // 6*16 = 96
    localparam int MINI_BORDER_PAD  = 1;
    localparam int MINI_BORDER_THK  = 4;
    localparam int MINI_TEL_VPAD    = 4;

    localparam int LEFT_X0          = 50;
    localparam int RIGHT_X0         = SCREEN_W - MINI_WIDTH - 50; // 640 - 96 = 544

    localparam int MINI_Y0_0        = 50;
    localparam int MINI_Y0_1        = MINI_HEIGHT + 100;           // 96
    localparam int MINI_Y0_2        = 2*MINI_HEIGHT + 150;         // 192

    localparam int NUM_PANELS       = 7; // 1 main + 6 mini

    // One bit per panel per color; OR-reduce for final pixel
    logic [NUM_PANELS-1:0] panel_R;
    logic [NUM_PANELS-1:0] panel_G;
    logic [NUM_PANELS-1:0] panel_B;

    // When vsync goes low to indicate a new frame, we allow a new game state
    assign VGA_new_frame_ready = ~v_sync;

    // ------------------------------------------------------------
    // Main 10x20 game panel (panel index 0)
    // ------------------------------------------------------------
    blit_screen #(
        .params                (params),
        .X0                    (MAIN_X0),
        .Y0                    (MAIN_Y0),
        .WIDTH                 (MAIN_WIDTH),
        .HEIGHT                (MAIN_HEIGHT),
        .SCALE_SHIFT           (MAIN_SCALE),
        .BORDER_PAD            (MAIN_BORDER_PAD),
        .BORDER_THICK          (MAIN_BORDER_THK),
        .TELEMETRY_VPAD        (MAIN_TEL_VPAD),
        .TELEMETRY_NUM_SIGNALS (TELEMETRY_NUM_SIGNALS),
        .TELEMETRY_VALUE_WIDTH (TELEMETRY_VALUE_WIDTH),
        .TELEMETRY_BASE        (TELEMETRY_BASE),
        // Frame size for the main game board
        .FRAME_WIDTH           (10),
        .FRAME_HEIGHT          (20)
    ) u_main_panel (
        .clk                 (clk),
        .reset               (reset),
        .frame_R             (VGA_frame.screen),
        .frame_G             (),
        .frame_B             (),
        .pixel_x_target_next (pixel_x_target_next),
        .pixel_y_target_next (pixel_y_target_next),
        .telemetry_values    (telemetry_values),
        .panel_pixel_R       (panel_R[0]),
        .panel_pixel_G       (panel_G[0]),
        .panel_pixel_B       (panel_B[0])
    );

    // ------------------------------------------------------------
    // Helper macro to instantiate a 6x6 debug panel
    // ------------------------------------------------------------
`define INSTANTIATE_DEBUG_PANEL(INST_NAME, INDEX, XPOS, YPOS, DBG_WIN, DBG_SIGS) \
    blit_screen #( \
        .params                (params), \
        .X0                    (XPOS), \
        .Y0                    (YPOS), \
        .WIDTH                 (MINI_WIDTH), \
        .HEIGHT                (MINI_HEIGHT), \
        .SCALE_SHIFT           (MINI_SCALE), \
        .BORDER_PAD            (MINI_BORDER_PAD), \
        .BORDER_THICK          (MINI_BORDER_THK), \
        .TELEMETRY_VPAD        (MINI_TEL_VPAD), \
        .TELEMETRY_NUM_SIGNALS (2),                  /* 2 debug signals per window */ \
        .TELEMETRY_VALUE_WIDTH (8),                  /* 8-bit values */ \
        .TELEMETRY_BASE        (TELEMETRY_BASE), \
        .FRAME_WIDTH           (DEBUG_FRAME_WIDTH),  /* 6x6 debug frame */ \
        .FRAME_HEIGHT          (DEBUG_FRAME_HEIGHT)  \
    ) INST_NAME ( \
        .clk                 (clk), \
        .reset               (reset), \
        .frame_R             (DBG_WIN[0]), \
        .frame_G             (DBG_WIN[1]), \
        .frame_B             (DBG_WIN[2]), \
        .pixel_x_target_next (pixel_x_target_next), \
        .pixel_y_target_next (pixel_y_target_next), \
        .telemetry_values    (DBG_SIGS),             /* debug_singals_N as telemetry */ \
        .panel_pixel_R       (panel_R[INDEX]), \
        .panel_pixel_G       (panel_G[INDEX]), \
        .panel_pixel_B       (panel_B[INDEX]) \
    )

    // ------------------------------------------------------------
    // 3 mini panels on the left (indices 1â€“3)
    // ------------------------------------------------------------
    `INSTANTIATE_DEBUG_PANEL(u_mini_panel_L0, 1, LEFT_X0,  MINI_Y0_0, debug_window_0, debug_singals_0);
    `INSTANTIATE_DEBUG_PANEL(u_mini_panel_L1, 2, LEFT_X0,  MINI_Y0_1, debug_window_1, debug_singals_1);
    `INSTANTIATE_DEBUG_PANEL(u_mini_panel_L2, 3, LEFT_X0,  MINI_Y0_2, debug_window_2, debug_singals_2);

    // ------------------------------------------------------------
    // 3 mini panels on the right (indices 4â€“6)
    // ------------------------------------------------------------
    `INSTANTIATE_DEBUG_PANEL(u_mini_panel_R0, 4, RIGHT_X0, MINI_Y0_0, debug_window_3, debug_singals_3);
    `INSTANTIATE_DEBUG_PANEL(u_mini_panel_R1, 5, RIGHT_X0, MINI_Y0_1, debug_window_4, debug_singals_4);
    `INSTANTIATE_DEBUG_PANEL(u_mini_panel_R2, 6, RIGHT_X0, MINI_Y0_2, debug_window_5, debug_singals_5);

`undef INSTANTIATE_DEBUG_PANEL

    // ------------------------------------------------------------
    // Final composite: any panel "on" lights the pixel
    // ------------------------------------------------------------
    assign pixel_value_next_R = |panel_R;
    assign pixel_value_next_G = |panel_G;
    assign pixel_value_next_B = |panel_B;

endmodule
