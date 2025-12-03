// tb_piece_mask_generator.sv
// Basic sanity testbench for piece_mask_generator

`timescale 1ns/1ps

import game_state_pkg::*;

module tb_piece_mask_generator;

    // Match DUT parameters
    localparam int BOARD_WIDTH  = 10;
    localparam int BOARD_HEIGHT = 20;

    // DUT I/O
    game_state_t state;
    logic [$clog2(BOARD_WIDTH) -1:0]  piece_x;
    logic [$clog2(BOARD_HEIGHT)-1:0]  piece_y;
    logic [5:0]                       window [5:0];

    // DUT instance
    piece_mask_generator #(
        .BOARD_WIDTH  (BOARD_WIDTH),
        .BOARD_HEIGHT (BOARD_HEIGHT)
    ) dut (
        .state   (state),
        .piece_x (piece_x),
        .piece_y (piece_y),
        .window  (window)
    );

    // ------------------------------------------------------------
    // Utility: print the 6x6 window (ly 5 at "top", ly 0 at bottom)
    // ------------------------------------------------------------
    task automatic print_window(string label);
        $display("=== %s ===", label);
        for (int ly = 5; ly >= 0; ly--) begin
            $write("%0d | ", ly);
            for (int lx = 0; lx < 6; lx++) begin
                if (window[lx][ly])
                    $write("#");
                else
                    $write(".");
            end
            $write("\n");
        end
        $write("    + ------\n\n");
    endtask

    // ------------------------------------------------------------
    // Simple stimulus
    // ------------------------------------------------------------
    initial begin
        $display("=== tb_piece_mask_generator starting ===");

        // --------------------------------------------------------
        // Test 1: Centered window on all-zero board
        // piece_x=5, piece_y=5 -> window maps to wx,wy in [0..5]
        // Expect: all zeros (no off-screen, and state is all 0)
        // --------------------------------------------------------
        state   = '{default: '0};
        piece_x = 5;
        piece_y = 5;

        #1;

        for (int lx = 0; lx < 6; lx++) begin
            for (int ly = 0; ly < 6; ly++) begin
                if (window[lx][ly] !== 1'b0)
                    $error("Test 1 FAILED: window[%0d][%0d] != 0", lx, ly);
            end
        end

        print_window("Test 1: centered, all-zero board");

        // --------------------------------------------------------
        // Test 2: Single '1' in board at (x=2,y=3) with same center
        // For piece_x=5,piece_y=5:
        //   wx = piece_x + lx - 1 - 4 = lx      (for this choice)
        //   wy = piece_y + ly - 1 - 4 = ly
        // So window[2][3] should mirror state.screen[2][3].
        // --------------------------------------------------------
        state   = '{default: '0};
        state.screen[2][3] = 1'b1;

        piece_x = 5;
        piece_y = 5;

        #1;

        if (window[2][3] !== 1'b1)
            $error("Test 2 FAILED: window[2][3] should be 1 (mirroring state[2][3])");

        // Everything else in the 6x6 should still be 0
        for (int lx = 0; lx < 6; lx++) begin
            for (int ly = 0; ly < 6; ly++) begin
                if (!(lx == 2 && ly == 3)) begin
                    if (window[lx][ly] !== 1'b0)
                        $error("Test 2 FAILED: window[%0d][%0d] should be 0", lx, ly);
                end
            end
        end

        print_window("Test 2: single '1' at (2,3)");

        // --------------------------------------------------------
        // Test 3: Near top-left edge (piece_x=1,piece_y=1)
        //
        // wx = piece_x + lx - 1 - 4 = 1 + lx - 5 = lx - 4
        //   => valid wx (0..BOARD_WIDTH-1) only for lx = 4,5.
        //   => lx=0..3 should stay default 6'b111111.
        //
        // wy = piece_y + ly - 1 - 4 = 1 + ly - 5 = ly - 4
        //   => for ly=0..3, wy<0 => col_bits[ly] forced to 0
        //   => for ly=4,5, wy=0,1 sample state.screen[wx][0/1]
        // --------------------------------------------------------
        state = '{default: '0};

        // Put distinctive bits at (x=0,y=0/1) and (x=1,y=0/1)
        state.screen[0][0] = 1'b1; // used by window[4][4]
        state.screen[0][1] = 1'b0; // used by window[4][5]
        state.screen[1][0] = 1'b1; // used by window[5][4]
        state.screen[1][1] = 1'b1; // used by window[5][5]

        piece_x = 1;
        piece_y = 1;

        #1;

        // Columns lx=0..3 should remain 6'b111111 (off-screen)
        for (int lx = 0; lx < 4; lx++) begin
            if (window[lx] !== 6'b111111)
                $error("Test 3 FAILED: window[%0d] should be 6'b111111, got %b", lx, window[lx]);
        end

        // Columns lx=4..5 should have ly=0..3 = 0 (wy<0 case),
        // ly=4..5 sampled from state.
        for (int lx = 4; lx < 6; lx++) begin
            for (int ly = 0; ly < 4; ly++) begin
                if (window[lx][ly] !== 1'b0)
                    $error("Test 3 FAILED: window[%0d][%0d] should be 0 (wy<0)", lx, ly);
            end
        end

        // Check some specific sampled cells:
        // lx=4 -> wx=0; ly=4->wy=0; ly=5->wy=1
        if (window[4][4] !== state.screen[0][0])
            $error("Test 3 FAILED: window[4][4] != state.screen[0][0]");
        if (window[4][5] !== state.screen[0][1])
            $error("Test 3 FAILED: window[4][5] != state.screen[0][1]");

        // lx=5 -> wx=1; ly=4->wy=0; ly=5->wy=1
        if (window[5][4] !== state.screen[1][0])
            $error("Test 3 FAILED: window[5][4] != state.screen[1][0]");
        if (window[5][5] !== state.screen[1][1])
            $error("Test 3 FAILED: window[5][5] != state.screen[1][1]");

        print_window("Test 3: near top-left edge");

        $display("=== tb_piece_mask_generator finished ===");
        $stop;
    end

endmodule
