// State Manager
// James Kaden Cassidy 
// kacassidy@hmc.edu
// 11/12/2025

module state_manager (
        input   logic                           reset,
        input   logic                           VGA_new_frame_ready,
        input   logic                           GAME_new_frame_ready,

        input   game_state_pkg::game_state_t    GAME_next_frame,
        output  game_state_pkg::game_state_t    VGA_frame
    );

    game_state_pkg::game_state_t current_game_state, next_game_state;
    
    // Change game state when new game frame and new VGA frame is ready
    always_ff @(posedge (VGA_new_frame_ready & GAME_new_frame_ready) or posedge reset) begin 
        if(reset)   current_game_state <= game_state_pkg::blank_game_state;
        else        current_game_state <= next_game_state;
    end

    assign next_game_state  = GAME_next_frame;
    assign VGA_frame        = current_game_state;


endmodule