
// tetris_pkg.sv
// Noah Fotenos
// nfotenos@hmc.edu
// 12/1/2025

module blit_piece (
    input  game_state_pkg::game_state_t     base_state,
    input  tetris_pkg::active_piece_grid_t  active_piece_grid,
    output game_state_pkg::game_state_t     out_state
);
    import game_state_pkg::*;
    import tetris_pkg::*;

    // Loop indices
    logic[4:0] dx, dy;
    logic[4:0] bx, by;

    always_comb begin : overlay_active_piece_comb
        // Start from the base (locked) board
        out_state = base_state;

        // For each cell in the 4x4 piece grid
        for (dy = 0; dy < 4; dy++) begin
            for (dx = 0; dx < 4; dx++) begin
                // Assume active_piece_grid.piece[dx][dy] == 1 means block present
                if (active_piece_grid.piece[dx][dy]) begin
                    // Compute board coordinates from top-left origin
                    bx = active_piece_grid.x + dx;
                    by = active_piece_grid.y + dy;

                    // Bounds check
                    if (bx >= 0 && bx < 10 && by >= 0 && by < 20) begin
                        // screen[x][y] is bit y of column x
                        out_state.screen[bx][by] = 1'b1;
                    end
                end
            end
        end
    end

endmodule
