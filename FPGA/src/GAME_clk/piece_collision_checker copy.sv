// piece_land_checker.sv
// James Kaden Cassidy
// kacassidy@hmc.edu
// 12/1/2025

module piece_collision_checker #(parameter FIXED_STATE_WIDTH = 10, parameter FIXED_STATE_HEIGHT = 20, parameter GRID = 4)(
        input   logic                                   no_piece,
        input   logic [GRID-1:0]                        active_piece_grid_piece[GRID-1:0],
        input   logic [$clog2(FIXED_STATE_HEIGHT)-1:0]  piece_y,
        input   logic [$clog2(FIXED_STATE_WIDTH)-1:0]   piece_x,
        input   logic [FIXED_STATE_HEIGHT-1:0]          GAME_fixed_state_screen [FIXED_STATE_WIDTH-1:0],
        output  logic                                   active_piece_toutching
    );

    localparam int BOARD_WIDTH   = FIXED_STATE_WIDTH;
    localparam int BOARD_HEIGHT  = FIXED_STATE_HEIGHT;
    localparam int GRID_SIZE     = GRID;

    // ----- MSB for all fixed columns (GAME_fixed_state) -----
    logic [$clog2(BOARD_HEIGHT)-1:0] fixed_lsb_idx [BOARD_WIDTH];
    //logic                            fixed_valid   [BOARD_WIDTH];

    genvar fx;
    generate
        for (fx = 0; fx < BOARD_WIDTH; fx++) begin : gen_fixed_msb
            lsb_index #(
                .WIDTH(BOARD_HEIGHT)
            ) u_fixed_msb (
                .in   (GAME_fixed_state_screen[fx]),  // screen[fx][19:0]
                .idx  (fixed_lsb_idx[fx])            // y of TOP-most filled cell
                //.valid(fixed_valid[fx])               // 1 if any bit set
            );
        end
    endgenerate

    // ----- MSB for each of the 4 piece-grid columns (bottom-most block) -----
    logic [$clog2(GRID_SIZE)-1:0] piece_bottom_idx [GRID_SIZE];  // 0..3
    logic                         piece_col_valid   [GRID_SIZE];

    genvar px;
    generate
        for (px = 0; px < GRID_SIZE; px++) begin : gen_piece_msb

            msb_index #(
                .WIDTH(GRID_SIZE)
            ) u_piece_msb (
                .in   (active_piece_grid_piece[px]),
                .idx  (piece_bottom_idx[px]),    // bottom-most local row index (0..3)
                .valid(piece_col_valid[px])      // 1 if this piece column has any block
            );
        end
    endgenerate

    // ------------------------------------------------------------
    // Collision / landing detection (combinational)
    // Using sum: piece_y_from_top + h_piece_col + h_fixed_col > 20
    // for any valid piece column.
    // ------------------------------------------------------------

    logic [$clog2(BOARD_HEIGHT)-1:0] piece_y_from_top, h_piece_col, h_fixed_col, sum;

    // want to ensure no wrap around
    logic [$clog2(BOARD_WIDTH)-1:0] checking_index;

    logic [8:0] signals [3:0];

    always_comb begin
        active_piece_toutching  = 1'b0;
        piece_y_from_top        = piece_y;
        for (logic[$clog2(GRID_SIZE):0] x = 0; x < GRID_SIZE; x++) begin
            checking_index = piece_x + x;

            h_piece_col     = piece_bottom_idx[x];
            h_fixed_col     = BOARD_HEIGHT-fixed_lsb_idx[checking_index];

            sum = piece_y_from_top + h_piece_col + h_fixed_col;

            signals[x] = sum;

            if (sum == BOARD_HEIGHT-1 & piece_col_valid[x]) begin // TODO should invalidate if piece is below lowest piece
                active_piece_toutching = 1'b1;
            end
        end
        active_piece_toutching = active_piece_toutching & ~no_piece;
    end

endmodule
