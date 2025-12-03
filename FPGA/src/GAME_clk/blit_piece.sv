// tetris_pkg.sv
// Noah Fotenos
// nfotenos@hmc.edu
// 12/1/2025

module blit_piece (
    input   logic                           no_piece,
    input  game_state_pkg::game_state_t     base_state,
    input  tetris_pkg::active_piece_grid_t  active_piece_grid,
    output game_state_pkg::game_state_t     out_state
);
    import game_state_pkg::*;
    import tetris_pkg::*;

    always_comb begin : overlay_active_piece_comb

        int bx, dx, dy, by;
        // Start from the base (locked) board
        out_state = base_state;

        // For each *column* of the 4x4 piece grid
        for (dx = 0; dx < 4; dx++) begin
            bx = active_piece_grid.x + dx - 4;

            // If this column is on-screen horizontally
            if (bx >= 0 && bx < 10) begin
                logic [19:0] column_mask;
                column_mask = '0;

                // Build a 20-bit mask for this one board column
                for (dy = 0; dy < 4; dy++) begin
                    if (active_piece_grid.piece[dx][dy]) begin
                        by = active_piece_grid.y + dy - 4;

                        // If this row is on-screen vertically
                        if (by >= 0 && by < 20) begin
                            column_mask[by] = 1'b1;
                        end
                    end
                end

                // OR the piece pixels into just this column
                out_state.screen[bx] = base_state.screen[bx] | (~no_piece & column_mask);
            end
        end
    end

endmodule
