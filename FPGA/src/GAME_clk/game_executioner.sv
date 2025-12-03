// game_executioner.sv
// James Kaden Cassidy
// kacassidy@hmc.edu
// 12/1/2025

//`include "parameters.svh"
`define COLORS 3

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

        // 6 sets of debug signals (2ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â8-bit each)
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

        // 6 sets of debug signals (2ÃƒÆ’Ã¢â‚¬â€8-bit each)
        .debug_singals_0,
        .debug_singals_1,
        .debug_singals_2,
        .debug_singals_3,
        .debug_singals_4(),
        .debug_singals_5()
    );

    flopR #(.WIDTH(1)) No_Piece_flop(.clk(game_clk), .reset, .D(active_piece_toutching_bottom), .Q(no_piece));

    // a piece is floating when the active piece is not toutching, unless clearing (no piece is active at this time)
    flopRF #(.WIDTH(1)) Floating_Piece(.clk(game_clk), .reset, .flush(active_piece_toutching_bottom), .D(1'b1), .Q(floating_piece));

    // a new piece is asserted when the line isnt being cleared and thee isnt a floating piece the frame before, once you insert a new piece, you no longer insert a new piece
    assign insert_new_piece = no_piece;

    flopRFS #(.WIDTH(5)) Gravity(.clk(game_clk), .reset, .flush(insert_new_piece | clearing_line), .stall(active_piece_toutching_bottom), 
                                .D(active_piece.y + 1), .Q(active_piece.y));

    piece_decoder Piece_Decoder(.active_piece, .active_piece_grid);

	always_ff @(posedge game_clk) begin
		if (reset)  GAME_fixed_state.screen <= game_state_pkg::blank_game_state.screen;
        else if (active_piece_toutching_bottom)        
                    GAME_fixed_state.screen <= GAME_state.screen;
	end
	
    flopRE #(.WIDTH($bits({new_piece.piece_type}))) flop_Piece_State(.clk(game_clk), .reset, .en(insert_new_piece), 
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

    blit_piece Blit_Piece(.base_state(GAME_fixed_state), .active_piece_grid, .out_state(GAME_state));

    assign debug_singals_4[0] = {1'(move_valid), 1'(move == tetris_pkg::CMD_LEFT), 1'(move == tetris_pkg::CMD_RIGHT), 1'(move == tetris_pkg::CMD_ROTATE)};
    assign debug_singals_4[1] = count;

    assign debug_singals_5[0] = {1'(game_clk_posedge_stalled), 1'(insert_new_piece), 1'(game_clk_posedge_stalled)};


endmodule
