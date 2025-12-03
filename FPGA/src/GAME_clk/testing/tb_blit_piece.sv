// tb_blit_piece.sv
// Simple sanity testbench for blit_piece
// Kaden Cassidy (testbench written with ChatGPT)

`timescale 1ns/1ps

import game_state_pkg::*;
import tetris_pkg::*;

module tb_blit_piece;

    // DUT inputs/outputs
    logic              no_piece;
    game_state_t       base_state;
    active_piece_grid_t active_piece_grid;
    game_state_t       out_state;

    // DUT instance
    blit_piece dut (
        .no_piece         (no_piece),
        .base_state       (base_state),
        .active_piece_grid(active_piece_grid),
        .out_state        (out_state)
    );

    // ----------------------------------------------------------------
    // Utility: pretty-print the board as 10x20 ASCII grid
    // ----------------------------------------------------------------
    task automatic print_state(string label, game_state_t s);
        $display("=== %s ===", label);
        // y = 19 (top) down to 0 (bottom) if bit 19=top, 0=bottom.
        for (int y = 19; y >= 0; y--) begin
            $write("%2d | ", y);
            for (int x = 0; x < 10; x++) begin
                // screen[x][y] is 1 => filled cell
                if (s.screen[x][y])
                    $write("#");
                else
                    $write(".");
            end
            $write("\n");
        end
        $write("    + ----------\n\n");
    endtask

    // ----------------------------------------------------------------
    // Simple stimulus
    // ----------------------------------------------------------------
    initial begin
        $display("=== tb_blit_piece starting ===");

        // ----------------------------------------------------------------
        // Test 1: no_piece = 1 => out_state should equal base_state
        // ----------------------------------------------------------------
        base_state        = '{default: '0};
        active_piece_grid = '{default: '0};
        no_piece          = 1'b1;

        #1; // allow combinational logic to settle

        assert (out_state == base_state)
            else $error("Test 1 FAILED: no_piece=1 but out_state != base_state");

        $display("Test 1 PASSED: no_piece gating works.");
        print_state("Test 1 out_state (should be all empty)", out_state);

        // ----------------------------------------------------------------
        // Test 2: Simple 2x2 block in the middle of the board, no base
        // ----------------------------------------------------------------
        base_state        = '{default: '0};
        active_piece_grid = '{default: '0};

        // Place the 4x4 piece window somewhere in the middle.
        // Remember: board coord = (x, y) = (active_piece_grid.x + dx - 4,
        //                                   active_piece_grid.y + dy - 4)
        //
        // These specific numbers don't matter much, we just want it on-screen.
        active_piece_grid.x = 6;
        active_piece_grid.y = 6;

        // Make a 2x2 filled block at local coords (1,1), (1,2), (2,1), (2,2)
        active_piece_grid.piece[1][1] = 1'b1;
        active_piece_grid.piece[1][2] = 1'b1;
        active_piece_grid.piece[2][1] = 1'b1;
        active_piece_grid.piece[2][2] = 1'b1;

        no_piece = 1'b0;

        #1;

        $display("Test 2: base_state empty, 2x2 active piece drawn.");
        print_state("Test 2 out_state", out_state);

        // ----------------------------------------------------------------
        // Test 3: Same piece, but with some base_state already set
        // ----------------------------------------------------------------
        base_state        = '{default: '0};

        // Pre-fill a simple pattern in base_state (e.g., bottom row full)
        for (int x = 0; x < 10; x++) begin
            base_state.screen[x][0] = 1'b1;  // y = 0 row
        end

        // Keep the same active_piece_grid as in Test 2
        no_piece = 1'b0;

        #1;

        $display("Test 3: base_state has bottom row filled, piece ORs on top.");
        print_state("Test 3 base_state", base_state);
        print_state("Test 3 out_state",  out_state);

        // ----------------------------------------------------------------
        // Test 4: no_piece = 1 again with active piece present
        // out_state should ignore piece and return base_state only
        // ----------------------------------------------------------------
        no_piece = 1'b1;

        #1;

        assert (out_state == base_state)
            else $error("Test 4 FAILED: no_piece=1 but piece still modified out_state");

        $display("Test 4 PASSED: no_piece correctly disables active piece overlay.");
        print_state("Test 4 out_state (should match base_state)", out_state);

        $display("=== tb_blit_piece finished ===");
        $stop;
    end

endmodule
