// piece_land_checker.sv
// James Kaden Cassidy
// kacassidy@hmc.edu
// 12/1/2025

module piece_land_checker(
        input   logic                               no_piece,
        input   tetris_pkg::active_piece_grid_t     active_piece_grid,
        input   game_state_pkg::game_state_t        GAME_fixed_state,
        output  logic                               active_piece_toutching,

        output  logic [8:0]                     sig3,
        output  logic [8:0]                     sig4,
        output  logic [8:0]                     sig5,
        output  logic [8:0]                     sig6
    );

    localparam int BOARD_WIDTH   = 10;
    localparam int BOARD_HEIGHT  = 20;
    localparam int GRID_SIZE     = 4;

    // Per-column heights of the fixed game from the BOTTOM (0..20)
    game_state_pkg::fixed_game_state_heights_t heights;

    // ----- MSB for all fixed columns (GAME_fixed_state) -----
    logic [$clog2(BOARD_HEIGHT)-1:0] fixed_lsb_idx [BOARD_WIDTH];
    //logic                            fixed_valid   [BOARD_WIDTH];

    genvar fx;
    generate
        for (fx = 0; fx < BOARD_WIDTH; fx++) begin : gen_fixed_msb
            lsb_index #(
                .WIDTH(BOARD_HEIGHT)
            ) u_fixed_msb (
                .in   (GAME_fixed_state.screen[fx]),  // screen[fx][19:0]
                .idx  (fixed_lsb_idx[fx])            // y of TOP-most filled cell
                //.valid(fixed_valid[fx])               // 1 if any bit set
            );
        end
    endgenerate

    // ----- MSB for each of the 4 piece-grid columns (bottom-most block) -----
    logic [GRID_SIZE-1:0] piece_col_bits_flipped [GRID_SIZE];
    logic [$clog2(GRID_SIZE)-1:0] piece_bottom_idx [GRID_SIZE];  // 0..3
    logic                         piece_col_valid   [GRID_SIZE];

    genvar px;
    generate
        for (px = 0; px < GRID_SIZE; px++) begin : gen_piece_msb

            msb_index #(
                .WIDTH(GRID_SIZE)
            ) u_piece_msb (
                .in   (active_piece_grid.piece[px]),
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
        piece_y_from_top        = active_piece_grid.y;
        for (logic[$clog2(GRID_SIZE):0] x = 0; x < GRID_SIZE; x++) begin
            checking_index = active_piece_grid.x + x;

            h_piece_col     = piece_bottom_idx[x];
            h_fixed_col     = 20-fixed_lsb_idx[checking_index];

            sum = piece_y_from_top + h_piece_col + h_fixed_col;

            signals[x] = sum;

            // sig3 = sum;
            // sig4 = piece_y_from_top;
            // sig5 = h_piece_col;
            // sig6 = h_fixed_col;

            if (sum >= BOARD_HEIGHT-1 & piece_col_valid[x]) begin //piece_col_valid[x] & fixed_valid[checking_index]
                active_piece_toutching = 1'b1;
            end
        end
        active_piece_toutching = active_piece_toutching & ~no_piece;
    end

    assign sig3 = signals[0];
    assign sig4 = signals[1];
    assign sig5 = signals[2];
    assign sig6 = signals[3];

endmodule
