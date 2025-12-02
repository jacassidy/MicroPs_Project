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

        // 6 sets of debug signals (2ÃƒÆ’Ã¢â‚¬â€8-bit each)
        output  logic [7:0]                         debug_singals_0 [2],
        output  logic [7:0]                         debug_singals_1 [2],
        output  logic [7:0]                         debug_singals_2 [2],
        output  logic [7:0]                         debug_singals_3 [2],
        output  logic [7:0]                         debug_singals_4 [2],
        output  logic [7:0]                         debug_singals_5 [2]
    );

    logic floating_piece;
    logic active_piece_toutching_bottom;
    logic active_piece_toutching_left;
    logic active_piece_toutching_right;
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
        .debug_window_0,
        .debug_window_1,
        .debug_window_2,
        .debug_window_3,
        .debug_window_4,
        .debug_window_5,

        // 6 sets of debug signals (2Ãƒâ€”8-bit each)
        .debug_singals_0,
        .debug_singals_1,
        .debug_singals_2,
        .debug_singals_3,
        .debug_singals_4,
        .debug_singals_5
    );

    flopR #(.WIDTH(1)) No_Piece_flop(.clk(game_clk), .reset, .D(active_piece_toutching_bottom), .Q(no_piece));

    // a piece is floating when the active piece is not toutching, unless clearing (no piece is active at this time)
    flopRF #(.WIDTH(1)) Floating_Piece(.clk(game_clk), .reset, .flush(active_piece_toutching_bottom), .D(1'b1), .Q(floating_piece));

    // a new piece is asserted when the line isnt being cleared and thee isnt a floating piece the frame before, once you insert a new piece, you no longer insert a new piece
    assign inset_new_piece = no_piece;

    flopRFS #(.WIDTH(5)) Gravity(.clk(game_clk), .reset, .flush(inset_new_piece | clearing_line), .stall(active_piece_toutching_bottom), 
                                .D(active_piece.y + 1), .Q(active_piece.y));

    piece_decoder Piece_Decoder(.active_piece, .active_piece_grid);

	always_ff @(posedge game_clk) begin
		if (reset)  GAME_fixed_state.screen <= game_state_pkg::blank_game_state.screen;
        else if (active_piece_toutching_bottom)        
                    GAME_fixed_state.screen <= GAME_state.screen;
	end
	
    flopRE #(.WIDTH($bits({new_piece.rotation,     new_piece.piece_type}))) flop_Piece_State(.clk(game_clk), .reset, .en(inset_new_piece), 
                        .D({new_piece.rotation,     new_piece.piece_type}), 
                        .Q({active_piece.rotation,  active_piece.piece_type}));

    logic stall_move_clk;

    synchronizer Mv_clk_delay(.clk(clk), .raw_input(move_clk), .synchronized_value(stall_move_clk));

    always_ff @(posedge stall_move_clk) begin // TODO x being reset to early since stall move clk is based off spi transactions
        if (reset | inset_new_piece) active_piece.x <= new_piece.x;
        else begin
            if (move_valid) begin
                if (~active_piece_toutching_left  & move == tetris_pkg::CMD_LEFT)  active_piece.x <= active_piece.x - 1;
                if (~active_piece_toutching_right & move == tetris_pkg::CMD_RIGHT) active_piece.x <= active_piece.x + 1;
            end
        end
    end

    blit_piece Blit_Piece(.base_state(GAME_fixed_state), .active_piece_grid, .out_state(GAME_state));

endmodule
