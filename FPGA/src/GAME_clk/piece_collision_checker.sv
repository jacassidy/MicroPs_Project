// piece_land_checker.sv
// James Kaden Cassidy
// kacassidy@hmc.edu
// 12/1/2025

//`include "parameters.svh"
`define COLORS 3

module block_pixels(output logic [5:0] block_pixels[5:0], input logic [5:0] shifted[5:0], input logic [5:0] base[5:0]);
    always_comb begin
        int x;
        int y;
        for (x = 0; x < 6; x++) begin
            for (y = 0; y < 6; y++) begin
                block_pixels[x][y] = shifted[x][y] & ~base[x][y];
            end
        end
    end
endmodule

module piece_collision_checker #(
    parameter int BOARD_WIDTH  = 10,
    parameter int BOARD_HEIGHT = 20
) ( 
        input   logic                               no_piece,
        input   game_state_pkg::game_state_t        GAME_fixed_state,
        input   logic[$clog2(BOARD_WIDTH) -1:0]     piece_x,
        input   logic[$clog2(BOARD_HEIGHT)-1:0]     piece_y,

        input   logic [3:0]                         piece_grid [3:0],
        output  logic                               left_collision,
        output  logic                               right_collision,
        output  logic                               down_collision,
        output  logic                               rotation_collision,
        
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
    logic [5:0] blank_mask [5:0];
    logic [5:0] board_mask [5:0];
    logic [5:0] piece_mask [5:0];

    // shifted versions of piece_mask
    logic [5:0] piece_mask_left  [5:0];
    logic [5:0] piece_mask_right [5:0];
    logic [5:0] piece_mask_down  [5:0];
    logic [5:0] piece_mask_rotate[5:0];

    assign blank_mask = '{default: 6'b0};;

    piece_mask_generator Piece_Mask_Generator(.state(GAME_fixed_state), .piece_x, .piece_y, .window(board_mask));

    assign debug_window_0[0]       = no_piece ? blank_mask : piece_mask;
    assign debug_window_1[0]       = no_piece ? blank_mask : piece_mask;
    assign debug_window_2[0]       = no_piece ? blank_mask : piece_mask;
    
    assign debug_window_0[1]       = board_mask;
    assign debug_window_1[1]       = board_mask;
    assign debug_window_2[1]       = board_mask;
    assign debug_window_3[1]       = board_mask;

    block_pixels bp1(debug_window_0[2], no_piece ? blank_mask : piece_mask_down,  piece_mask);
    block_pixels bp2(debug_window_1[2], no_piece ? blank_mask : piece_mask_left,  piece_mask);
    block_pixels bp3(debug_window_2[2], no_piece ? blank_mask : piece_mask_right, piece_mask);

    assign debug_window_3[2]  	   = piece_mask_rotate;

    assign debug_singals_0[0]      = down_collision;
    assign debug_singals_1[0]      = left_collision;
    assign debug_singals_2[0]      = right_collision;
    assign debug_singals_3[0]      = rotation_collision;

    // ------------------------------------------------------------------------
    // Build piece_mask and compute collisions with explicit (x,y) shifts
    // ------------------------------------------------------------------------
    always_comb begin
        // Clear base and shifted masks
        for (int y = 0; y < 6; y++) begin
            piece_mask[y]       = '0;
            piece_mask_left[y]  = '0;
            piece_mask_right[y] = '0;
            piece_mask_down[y]  = '0;
        end

        // Place 4Ã—4 piece in the middle of the 6Ã—6:
        // piece_grid[0..3][0..3] -> piece_mask[1..4][1..4]
        for (int y = 0; y < 4; y++) begin
            for (int x = 0; x < 4; x++) begin
                piece_mask[x+1][y+1] = piece_grid[x][y];
            end
        end

        // Now shift using (x,y) coordinates so that:
        //  - LEFT  = x-1  (if x > 0)
        //  - RIGHT = x+1  (if x < 5)
        //  - DOWN  = y+1  (if y < 5)
        //
        // Coordinate system: (0,0) = top-left, x right, y down.
        for (int y = 0; y < 6; y++) begin
            for (int x = 0; x < 6; x++) begin
                if (piece_mask[x][y]) begin
                    // move one cell left
                    if (x > 0)
                        piece_mask_left[x-1][y] = 1'b1;

                    // move one cell right
                    if (x < 5)
                        piece_mask_right[x+1][y] = 1'b1;

                    // move one cell down
                    if (y < 5)
                        piece_mask_down[x][y+1] = 1'b1;
                end
                piece_mask_rotate[x][y] = piece_mask[y][5-x];
            end
        end

        // Collision detection (same idea as before)
        left_collision  = 1'b0;
        right_collision = 1'b0;
        down_collision  = 1'b0;
        rotation_collision = 1'b0;

        for (int y = 0; y < 6; y++) begin
            if (|(piece_mask_left[y]  & board_mask[y])) left_collision  = 1'b1;
            if (|(piece_mask_right[y] & board_mask[y])) right_collision = 1'b1;
            if (|(piece_mask_down[y]  & board_mask[y])) down_collision  = 1'b1;
            if (|(piece_mask_rotate[y]  & board_mask[y])) rotation_collision  = 1'b1;
        end

        down_collision &= ~no_piece;
    end




endmodule
