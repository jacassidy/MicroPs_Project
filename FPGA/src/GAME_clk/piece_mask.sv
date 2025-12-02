// piece_mask.sv
// Noah Fotenos
// nfotenos@hmc.edu
// 12/1/2025

// Neighborhood sampler: returns a 6x6 window around (piece_x, piece_y)
// with the top-left of the window at (piece_x-1, piece_y-1).
// Any coordinate that falls off-screen is forced to 1.

module piece_mask #(
    parameter int BOARD_WIDTH  = 10,
    parameter int BOARD_HEIGHT = 20
) (
    input  game_state_t                         state,

    // Top-left of screen is (0,0), x right, y down.
    input  logic [$clog2(BOARD_WIDTH) -1:0]     piece_x,
    input  logic [$clog2(BOARD_HEIGHT)-1:0]     piece_y,

    // window[x][y], 0..5 in each dimension
    output logic [5:0][5:0]                     window
);

    // Combinational generation of the 6x6 window
    always_comb begin
        for (int lx = 0; lx < 6; lx++) begin           // local x (0..5)
            for (int ly = 0; ly < 6; ly++) begin       // local y (0..5)
                // World coordinates: start at (piece_x-1, piece_y-1)
                int wx = piece_x + lx - 1;
                int wy = piece_y + ly - 1;

                // If off-screen, force to 1, else sample from state.screen
                if (wx < 0 || wy < 0 ||
                    wx >= BOARD_WIDTH || wy >= BOARD_HEIGHT) begin
                    window[lx][ly] = 1'b1;
                end else begin
                    window[lx][ly] = state.screen[wx][wy];
                end
            end
        end
    end

endmodule
