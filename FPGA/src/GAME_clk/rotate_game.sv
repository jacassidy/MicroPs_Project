// rotate_game.sv
// James Kaden Cassidy
// kacassidy@hmc.edu
// 12/1/2025

// rotate.sv
//
// Rotate the active 4x4 piece grid and the fixed game state
//  - 90° counterclockwise (CCW)
//  - 90° clockwise (CW)
//
// Coordinate convention:
//   (0,0) is top-left, x increases to the right, y increases downward.
//
// Board dimensions (original):
//   FIXED_STATE_WIDTH_IN  = board width  (e.g., 10)
//   FIXED_STATE_HEIGHT_IN = board height (e.g., 20)
//
// After a 90° rotation, dimensions swap:
//   width_out  = FIXED_STATE_HEIGHT_IN
//   height_out = FIXED_STATE_WIDTH_IN
//
// Types from your packages:
//
//   typedef struct {
//     logic  [3:0]  piece [3:0]; // piece[x][y], 0..3
//     logic  [3:0]  x;           // 0..9  (board columns, top-left of 4x4)
//     logic  [4:0]  y;           // 0..19 (board rows, top-left of 4x4)
//   } active_piece_grid_t;
//
//   typedef struct {
//     // screen[x][y] : 20 rows, each 10 bits wide
//     logic [19:0] screen [9:0]; // screen[x][y], x=0..9, y=0..19
//   } game_state_t;

module rotate_game #(
    parameter int GRID                 = 4,
    // Original board dimensions
    parameter int FIXED_STATE_WIDTH_IN  = 10,  // columns
    parameter int FIXED_STATE_HEIGHT_IN = 20   // rows
) (
    // Struct inputs
    input  tetris_pkg::active_piece_grid_t active_piece_grid,
    input  game_state_pkg::game_state_t    GAME_fixed_state,

    // -----------------------------
    // Rotated piece grids (4x4)
    // -----------------------------
    // CCW 90°: piece_ccw[x][y]
    output logic [GRID-1:0] active_piece_grid_piece_ccw [GRID-1:0],
    // CW 90°: piece_cw[x][y]
    output logic [GRID-1:0] active_piece_grid_piece_cw  [GRID-1:0],

    // -----------------------------
    // Rotated piece positions
    // (top-left of 4×4 bounding box
    // in the rotated board coords)
    // -----------------------------
    // After rotation, board dims swap:
    //   width_out  = FIXED_STATE_HEIGHT_IN
    //   height_out = FIXED_STATE_WIDTH_IN
    //
    // So:
    //   piece_x_* in [0 .. width_out-1]
    //   piece_y_* in [0 .. height_out-1]
    output logic [$clog2(FIXED_STATE_HEIGHT_IN)-1:0] piece_x_ccw,
    output logic [$clog2(FIXED_STATE_WIDTH_IN) -1:0] piece_y_ccw,

    output logic [$clog2(FIXED_STATE_HEIGHT_IN)-1:0] piece_x_cw,
    output  logic[$clog2(FIXED_STATE_WIDTH_IN) -1:0] piece_y_cw,

    // -----------------------------
    // Rotated fixed game state
    // -----------------------------
    // Output board dimensions:
    //   width_out  = FIXED_STATE_HEIGHT_IN
    //   height_out = FIXED_STATE_WIDTH_IN
    //
    // screen_rot[x'][y'] with:
    //   x' = 0 .. width_out-1
    //   y' = 0 .. height_out-1
    output logic [FIXED_STATE_WIDTH_IN -1:0] GAME_fixed_state_screen_ccw [FIXED_STATE_HEIGHT_IN-1:0],
    output logic [FIXED_STATE_WIDTH_IN -1:0] GAME_fixed_state_screen_cw  [FIXED_STATE_HEIGHT_IN-1:0]
);

    // For readability
    localparam int BOARD_W_IN = FIXED_STATE_WIDTH_IN;   // original width
    localparam int BOARD_H_IN = FIXED_STATE_HEIGHT_IN;  // original height

    // ------------------------------------------------------------
    // Piece position rotation (top-left of 4×4 bounding box)
    //
    // Using rotation about (0,0) with (0,0) as top-left:
    //
    // Original coords: (px, py)
    //   px in [0 .. BOARD_W_IN - GRID]
    //   py in [0 .. BOARD_H_IN - GRID]
    //
    // CW 90°:
    //   new_x_cw = BOARD_H_IN - GRID - py
    //   new_y_cw = px
    //
    // CCW 90°:
    //   new_x_ccw = py
    //   new_y_ccw = BOARD_W_IN - GRID - px
    //
    // After rotation, board dims are:
    //   width_out  = BOARD_H_IN
    //   height_out = BOARD_W_IN
    // so these ranges are valid:
    //   0 <= new_x_* < BOARD_H_IN
    //   0 <= new_y_* < BOARD_W_IN
    // ------------------------------------------------------------

    always_comb begin
        // Piece positions
        piece_x_cw  = BOARD_H_IN - GRID - active_piece_grid.y;
        piece_y_cw  = active_piece_grid.x;

        piece_x_ccw = active_piece_grid.y;
        piece_y_ccw = BOARD_W_IN - GRID - active_piece_grid.x;
    end

    // ------------------------------------------------------------
    // Rotate 4×4 piece grid
    //
    // active_piece_grid.piece[x][y] with:
    //   x = 0..GRID-1 (columns)
    //   y = 0..GRID-1 (rows, top to bottom)
    //
    // 90° CCW:
    //   new_x =  y
    //   new_y =  GRID-1 - x
    // Inverse (to fill new from old):
    //   old_x = GRID-1 - new_y
    //   old_y = new_x
    //
    // 90° CW:
    //   new_x =  GRID-1 - y
    //   new_y =  x
    // Inverse:
    //   old_x = new_y
    //   old_y = GRID-1 - new_x
    // ------------------------------------------------------------

    genvar gx_new, gy_new;
    generate
        for (gx_new = 0; gx_new < GRID; gx_new++) begin : gen_piece_x
            for (gy_new = 0; gy_new < GRID; gy_new++) begin : gen_piece_y
                // CCW mapping
                localparam int OLD_X_CCW = GRID-1 - gy_new;
                localparam int OLD_Y_CCW = gx_new;

                // CW mapping
                localparam int OLD_X_CW  = gy_new;
                localparam int OLD_Y_CW  = GRID-1 - gx_new;

                // Assign rotated bits
                assign active_piece_grid_piece_ccw[gx_new][gy_new] =
                    active_piece_grid.piece[OLD_X_CCW][OLD_Y_CCW];

                assign active_piece_grid_piece_cw[gx_new][gy_new]  =
                    active_piece_grid.piece[OLD_X_CW][OLD_Y_CW];
            end
        end
    endgenerate

    // ------------------------------------------------------------
    // Rotate fixed game state
    //
    // Original:
    //   GAME_fixed_state.screen[x][y]
    //     x in [0 .. BOARD_W_IN-1]
    //     y in [0 .. BOARD_H_IN-1]
    //
    // After rotation, we want:
    //   GAME_fixed_state_screen_*[x'][y']
    //     x' in [0 .. BOARD_H_IN-1]  (width_out)
    //     y' in [0 .. BOARD_W_IN-1]  (height_out)
    //
    // 90° CCW (new from old):
    //   new_x =  y
    //   new_y =  BOARD_W_IN - 1 - x
    // Inverse (for coding new[x'][y'] = old[...]):
    //   old_x = BOARD_W_IN - 1 - new_y
    //   old_y = new_x
    //
    // 90° CW:
    //   new_x =  BOARD_H_IN - 1 - y
    //   new_y =  x
    // Inverse:
    //   old_x = new_y
    //   old_y = BOARD_H_IN - 1 - new_x
    // ------------------------------------------------------------

    genvar bx_new, by_new;
    generate
        for (bx_new = 0; bx_new < BOARD_H_IN; bx_new++) begin : gen_board_x
            for (by_new = 0; by_new < BOARD_W_IN; by_new++) begin : gen_board_y
                // CCW mapping
                localparam int OLD_X_CCW_BOARD = BOARD_W_IN - 1 - by_new;
                localparam int OLD_Y_CCW_BOARD = bx_new;

                // CW mapping
                localparam int OLD_X_CW_BOARD  = by_new;
                localparam int OLD_Y_CW_BOARD  = BOARD_H_IN - 1 - bx_new;

                assign GAME_fixed_state_screen_ccw[bx_new][by_new] =
                    GAME_fixed_state.screen[OLD_X_CCW_BOARD][OLD_Y_CCW_BOARD];

                assign GAME_fixed_state_screen_cw[bx_new][by_new]  =
                    GAME_fixed_state.screen[OLD_X_CW_BOARD][OLD_Y_CW_BOARD];
            end
        end
    endgenerate

endmodule
