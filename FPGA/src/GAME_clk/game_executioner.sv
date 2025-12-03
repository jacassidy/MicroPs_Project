// game_executioner.sv
// James Kaden Cassidy
// kacassidy@hmc.edu
// 12/1/2025

//`include "parameters.svh"
`define COLORS 3

localparam int BOARD_WIDTH  = 10;
localparam int BOARD_HEIGHT = 20;

module game_executioner #(
    parameter int                                   TELEMETRY_NUM_SIGNALS,    
    parameter int                                   TELEMETRY_VALUE_WIDTH,
    parameter int                                   TELEMETRY_BASE
)(
        input   logic                               reset,
        input   logic                               clk,
        input   logic                               move_clk,
        input   logic                               move_valid,
        input   logic                               game_clk,

        input   tetris_pkg::command_t               move,
        input   tetris_pkg::active_piece_t          new_piece,

        output  game_state_pkg::game_state_t        GAME_state,

        // 6 debug windows, each 3-color 6x6
        output  logic [5:0]                         debug_window_0 [`COLORS][5:0],
        output  logic [5:0]                         debug_window_1 [`COLORS][5:0],
        output  logic [5:0]                         debug_window_2 [`COLORS][5:0],
        output  logic [5:0]                         debug_window_3 [`COLORS][5:0],
        output  logic [5:0]                         debug_window_4 [`COLORS][5:0],
        output  logic [5:0]                         debug_window_5 [`COLORS][5:0],

        // 6 sets of debug signals (2ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â8-bit each)
        output  logic [7:0]                         debug_singals_0 [2],
        output  logic [7:0]                         debug_singals_1 [2],
        output  logic [7:0]                         debug_singals_2 [2],
        output  logic [7:0]                         debug_singals_3 [2],
        output  logic [7:0]                         debug_singals_4 [2],
        output  logic [7:0]                         debug_singals_5 [2]
    );

    logic [7:0] count;

    logic floating_piece;
    logic active_piece_toutching_bottom;
    logic active_piece_toutching_left;
    logic active_piece_toutching_right;
    logic rotation_blocked;
    logic clearing_line;
    logic no_piece;

    // assign active_piece_toutching_left = 1'b0;
    // assign active_piece_toutching_right = 1'b0;

    tetris_pkg::active_piece_t      active_piece;

    tetris_pkg::active_piece_grid_t active_piece_grid;
    game_state_pkg::game_state_t    GAME_fixed_state;


    piece_collision_checker Piece_Collision_Checker(
        .no_piece,
        .GAME_fixed_state,
        .piece_x(active_piece.x),
        .piece_y(active_piece.y),
        .piece_grid(active_piece_grid.piece),
        .left_collision(active_piece_toutching_left),
        .right_collision(active_piece_toutching_right),
        .down_collision(active_piece_toutching_bottom),
        .rotation_collision(rotation_blocked),
        .debug_window_0,
        .debug_window_1,
        .debug_window_2,
        .debug_window_3,
        .debug_window_4,
        .debug_window_5,

        // 6 sets of debug signals (2ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â8-bit each)
        .debug_singals_0,
        .debug_singals_1,
        .debug_singals_2,
        .debug_singals_3,
        .debug_singals_4(),
        .debug_singals_5()
    );

    flopR_2clk #(.WIDTH(1)) No_Piece_flop(.clk_tree(clk), .target_clk(game_clk), .reset, .D(active_piece_toutching_bottom), .Q(no_piece));

    // a piece is floating when the active piece is not toutching, unless clearing (no piece is active at this time)
    flopRF_2clk #(.WIDTH(1)) Floating_Piece(.clk_tree(clk), .target_clk(game_clk), .reset, .flush(active_piece_toutching_bottom), .D(1'b1), .Q(floating_piece));

    // a new piece is asserted when the line isnt being cleared and thee isnt a floating piece the frame before, once you insert a new piece, you no longer insert a new piece
    assign insert_new_piece = no_piece;

    flopRFS_2clk #(.WIDTH(5)) Gravity(.clk_tree(clk), .target_clk(game_clk), .reset, .flush(insert_new_piece | clearing_line), .stall(active_piece_toutching_bottom), 
                                .D(active_piece.y + 1), .Q(active_piece.y));

    piece_decoder Piece_Decoder(.active_piece, .active_piece_grid);

    // Next-state for the fixed board and line-clear flag
    logic                         row_full      [BOARD_HEIGHT];
    logic                         any_full_row;
    int                           clear_y;          // index of bottom-most full row
    logic                         clearing_line_next;
    game_state_pkg::game_state_t  fixed_state_next;

    // Combinational "next" logic for line clear
    always_comb begin
        logic full;
        // 1) Compute which rows are full (AND across x)
        for (int y = 0; y < BOARD_HEIGHT; y++) begin
            full = 1'b1;
            for (int x = 0; x < BOARD_WIDTH; x++) begin
                full &= GAME_state.screen[x][y];
            end
            row_full[y] = full;
        end

        // 2) Find bottom-most full row (if any)
        any_full_row = 1'b0;
        clear_y      = 0;
        for (int y = 0; y < BOARD_HEIGHT; y++) begin
            if (row_full[y]) begin
                any_full_row = 1'b1; // keep true once set
                clear_y      = y;                  // last one wins => bottom-most
            end
        end

        // 3) Default: just lock the board as-is, no clear
        fixed_state_next      = GAME_state;
        clearing_line_next    = 1'b0;

        // 4) If we found a full row, clear *one* line (bottom-most) and
        //    shift everything above it down by 1. Rows below are unchanged.
        if (any_full_row) begin
            clearing_line_next = 1'b1;

            for (int y = 0; y < BOARD_HEIGHT; y++) begin
                for (int x = 0; x < BOARD_WIDTH; x++) begin
                    if (y == 0 && y <= clear_y) begin
                        // Top row becomes empty whenever we clear a row
                        fixed_state_next.screen[x][y] = 1'b0;
                    end else if (y <= clear_y) begin
                        // Rows 1..clear_y each take the row directly above
                        fixed_state_next.screen[x][y] = GAME_state.screen[x][y-1];
                    end else begin
                        // Rows below the cleared line (y > clear_y) stay the same
                        fixed_state_next.screen[x][y] = GAME_state.screen[x][y];
                    end
                end
            end
        end
    end

    // clearing_line should be declared as a reg/logic somewhere:
    // output logic clearing_line;

    // Single flop updated with either a pure lock or the cleared version

    logic game_clk_meta, game_clk_sync, game_clk_sync_d;
    logic game_clk_rise;

    // Sync game_clk into clk domain and detect rising edges
    always_ff @(posedge clk) begin
        if (reset) begin
            game_clk_meta   <= 1'b0;
            game_clk_sync   <= 1'b0;
            game_clk_sync_d <= 1'b0;
        end else begin
            game_clk_meta   <= game_clk;       // 1st stage
            game_clk_sync   <= game_clk_meta;  // 2nd stage
            game_clk_sync_d <= game_clk_sync;  // delayed copy
        end
    end

    assign game_clk_rise = game_clk_sync & ~game_clk_sync_d;

    always_ff @(posedge clk) begin
        if (reset) begin
            GAME_fixed_state.screen <= game_state_pkg::blank_game_state.screen;
            clearing_line           <= 1'b0;
        end else if (game_clk_rise) begin
            if (active_piece_toutching_bottom) begin
                GAME_fixed_state.screen <= fixed_state_next.screen;
                clearing_line           <= clearing_line_next;
            end else begin
                // no new piece lock this cycle => no clear pulse
                clearing_line           <= 1'b0;
            end
        end
    end
    // always_ff @(posedge game_clk) begin
    //     if (reset) begin
    //         GAME_fixed_state.screen <= game_state_pkg::blank_game_state.screen;
    //         clearing_line           <= 1'b0;
    //     end else if (active_piece_toutching_bottom) begin
    //         GAME_fixed_state.screen <= fixed_state_next.screen;
    //         clearing_line           <= clearing_line_next;
    //     end else begin
    //         // no new piece lock this cycle => no clear pulse
    //         clearing_line           <= 1'b0;
    //     end
    // end


	// always_ff @(posedge game_clk) begin
	// 	if (reset)  GAME_fixed_state.screen <= game_state_pkg::blank_game_state.screen;
    //     else if (active_piece_toutching_bottom)        
    //                 GAME_fixed_state.screen <= GAME_state.screen;
	// end
	
    flopRE_2clk #(.WIDTH($bits({new_piece.piece_type}))) flop_Piece_State(.clk_tree(clk), .target_clk(game_clk), .reset, .en(insert_new_piece), 
                        .D({new_piece.piece_type}), 
                        .Q({active_piece.piece_type}));

    logic stalled_move_clk;

    synchronizer Mv_clk_delay(.clk(clk), .raw_input(move_clk), .synchronized_value(stalled_move_clk));

    logic game_clk_q, move_clk_q;

    always_ff @(posedge clk) begin
        if (reset) begin
            game_clk_q          <= 1'b0;
            move_clk_q  <= 1'b0;
        end else begin
            game_clk_q          <= game_clk;
            move_clk_q  <= move_clk;
        end
    end

    // One-cycle enables on rising edges (0 -> 1) of the slow "clocks"
    wire game_clk_posedge  =  game_clk & ~game_clk_q;
    wire move_clk_en  =  move_clk & ~move_clk_q;
    logic game_clk_posedge_stalled;

    // ------------------------------------------------------------
    // Single flop for active_piece.x in the clk domain
    // ------------------------------------------------------------
    always_ff @(posedge clk) begin
        if (reset) begin
            active_piece.x <= 4'd4;   // or new_piece.x, your call
            active_piece.rotation <= tetris_pkg::ROT_0;
            count <= '0;
            game_clk_posedge_stalled <= '0;
        end else if (game_clk_posedge & insert_new_piece) begin
            game_clk_posedge_stalled <= 1'b1;
        end else if (game_clk_posedge_stalled & game_clk_posedge) begin
            // Fires only on the cycle where game_clk goes 0->1
            // and insert_new_piece is high in that same cycle
            active_piece.x        <= new_piece.x;
            active_piece.rotation <= new_piece.rotation;
            count <= count + 16;
            game_clk_posedge_stalled <= 1'b0;
        end else if (move_clk_en & move_valid) begin
            count <= count + 1;
            // Fires only on the cycle where stalled_move_clk goes 0->1
            // and move_valid is high
            if      (~active_piece_toutching_left & move == tetris_pkg::CMD_LEFT)       active_piece.x <= active_piece.x - 1;
            else if (~active_piece_toutching_right & move == tetris_pkg::CMD_RIGHT)     active_piece.x <= active_piece.x + 1;
            else if (~rotation_blocked              & move == tetris_pkg::CMD_ROTATE)   begin
                case (active_piece.rotation)
                    tetris_pkg::ROT_0 :  active_piece.rotation <= tetris_pkg::ROT_90;
                    tetris_pkg::ROT_90:  active_piece.rotation <= tetris_pkg::ROT_180;
                    tetris_pkg::ROT_180: active_piece.rotation <= tetris_pkg::ROT_270;
                    tetris_pkg::ROT_270: active_piece.rotation <= tetris_pkg::ROT_0;
                    default:             active_piece.rotation <= tetris_pkg::ROT_90;
                endcase
            end
            //else count <= count - 1;
            // other moves: no change
        end
    end

    blit_piece Blit_Piece(.no_piece, .base_state(GAME_fixed_state), .active_piece_grid, .out_state(GAME_state));

    // // assign telemetry_values[0] = (active_piece.x - 4);
    // // assign telemetry_values[1] = (active_piece.y - 4);

    // // assign telemetry_values[2] = count;
    // // assign telemetry_values[3] = {1'(move_valid), 1'(move == tetris_pkg::CMD_LEFT), 1'(move == tetris_pkg::CMD_RIGHT), 1'(move == tetris_pkg::CMD_ROTATE)};
    
    // assign telemetry_values[0] = {1'(game_clk_posedge_stalled), 1'(insert_new_piece), 1'(game_clk_posedge_stalled)};
    // assign telemetry_values[1] = no_piece;

    // assign telemetry_values[6] = insert_new_piece;


endmodule
