// piece_mask_generator.sv
// Noah Fotenos
// nfotenos@hmc.edu
// 12/1/2025

// Neighborhood sampler: returns a 6x6 window around (piece_x, piece_y)
// with the top-left of the window at (piece_x-1, piece_y-1).
// Any coordinate that falls off-screen is forced to 1.

module piece_mask_generator #(
    parameter int BOARD_WIDTH  = 10,
    parameter int BOARD_HEIGHT = 20
) (
    input  game_state_pkg::game_state_t         state,

    // Top-left of screen is (0,0), x right, y down.
    input  logic [$clog2(BOARD_WIDTH) -1:0]     piece_x,
    input  logic [$clog2(BOARD_HEIGHT)-1:0]     piece_y,

    // window[x][y], 0..5 in each dimension
    // window[lx][ly]: 6 columns, each 6 bits tall
    output logic [5:0]                          window [5:0]
);
    import game_state_pkg::*;

    always_comb begin

        int lx, wx, ly, wy;
        // Default everything to "off-screen" = 1
        for (lx = 0; lx < 6; lx++) begin
            window[lx] = 6'b111111;
        end

        // For each *column* of the 6x6 window
        for (lx = 0; lx < 6; lx++) begin
            wx = piece_x + lx - 1;  // world x

            // If this column is horizontally in-bounds
            if (wx >= 0 && wx < BOARD_WIDTH) begin
                logic [5:0] col_bits;
                col_bits = 6'b111111;   // default "off-screen" vertically too

                // Now walk the 6 vertical positions for this column
                for (ly = 0; ly < 6; ly++) begin
                    wy = piece_y + ly - 1;  // world y

                    // If vertically on-screen, sample from state
                    if (wy >= 0 && wy < BOARD_HEIGHT) begin
                        // state.screen[wx] is a BOARD_HEIGHT-bit column
                        col_bits[ly] = state.screen[wx][wy];
                    end
                    // else: leave as 1 (off-screen)
                end

                // Assign this 6-bit column into the window
                window[lx] = col_bits;
            end
            // else: window[lx] already 6'b111111 from the default pass
        end
    end

endmodule

