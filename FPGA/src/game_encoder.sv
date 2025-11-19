// Game Encoder
// James Kaden Cassidy 
// kacassidy@hmc.edu
// 11/12/2025

module game_encoder (
    output  logic                           GAME_new_frame_ready, // not driven here
    output  game_state_pkg::game_state_t    GAME_next_frame,

    input   logic [3:0]                     GAME_frame_select      // 1–8 selects screen1–screen8
);

    import game_state_pkg::*;

    // Eight frame buffers
    game_state_t template;
    game_state_t screen1;
    game_state_t screen2;
    game_state_t screen3;
    game_state_t screen4;
    game_state_t screen5;
    game_state_t screen6;
    game_state_t screen7;
    game_state_t screen8;
	
	// 3x5 font for digits 1–8 (rows 0..4, cols 0..2)
	logic [2:0] d1 [0:4];
	logic [2:0] d2 [0:4];
	logic [2:0] d3 [0:4];
	logic [2:0] d4 [0:4];
	logic [2:0] d5 [0:4];
	logic [2:0] d6 [0:4];
	logic [2:0] d7 [0:4];
	logic [2:0] d8 [0:4];

    // ----------------------------------------------------------------
    // Initialize the eight game_state patterns
    // ----------------------------------------------------------------
    initial begin : init_game_states
        integer r, c;

        screen1 = blank_game_state;

        // Start everything as blank
        screen1 = blank_game_state;
        screen2 = blank_game_state;
        screen3 = blank_game_state;
        screen4 = blank_game_state;
        screen5 = blank_game_state;
        screen6 = blank_game_state;
        screen7 = blank_game_state;
        screen8 = blank_game_state;

        for (r = 0; r < 20; r++) begin
            for (c = 0; c < 10; c++) begin
                if (r == 0 | r == 19 | c== 0 | c == 9) template.screen[c][r] = 1'b1;
            end
        end

        screen1 = template;
        screen2 = template;
        screen3 = template;
        screen4 = template;
        screen5 = template;
        screen6 = template;
        screen7 = template;
        screen8 = template;

        // "1"
        d1[0] = 3'b010;
        d1[1] = 3'b010;
        d1[2] = 3'b010;
        d1[3] = 3'b010;
        d1[4] = 3'b010;

        // "2"
        d2[0] = 3'b111;
        d2[1] = 3'b001;
        d2[2] = 3'b111;
        d2[3] = 3'b100;
        d2[4] = 3'b111;

        // "3"
        d3[0] = 3'b111;
        d3[1] = 3'b001;
        d3[2] = 3'b111;
        d3[3] = 3'b001;
        d3[4] = 3'b111;

        // "4"
        d4[0] = 3'b101;
        d4[1] = 3'b101;
        d4[2] = 3'b111;
        d4[3] = 3'b001;
        d4[4] = 3'b001;

        // "5"
        d5[0] = 3'b111;
        d5[1] = 3'b100;
        d5[2] = 3'b111;
        d5[3] = 3'b001;
        d5[4] = 3'b111;

        // "6"
        d6[0] = 3'b111;
        d6[1] = 3'b100;
        d6[2] = 3'b111;
        d6[3] = 3'b101;
        d6[4] = 3'b111;

        // "7"
        d7[0] = 3'b111;
        d7[1] = 3'b001;
        d7[2] = 3'b010;
        d7[3] = 3'b010;
        d7[4] = 3'b010;

        // "8"
        d8[0] = 3'b111;
        d8[1] = 3'b101;
        d8[2] = 3'b111;
        d8[3] = 3'b101;
        d8[4] = 3'b111;

        // Draw digits into rows 2..6, cols 0..2
        for (r = 0; r < 5; r++) begin
            for (c = 0; c < 3; c++) begin
                if (d1[r][c]) screen1.screen[-c+6][r+8] = 1'b1;
                if (d2[r][c]) screen2.screen[-c+6][r+8] = 1'b1;
                if (d3[r][c]) screen3.screen[-c+6][r+8] = 1'b1;
                if (d4[r][c]) screen4.screen[-c+6][r+8] = 1'b1;
                if (d5[r][c]) screen5.screen[-c+6][r+8] = 1'b1;
                if (d6[r][c]) screen6.screen[-c+6][r+8] = 1'b1;
                if (d7[r][c]) screen7.screen[-c+6][r+8] = 1'b1;
                if (d8[r][c]) screen8.screen[-c+6][r+8] = 1'b1;
            end
        end
    end


    // ----------------------------------------------------------------
    // Combinational selection of next frame
    // ----------------------------------------------------------------
    always_comb begin
        // Default to blank if select is out of range
        GAME_next_frame = blank_game_state;

        // Map 4-bit select to screens 1–8
        case (GAME_frame_select)
            4'd0: GAME_next_frame = screen1;
            4'd1: GAME_next_frame = screen2;
            4'd2: GAME_next_frame = screen3;
            4'd3: GAME_next_frame = screen4;
            4'd4: GAME_next_frame = screen5;
            4'd5: GAME_next_frame = screen6;
            4'd6: GAME_next_frame = screen7;
            4'd7: GAME_next_frame = screen8;
            default: GAME_next_frame = template;
        endcase
    end

    // GAME_new_frame_ready is *not* assigned in this module.
    // Drive it with your own logic where appropriate.

endmodule
