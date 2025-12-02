// Game Decoder
// James Kaden Cassidy 
// kacassidy@hmc.edu
// 11/12/2025

module game_decoder #(
    parameter vga_pkg::vga_params_t params,
    parameter int                   TELEMETRY_NUM_SIGNALS,    
    parameter int                   TELEMETRY_VALUE_WIDTH,
    parameter int                   TELEMETRY_BASE
)(
    input  logic                               clk,
    input  logic                               reset,

    output logic                               VGA_new_frame_ready,

    input  game_state_pkg::game_state_t        VGA_frame,

    input  logic [params.pixel_x_bits-1:0]     pixel_x_target_next,
    input  logic [params.pixel_y_bits-1:0]     pixel_y_target_next,
    output logic                               pixel_value_next,

    input  logic                               v_sync,

    input  logic [TELEMETRY_VALUE_WIDTH-1:0]   telemetry_values [TELEMETRY_NUM_SIGNALS]
);

    // When vsync goes low to indicate a new frame, we allow a new game state
    assign VGA_new_frame_ready = ~v_sync;

    // Single panel instance with your current geometry:
    // GAME_X_MIN = 240, GAME_X_MAX = 400  => WIDTH  = 160
    // GAME_Y_MIN = 80,  GAME_Y_MAX = 400  => HEIGHT = 320
    // Scaling: drop 4 bits => 16x16 pixels per logical cell
    blit_screen #(
        .params                (params),
        .X0                    (240),
        .Y0                    (80),
        .WIDTH                 (160),
        .HEIGHT                (320),
        .SCALE_SHIFT           (4),
        .BORDER_PAD            (1),
        .BORDER_THICK          (10),
        .TELEMETRY_VPAD        (8),  // vertical gap below border
        .TELEMETRY_NUM_SIGNALS (TELEMETRY_NUM_SIGNALS),
        .TELEMETRY_VALUE_WIDTH (TELEMETRY_VALUE_WIDTH),
        .TELEMETRY_BASE        (TELEMETRY_BASE)
    ) u_main_panel (
        .clk                 (clk),
        .reset               (reset),
        .frame               (VGA_frame),
        .pixel_x_target_next (pixel_x_target_next),
        .pixel_y_target_next (pixel_y_target_next),
        .telemetry_values    (telemetry_values),
        .panel_pixel         (pixel_value_next)
    );

endmodule
