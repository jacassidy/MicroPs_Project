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

    );

    logic floating_piece;
    logic active_piece_toutching;
    logic clearing_line;
    logic inset_new_piece;

    tetris_pkg::active_piece_grid_t active_piece_grid;
    game_state_pkg::game_state_t    GAME_fixed_state;

    // a piece is floating when the active piece is not toutching, unless clearing (no piece is active at this time)
    flopRFS #(WIDTH = 1) Floating_Piece(.clk(game_clk), .reset, .stall(clearing_line), .D(~active_piece_toutching), .Q(floating_piece));

    piece_land_checker Piece_Land_Chcecker(.active_piece_grid, .GAME_fixed_state, .active_piece_toutching);

    // a new piece is asserted when the line isnt being cleared and thee isnt a floating piece the frame before, once you insert a new piece, you no longer insert a new piece
    flopRF #(WIDTH = 1) New_Piece(.clk(game_clk), .reset, .flush(inset_new_piece), .D(~floating_piece & ~clearing_line), .Q(inset_new_piece));






    


endmodule
