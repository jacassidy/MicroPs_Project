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

    // Assume: game_state_t is
    // typedef struct {
    //   logic [19:0] screen [9:0];  // screen[x][y]
    // } game_state_t;

    always_comb begin : overlay_active_piece_comb
        // Start from the base (locked) board
        out_state = base_state;

        // For each *column* of the 4x4 piece grid
        for (int dx = 0; dx < 4; dx++) begin
            int bx = active_piece_grid.x + dx;

            // If this column is on-screen horizontally
            if (bx >= 0 && bx < 10) begin
                logic [19:0] column_mask;
                column_mask = '0;

                // Build a 20-bit mask for this one board column
                for (int dy = 0; dy < 4; dy++) begin
                    if (active_piece_grid.piece[dx][dy]) begin
                        int by = active_piece_grid.y + dy;

                        // If this row is on-screen vertically
                        if (by >= 0 && by < 20) begin
                            column_mask[by] = 1'b1;
                        end
                    end
                end

                // OR the piece pixels into just this column
                out_state.screen[bx] = base_state.screen[bx] | column_mask;
            end
        end
    end

endmodule
