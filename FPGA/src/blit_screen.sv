// blit_screen
// James Kaden Cassidy 
// kacassidy@hmc.edu
// 12/2/2025

// -----------------------------------------------------------------------------
// game_panel_with_telemetry
//   Generic "board + border + telemetry" panel.
//
//   - Places a game board at (X0,Y0) with logical size WIDTH x HEIGHT pixels
//   - Scales physical pixels down to board cells using SCALE_SHIFT
//   - Draws a border around the game area with BORDER_PAD/BORDER_THICK
//   - Places telemetry box TELEMETRY_VPAD pixels *below* the outer border
// -----------------------------------------------------------------------------
module blit_screen #(
    parameter vga_pkg::vga_params_t params,

    // Game area placement (in screen pixels)
    parameter int X0,
    parameter int Y0,
    parameter int WIDTH,   // GAME_X_MAX - GAME_X_MIN
    parameter int HEIGHT,   // GAME_Y_MAX - GAME_Y_MIN

    parameter int FRAME_WIDTH,
    parameter int FRAME_HEIGHT,

    // How many LSBs to drop when mapping pixels -> board cells (2^SCALE_SHIFT)
    parameter int SCALE_SHIFT,     // 16x16 pixels per cell

    // Border geometry
    parameter int BORDER_PAD,
    parameter int BORDER_THICK,

    // Vertical pad between bottom of border and telemetry box
    parameter int TELEMETRY_VPAD,

    // Telemetry formatting
    parameter int TELEMETRY_NUM_SIGNALS,
    parameter int TELEMETRY_VALUE_WIDTH,
    parameter int TELEMETRY_BASE        
) (
    input  logic                               clk,
    input  logic                               reset,

    // Game state to render
    input  logic [FRAME_HEIGHT-1:0]            frame_R [FRAME_WIDTH-1:0],
    input  logic [FRAME_HEIGHT-1:0]            frame_G [FRAME_WIDTH-1:0],
    input  logic [FRAME_HEIGHT-1:0]            frame_B [FRAME_WIDTH-1:0],

    // Current pixel from VGA timing
    input  logic [params.pixel_x_bits-1:0]     pixel_x_target_next,
    input  logic [params.pixel_y_bits-1:0]     pixel_y_target_next,

    // Telemetry values
    input  logic [TELEMETRY_VALUE_WIDTH-1:0]   telemetry_values [TELEMETRY_NUM_SIGNALS],

    // This panel's contribution to the pixel
    output logic                               panel_pixel_R,
    output logic                               panel_pixel_G,
    output logic                               panel_pixel_B
);

    // ------------------------------------------------------------
    // Derived game-area geometry
    // ------------------------------------------------------------
    localparam int GAME_X_MIN = X0;
    localparam int GAME_X_MAX = X0 + WIDTH;
    localparam int GAME_Y_MIN = Y0;
    localparam int GAME_Y_MAX = Y0 + HEIGHT;

    // ------------------------------------------------------------
    // Border controls
    //   BORDER_PAD:   gap between game area and inner edge of border
    //   BORDER_THICK: thickness of the border ring
    // ------------------------------------------------------------
    localparam int BORDER_INNER_X_MIN = GAME_X_MIN - BORDER_PAD;
    localparam int BORDER_INNER_X_MAX = GAME_X_MAX + BORDER_PAD;
    localparam int BORDER_INNER_Y_MIN = GAME_Y_MIN - BORDER_PAD;
    localparam int BORDER_INNER_Y_MAX = GAME_Y_MAX + BORDER_PAD;

    localparam int BORDER_OUTER_X_MIN = BORDER_INNER_X_MIN - BORDER_THICK;
    localparam int BORDER_OUTER_X_MAX = BORDER_INNER_X_MAX + BORDER_THICK;
    localparam int BORDER_OUTER_Y_MIN = BORDER_INNER_Y_MIN - BORDER_THICK;
    localparam int BORDER_OUTER_Y_MAX = BORDER_INNER_Y_MAX + BORDER_THICK;

    // ------------------------------------------------------------
    // Telemetry box placement: directly below the border
    // ------------------------------------------------------------
    localparam int TELEMETRY_BOX_X0 = BORDER_OUTER_X_MIN;
    localparam int TELEMETRY_BOX_Y0 = BORDER_OUTER_Y_MAX + TELEMETRY_VPAD;

    // ------------------------------------------------------------
    // Game pixel + border detection
    // ------------------------------------------------------------
    logic [params.pixel_x_bits-1:0] x_idx;
    logic [params.pixel_y_bits-1:0] y_idx;
    logic                           in_game_rect;
    logic                           game_pixel_value_R;
    logic                           game_pixel_value_G;
    logic                           game_pixel_value_B;
    logic                           game_pixel_R;
    logic                           game_pixel_G;
    logic                           game_pixel_B;
    logic                           border_pixel;
    logic                           telemetry_pixel;

    assign in_game_rect =
        (pixel_x_target_next >= GAME_X_MIN) && (pixel_x_target_next < GAME_X_MAX) &&
        (pixel_y_target_next >= GAME_Y_MIN) && (pixel_y_target_next < GAME_Y_MAX);

    // Local coordinates relative to top-left of game area
    assign x_idx = pixel_x_target_next - GAME_X_MIN;
    assign y_idx = pixel_y_target_next - GAME_Y_MIN;

    // Map physical pixels -> board cells using SCALE_SHIFT
    // Only valid when we're inside the game rect.
    always_comb begin
        if (in_game_rect) begin
            game_pixel_value_R =
                frame_R[ x_idx[params.pixel_x_bits-1:SCALE_SHIFT] ]
                             [ y_idx[params.pixel_y_bits-1:SCALE_SHIFT] ];
            game_pixel_value_G =
                frame_G[ x_idx[params.pixel_x_bits-1:SCALE_SHIFT] ]
                             [ y_idx[params.pixel_y_bits-1:SCALE_SHIFT] ];
            game_pixel_value_B =
                frame_B[ x_idx[params.pixel_x_bits-1:SCALE_SHIFT] ]
                             [ y_idx[params.pixel_y_bits-1:SCALE_SHIFT] ];
        end else begin
            game_pixel_value_R = 1'b0;
            game_pixel_value_G = 1'b0;
            game_pixel_value_B = 1'b0;
        end
    end

    assign game_pixel_R = in_game_rect & game_pixel_value_R;
    assign game_pixel_G = in_game_rect & game_pixel_value_G;
    assign game_pixel_B = in_game_rect & game_pixel_value_B;

    // Border logic
    assign border_pixel =
        (pixel_x_target_next >= BORDER_OUTER_X_MIN &&
         pixel_x_target_next <  BORDER_OUTER_X_MAX &&
         pixel_y_target_next >= BORDER_OUTER_Y_MIN &&
         pixel_y_target_next <  BORDER_OUTER_Y_MAX) &&
        !(pixel_x_target_next >= BORDER_INNER_X_MIN &&
          pixel_x_target_next <  BORDER_INNER_X_MAX &&
          pixel_y_target_next >= BORDER_INNER_Y_MIN &&
          pixel_y_target_next <  BORDER_INNER_Y_MAX);

    // ------------------------------------------------------------
    // Telemetry module, automatically placed below border
    // ------------------------------------------------------------
    telemetry_module #(
        .params                (params),
        .BOX_X0                (TELEMETRY_BOX_X0),
        .BOX_Y0                (TELEMETRY_BOX_Y0),
        .TELEMETRY_NUM_SIGNALS (TELEMETRY_NUM_SIGNALS),
        .TELEMETRY_VALUE_WIDTH (TELEMETRY_VALUE_WIDTH),
        .TELEMETRY_BASE        (TELEMETRY_BASE)
    ) u_telemetry (
        .clk                 (clk),
        .reset               (reset),
        .pixel_x_target_next (pixel_x_target_next),
        .pixel_y_target_next (pixel_y_target_next),
        .telemetry_values    (telemetry_values),
        .telemetry_pixel     (telemetry_pixel)
    );

    // Final output for this panel
    assign panel_pixel_R = game_pixel_R | border_pixel | telemetry_pixel;
    assign panel_pixel_G = game_pixel_G | border_pixel | telemetry_pixel;
    assign panel_pixel_B = game_pixel_B | border_pixel | telemetry_pixel;

endmodule

// blit_screen
// James Kaden Cassidy 
// kacassidy@hmc.edu
// 12/2/2025

// -----------------------------------------------------------------------------
// game_panel_with_telemetry
//   Generic "board + border + telemetry" panel.
//
//   - Places a game board at (X0,Y0) with logical size WIDTH x HEIGHT pixels
//   - Scales physical pixels down to board cells using SCALE_SHIFT
//   - Draws a border around the game area with BORDER_PAD/BORDER_THICK
//   - Places telemetry box TELEMETRY_VPAD pixels *below* the outer border
// -----------------------------------------------------------------------------
module blit_screen_no_telemetry #(
    parameter vga_pkg::vga_params_t params,

    // Game area placement (in screen pixels)
    parameter int X0,
    parameter int Y0,
    parameter int WIDTH,   // GAME_X_MAX - GAME_X_MIN
    parameter int HEIGHT,   // GAME_Y_MAX - GAME_Y_MIN

    parameter int FRAME_WIDTH,
    parameter int FRAME_HEIGHT,

    // How many LSBs to drop when mapping pixels -> board cells (2^SCALE_SHIFT)
    parameter int SCALE_SHIFT,     // 16x16 pixels per cell

    // Border geometry
    parameter int BORDER_PAD,
    parameter int BORDER_THICK,

    // Vertical pad between bottom of border and telemetry box
    parameter int TELEMETRY_VPAD,

    // Telemetry formatting
    parameter int TELEMETRY_NUM_SIGNALS,
    parameter int TELEMETRY_VALUE_WIDTH,
    parameter int TELEMETRY_BASE        
) (
    input  logic                               clk,
    input  logic                               reset,

    // Game state to render
    input  logic [FRAME_HEIGHT-1:0]            frame_R [FRAME_WIDTH-1:0],
    input  logic [FRAME_HEIGHT-1:0]            frame_G [FRAME_WIDTH-1:0],
    input  logic [FRAME_HEIGHT-1:0]            frame_B [FRAME_WIDTH-1:0],

    // Current pixel from VGA timing
    input  logic [params.pixel_x_bits-1:0]     pixel_x_target_next,
    input  logic [params.pixel_y_bits-1:0]     pixel_y_target_next,

    // Telemetry values
    input  logic [TELEMETRY_VALUE_WIDTH-1:0]   telemetry_values [TELEMETRY_NUM_SIGNALS],

    // This panel's contribution to the pixel
    output logic                               panel_pixel_R,
    output logic                               panel_pixel_G,
    output logic                               panel_pixel_B
);

    // ------------------------------------------------------------
    // Derived game-area geometry
    // ------------------------------------------------------------
    localparam int GAME_X_MIN = X0;
    localparam int GAME_X_MAX = X0 + WIDTH;
    localparam int GAME_Y_MIN = Y0;
    localparam int GAME_Y_MAX = Y0 + HEIGHT;

    // ------------------------------------------------------------
    // Border controls
    //   BORDER_PAD:   gap between game area and inner edge of border
    //   BORDER_THICK: thickness of the border ring
    // ------------------------------------------------------------
    localparam int BORDER_INNER_X_MIN = GAME_X_MIN - BORDER_PAD;
    localparam int BORDER_INNER_X_MAX = GAME_X_MAX + BORDER_PAD;
    localparam int BORDER_INNER_Y_MIN = GAME_Y_MIN - BORDER_PAD;
    localparam int BORDER_INNER_Y_MAX = GAME_Y_MAX + BORDER_PAD;

    localparam int BORDER_OUTER_X_MIN = BORDER_INNER_X_MIN - BORDER_THICK;
    localparam int BORDER_OUTER_X_MAX = BORDER_INNER_X_MAX + BORDER_THICK;
    localparam int BORDER_OUTER_Y_MIN = BORDER_INNER_Y_MIN - BORDER_THICK;
    localparam int BORDER_OUTER_Y_MAX = BORDER_INNER_Y_MAX + BORDER_THICK;

    // ------------------------------------------------------------
    // Telemetry box placement: directly below the border
    // ------------------------------------------------------------
    localparam int TELEMETRY_BOX_X0 = BORDER_OUTER_X_MIN;
    localparam int TELEMETRY_BOX_Y0 = BORDER_OUTER_Y_MAX + TELEMETRY_VPAD;

    // ------------------------------------------------------------
    // Game pixel + border detection
    // ------------------------------------------------------------
    logic [params.pixel_x_bits-1:0] x_idx;
    logic [params.pixel_y_bits-1:0] y_idx;
    logic                           in_game_rect;
    logic                           game_pixel_value_R;
    logic                           game_pixel_value_G;
    logic                           game_pixel_value_B;
    logic                           game_pixel_R;
    logic                           game_pixel_G;
    logic                           game_pixel_B;
    logic                           border_pixel;
    logic                           telemetry_pixel;

    assign in_game_rect =
        (pixel_x_target_next >= GAME_X_MIN) && (pixel_x_target_next < GAME_X_MAX) &&
        (pixel_y_target_next >= GAME_Y_MIN) && (pixel_y_target_next < GAME_Y_MAX);

    // Local coordinates relative to top-left of game area
    assign x_idx = pixel_x_target_next - GAME_X_MIN;
    assign y_idx = pixel_y_target_next - GAME_Y_MIN;

    // Map physical pixels -> board cells using SCALE_SHIFT
    // Only valid when we're inside the game rect.
    always_comb begin
        if (in_game_rect) begin
            game_pixel_value_R =
                frame_R[ x_idx[params.pixel_x_bits-1:SCALE_SHIFT] ]
                             [ y_idx[params.pixel_y_bits-1:SCALE_SHIFT] ];
            game_pixel_value_G =
                frame_G[ x_idx[params.pixel_x_bits-1:SCALE_SHIFT] ]
                             [ y_idx[params.pixel_y_bits-1:SCALE_SHIFT] ];
            game_pixel_value_B =
                frame_B[ x_idx[params.pixel_x_bits-1:SCALE_SHIFT] ]
                             [ y_idx[params.pixel_y_bits-1:SCALE_SHIFT] ];
        end else begin
            game_pixel_value_R = 1'b0;
            game_pixel_value_G = 1'b0;
            game_pixel_value_B = 1'b0;
        end
    end

    assign game_pixel_R = in_game_rect & game_pixel_value_R;
    assign game_pixel_G = in_game_rect & game_pixel_value_G;
    assign game_pixel_B = in_game_rect & game_pixel_value_B;

    // Border logic
    assign border_pixel =
        (pixel_x_target_next >= BORDER_OUTER_X_MIN &&
         pixel_x_target_next <  BORDER_OUTER_X_MAX &&
         pixel_y_target_next >= BORDER_OUTER_Y_MIN &&
         pixel_y_target_next <  BORDER_OUTER_Y_MAX) &&
        !(pixel_x_target_next >= BORDER_INNER_X_MIN &&
          pixel_x_target_next <  BORDER_INNER_X_MAX &&
          pixel_y_target_next >= BORDER_INNER_Y_MIN &&
          pixel_y_target_next <  BORDER_INNER_Y_MAX);


    // Final output for this panel
    assign panel_pixel_R = game_pixel_R | border_pixel;
    assign panel_pixel_G = game_pixel_G | border_pixel;
    assign panel_pixel_B = game_pixel_B | border_pixel;

endmodule

