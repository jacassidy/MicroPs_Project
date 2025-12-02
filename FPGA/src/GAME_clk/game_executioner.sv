// game_executioner.sv
// James Kaden Cassidy
// kacassidy@hmc.edu
// 12/1/2025

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

        output  game_state_pkg::game_state_t        GAME_state
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



    // assign no_piece = ~floating_piece & ~active_piece_toutching_bottom;
    flopR #(.WIDTH(1)) No_Piece_flop(.clk(game_clk), .reset, .D(active_piece_toutching_bottom), .Q(no_piece));

    // a piece is floating when the active piece is not toutching, unless clearing (no piece is active at this time)
    flopRF #(.WIDTH(1)) Floating_Piece(.clk(game_clk), .reset, .flush(active_piece_toutching_bottom), .D(1'b1), .Q(floating_piece));

    // piece_land_checker Piece_Land_Chcecker(.no_piece, .active_piece_grid, .GAME_fixed_state, .active_piece_toutching(active_piece_toutching_bottom));

    // rotated game

    localparam int GRID                     = 4;
    localparam int FIXED_STATE_WIDTH_IN     = 10;  // columns
    localparam int FIXED_STATE_HEIGHT_IN    = 20;  // rows

    logic [3:0] active_piece_grid_piece_ccw [3:0];
    logic [3:0] active_piece_grid_piece_cw  [3:0];

    logic [$clog2(FIXED_STATE_HEIGHT_IN)-1:0] piece_x_ccw;
    logic [$clog2(FIXED_STATE_WIDTH_IN) -1:0] piece_y_ccw;

    logic [$clog2(FIXED_STATE_HEIGHT_IN)-1:0] piece_x_cw;
    logic [$clog2(FIXED_STATE_WIDTH_IN) -1:0] piece_y_cw;

    logic [FIXED_STATE_WIDTH_IN -1:0] GAME_fixed_state_screen_ccw [FIXED_STATE_HEIGHT_IN-1:0];
    logic [FIXED_STATE_WIDTH_IN -1:0] GAME_fixed_state_screen_cw  [FIXED_STATE_HEIGHT_IN-1:0];

    // piece_collision_checker #(.FIXED_STATE_WIDTH(20), .FIXED_STATE_HEIGHT(10), .GRID(4)) LEFT_piece_collision_checker(.no_piece, 
    //     .active_piece_grid_piece(active_piece_grid_piece_ccw), .piece_y(piece_y_ccw), .piece_x(piece_x_ccw), 
    //     .GAME_fixed_state_screen(GAME_fixed_state_screen_ccw), .active_piece_toutching(active_piece_toutching_left));

    // piece_collision_checker #(.FIXED_STATE_WIDTH(20), .FIXED_STATE_HEIGHT(10), .GRID(4)) RIGHT_piece_collision_checker(.no_piece, 
    //     .active_piece_grid_piece(active_piece_grid_piece_cw), .piece_y(piece_y_cw), .piece_x(piece_x_cw), 
    //     .GAME_fixed_state_screen(GAME_fixed_state_screen_cw), .active_piece_toutching(active_piece_toutching_right));

    // rotate_game Rotate_Game (.active_piece_grid, .GAME_fixed_state, .active_piece_grid_piece_ccw, .active_piece_grid_piece_cw,
    //     .piece_x_ccw, .piece_y_ccw, .piece_x_cw, .piece_y_cw, .GAME_fixed_state_screen_ccw, .GAME_fixed_state_screen_cw);


    // a new piece is asserted when the line isnt being cleared and thee isnt a floating piece the frame before, once you insert a new piece, you no longer insert a new piece
    assign inset_new_piece = no_piece;

    flopRFS_2clk #(.WIDTH(5)) Gravity(.clk_tree(clk), .target_clk(game_clk), .reset, .flush(inset_new_piece | clearing_line), .stall(active_piece_toutching_bottom), 
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
