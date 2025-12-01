// piece_land_checker.sv
// James Kaden Cassidy
// kacassidy@hmc.edu
// 12/1/2025

module piece_land_checker(
        input  tetris_pkg::active_piece_grid_t   active_piece_grid,
        input  game_state_pkg::game_state_t      GAME_fixed_state,
        output logic                             active_piece_toutching
    );

    // NOTE / ASSUMPTION:
    // - GAME_fixed_state.screen[x] is 20 bits tall: [19:0]
    // - We assume bit 19 corresponds to y = 0 (top row),
    //   and bit 0 corresponds to y = 19 (bottom row).
    //   Thus: board_y = 19 - bit_index.
    //
    // (0,0) is the top-left in board coordinates.

    localparam int BOARD_WIDTH   = 10;
    localparam int BOARD_HEIGHT  = 20;
    localparam int GRID_SIZE     = 4;

    // Per-column top height of the fixed game (in board y-coordinates).
    game_state_pkg::fixed_game_state_heights_t heights;

    // Outputs from msb_index for each column of the fixed game.
    // msb_idx[x]  : bit index of MSB '1' in that column (0..19)
    // col_valid[x]: 1 if any bit in that column is set.
    logic [$clog2(BOARD_HEIGHT)-1:0] msb_idx   [BOARD_WIDTH];
    logic                            col_valid [BOARD_WIDTH];

    // ----------------------------------------------------------------
    // Generate: find the MSB set in each column of GAME_fixed_state
    // ----------------------------------------------------------------
    genvar gx;
    generate
        for (gx = 0; gx < BOARD_WIDTH; gx++) begin : gen_msb_index_per_col
            msb_index #(
                .WIDTH(BOARD_HEIGHT)
            ) u_msb_index (
                .in   (GAME_fixed_state.screen[gx]),
                .idx  (msb_idx[gx]),
                .valid(col_valid[gx])
            );
        end
    endgenerate

    // ----------------------------------------------------------------
    // Combinational logic:
    //  1. Convert MSB indices into board-space heights[ x ] (y-coordinate
    //     of the top-most filled cell in each column, or 20 if empty).
    //  2. For the active piece, check if any bottom-most block in each
    //     occupied column is directly on top of the fixed stack.
    // ----------------------------------------------------------------
    always_comb begin
        // Default: no collision
        active_piece_toutching = 1'b0;

        // 1) Build heights[] from msb_index outputs.
        //
        // If column has any block:
        //   bit_index_top = msb_idx[x]
        //   y_top        = BOARD_HEIGHT-1 - bit_index_top
        // If column empty:
        //   y_top = BOARD_HEIGHT (sentinel meaning "no block")
        for (int x = 0; x < BOARD_WIDTH; x++) begin
            if (col_valid[x]) begin
                // Convert bit index 0..19 to board y = 0..19
                heights.heights[x] = BOARD_HEIGHT - 1 - msb_idx[x];
            end else begin
                // Sentinel: no blocks in this column
                heights.heights[x] = BOARD_HEIGHT; // == 20
            end
        end

        // 2) Collision check:
        //
        // For each local column of the 4x4 piece grid:
        //   - Find the bottom-most '1' in that local column.
        //   - Convert it to world (board) coordinates (world_x, world_y).
        //   - Compute world_y_below = world_y + 1.
        //   - If world_y_below < BOARD_HEIGHT and equals the top height
        //     of the fixed stack in that column, then the piece is
        //     directly sitting on top of a fixed block in that column.
        //
        // That is: there exists a column x where
        //   world_y_below == heights.heights[x]
        // and col_valid[x] == 1.
        for (int local_x = 0; local_x < GRID_SIZE; local_x++) begin
            // Global x position of this local column
            int world_x = active_piece_grid.x + local_x;

            // Skip if off the board horizontally
            if (world_x < 0 || world_x >= BOARD_WIDTH)
                continue;

            // Find bottom-most block in this local piece column.
            int bottom_local_y = -1;
            for (int local_y = GRID_SIZE-1; local_y >= 0; local_y--) begin
                if (active_piece_grid.piece[local_y][local_x]) begin
                    bottom_local_y = local_y;
                    break;
                end
            end

            // If no blocks in this local column, move on.
            if (bottom_local_y < 0)
                continue;

            // Convert to world coordinates
            int world_y       = active_piece_grid.y + bottom_local_y;
            int world_y_below = world_y + 1;

            // Only care about cells that are still on the board.
            if (world_y_below < BOARD_HEIGHT) begin
                if (col_valid[world_x] &&
                    heights.heights[world_x] == world_y_below[5:0]) begin
                    active_piece_toutching = 1'b1;
                end
            end
        end
    end

endmodule
