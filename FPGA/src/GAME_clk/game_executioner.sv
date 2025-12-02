// game_executioner.sv
// James Kaden Cassidy
// kacassidy@hmc.edu
// 12/1/2025

module game_executioner(
        input   logic                           reset,
        input   logic                           move_clk,
        input   logic                           game_clk,

        input   tetris_pkg::command_t           move,
        input   tetris_pkg::active_piece_t      new_piece,

        output  game_state_pkg::game_state_t    GAME_state,

        output  logic [8:0]                     sig1,
        output  logic [8:0]                     sig2,
        output  logic [8:0]                     sig3,
        output  logic [8:0]                     sig4,
        output  logic [8:0]                     sig5,
        output  logic [8:0]                     sig6
    );

    logic floating_piece;
    logic active_piece_toutching;
    logic clearing_line;
    logic no_piece;

    tetris_pkg::active_piece_t      active_piece;

    tetris_pkg::active_piece_grid_t active_piece_grid;
    game_state_pkg::game_state_t    GAME_fixed_state;

    // assign no_piece = ~floating_piece & ~active_piece_toutching;
    flopR #(.WIDTH(1)) No_Piece_flop(.clk(game_clk), .reset, .D(active_piece_toutching), .Q(no_piece));

    // a piece is floating when the active piece is not toutching, unless clearing (no piece is active at this time)
    flopRF #(.WIDTH(1)) Floating_Piece(.clk(game_clk), .reset, .flush(active_piece_toutching), .D(1'b1), .Q(floating_piece));

    piece_land_checker Piece_Land_Chcecker(.no_piece, .active_piece_grid, .GAME_fixed_state, .active_piece_toutching);

    // a new piece is asserted when the line isnt being cleared and thee isnt a floating piece the frame before, once you insert a new piece, you no longer insert a new piece
    assign inset_new_piece = no_piece;

    flopRFS #(.WIDTH(5)) Gravity(.clk(game_clk), .reset, .flush(inset_new_piece | clearing_line), .stall(active_piece_toutching), .D(active_piece.y + 1), .Q(active_piece.y));

    piece_decoder Piece_Decoder(.active_piece, .active_piece_grid);

    //flopRE #(.WIDTH($bits(GAME_fixed_state.screen))) flop_Fixed_State(.clk(game_clk), .reset, .en(active_piece_toutching), .D(GAME_state.screen), .Q(GAME_fixed_state.screen));
	always_ff @(posedge game_clk) begin
		if (reset)  GAME_fixed_state.screen <= game_state_pkg::blank_game_state.screen;
        else if (active_piece_toutching)        
                    GAME_fixed_state.screen <= GAME_state.screen;
	end
	
    flopRE #(.WIDTH($bits({new_piece.x,    new_piece.rotation,     new_piece.piece_type}))) flop_Piece_State(.clk(game_clk), .reset, .en(inset_new_piece), 
                        .D({new_piece.x,    new_piece.rotation,     new_piece.piece_type}), 
                        .Q({active_piece.x, active_piece.rotation,  active_piece.piece_type}));

    blit_piece Blit_Piece(.base_state(GAME_fixed_state), .active_piece_grid, .out_state(GAME_state));

    assign sig1 = active_piece.x;
    assign sig2 = active_piece.y;
    assign sig3 = floating_piece;
    assign sig4 = active_piece_toutching;
    assign sig5 = clearing_line;
    assign sig6 = no_piece;

endmodule
