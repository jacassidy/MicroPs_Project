// Game Decoder
// James Kaden Cassidy 
// kacassidy@hmc.edu
// 11/12/2025

module game_decoder #(
        parameter vga_pkg::vga_params_t params
    )(
        output  logic                           VGA_new_frame_ready,

        input   game_state_pkg::game_state_t    VGA_frame,

        input   logic[params.pixel_x_bits-1:0]  pixel_x_target_next,
        input   logic[params.pixel_y_bits-1:0]  pixel_y_target_next,
        output  logic                           pixel_value_next,

        input   logic                           v_sync
    );

    logic[10:0] x_idx, y_idx;
    logic       boarder;
    logic       game_pixel_value;
    logic       game_pixel;

    // ------------------------------------------------------------
    // Game area geometry
    // ------------------------------------------------------------
    localparam int GAME_X_MIN = 240;
    localparam int GAME_X_MAX = 400;
    localparam int GAME_Y_MIN = 80;
    localparam int GAME_Y_MAX = 400;

    // ------------------------------------------------------------
    // Border controls
    //   BORDER_PAD:     gap between game area and inner edge of border
    //   BORDER_THICK:   thickness of the border ring
    // ------------------------------------------------------------
    localparam int BORDER_PAD   = 4;   // <--- tweak this
    localparam int BORDER_THICK = 10;   // <--- and this

    // Inner edge of the border (closest to the game)
    localparam int BORDER_INNER_X_MIN = GAME_X_MIN - BORDER_PAD;
    localparam int BORDER_INNER_X_MAX = GAME_X_MAX + BORDER_PAD;
    localparam int BORDER_INNER_Y_MIN = GAME_Y_MIN - BORDER_PAD;
    localparam int BORDER_INNER_Y_MAX = GAME_Y_MAX + BORDER_PAD;

    // Outer edge of the border (furthest from the game)
    localparam int BORDER_OUTER_X_MIN = BORDER_INNER_X_MIN - BORDER_THICK;
    localparam int BORDER_OUTER_X_MAX = BORDER_INNER_X_MAX + BORDER_THICK;
    localparam int BORDER_OUTER_Y_MIN = BORDER_INNER_Y_MIN - BORDER_THICK;
    localparam int BORDER_OUTER_Y_MAX = BORDER_INNER_Y_MAX + BORDER_THICK;

    // when vsync goes low to indicate new fame, we allow a new game state to be loaded to display
    assign VGA_new_frame_ready  = ~v_sync;

    assign x_idx                = pixel_x_target_next - GAME_X_MIN;
    assign y_idx                = pixel_y_target_next - GAME_Y_MIN;

    assign game_pixel_value     = VGA_frame.screen[x_idx[params.pixel_x_bits-1:4]][y_idx[params.pixel_x_bits-1:4]];
    assign game_pixel           = pixel_x_target_next >= 240 & pixel_x_target_next < 400
                                & pixel_y_target_next >= 80 & pixel_y_target_next < 400;
    
    assign boarder  =
                                (pixel_x_target_next >= BORDER_OUTER_X_MIN &&
                                pixel_x_target_next <  BORDER_OUTER_X_MAX &&
                                pixel_y_target_next >= BORDER_OUTER_Y_MIN &&
                                pixel_y_target_next <  BORDER_OUTER_Y_MAX) &&
                                !(pixel_x_target_next >= BORDER_INNER_X_MIN &&
                                pixel_x_target_next <  BORDER_INNER_X_MAX &&
                                pixel_y_target_next >= BORDER_INNER_Y_MIN &&
                                pixel_y_target_next <  BORDER_INNER_Y_MAX);

    assign pixel_value_next     = (game_pixel & game_pixel_value) | boarder;

endmodule