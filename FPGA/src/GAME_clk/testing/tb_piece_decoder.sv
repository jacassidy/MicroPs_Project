// tb_piece_decoder.sv
// Basic sanity testbench for piece_decoder
// Kaden Cassidy (with ChatGPT)
//
// Assumes tetris_pkg.sv defines:
//   - active_piece_t
//   - active_piece_grid_t
//   - enums: PIECE_I, PIECE_O, PIECE_T, PIECE_L, PIECE_J, PIECE_S, PIECE_Z
//   - enums: ROT_0, ROT_90, ROT_180, ROT_270

`timescale 1ns/1ps

import tetris_pkg::*;

module tb_piece_decoder;

    // DUT I/O
    active_piece_t       active_piece;
    active_piece_grid_t  active_piece_grid;

    // DUT instance
    piece_decoder dut (
        .active_piece      (active_piece),
        .active_piece_grid (active_piece_grid)
    );

    // ------------------------------------------------------------
    // Helper: count number of '1' cells in the 4x4 piece matrix
    // ------------------------------------------------------------
    function automatic int count_active_cells(input active_piece_grid_t grid);
        int cnt = 0;
        for (int r = 0; r < 4; r++) begin
            for (int c = 0; c < 4; c++) begin
                if (grid.piece[r][c])
                    cnt++;
            end
        end
        return cnt;
    endfunction

    // Pretty-print the 4x4 piece grid for debug
    task automatic print_piece(string label, active_piece_grid_t grid);
        $display("=== %s === (x=%0d, y=%0d)", label, grid.x, grid.y);
        for (int r = 0; r < 4; r++) begin
            $write("%0d | ", r);
            for (int c = 0; c < 4; c++) begin
                if (grid.piece[r][c])
                    $write("#");
                else
                    $write(".");
            end
            $write("\n");
        end
        $write("    + ----\n\n");
    endtask

    // ------------------------------------------------------------
    // Simple stimulus
    // ------------------------------------------------------------
    initial begin
        int cnt;

        $display("=== tb_piece_decoder starting ===");

        // --------------------------------------------------------
        // Test 1: I piece, ROT_0, center-ish position
        // --------------------------------------------------------
        active_piece = '0;
        active_piece.piece_type = PIECE_I;
        active_piece.rotation   = ROT_0;
        active_piece.x          = 5;
        active_piece.y          = 10;

        #1; // let combinational logic settle

        cnt = count_active_cells(active_piece_grid);

        assert (active_piece_grid.x == active_piece.x &&
                active_piece_grid.y == active_piece.y)
            else $error("Test 1 FAILED: x/y mismatch for I, ROT_0");

        assert (cnt == 4)
            else $error("Test 1 FAILED: I, ROT_0 should have 4 blocks, got %0d", cnt);

        print_piece("Test 1: I, ROT_0", active_piece_grid);

        // --------------------------------------------------------
        // Test 2: I piece, ROT_90
        // --------------------------------------------------------
        active_piece.rotation = ROT_90;
        active_piece.x        = 3;
        active_piece.y        = 15;

        #1;

        cnt = count_active_cells(active_piece_grid);

        assert (active_piece_grid.x == active_piece.x &&
                active_piece_grid.y == active_piece.y)
            else $error("Test 2 FAILED: x/y mismatch for I, ROT_90");

        assert (cnt == 4)
            else $error("Test 2 FAILED: I, ROT_90 should have 4 blocks, got %0d", cnt);

        print_piece("Test 2: I, ROT_90", active_piece_grid);

        // --------------------------------------------------------
        // Test 3: T piece, ROT_180
        // --------------------------------------------------------
        active_piece = '0;
        active_piece.piece_type = PIECE_T;
        active_piece.rotation   = ROT_180;
        active_piece.x          = 4;
        active_piece.y          = 8;

        #1;

        cnt = count_active_cells(active_piece_grid);

        assert (active_piece_grid.x == active_piece.x &&
                active_piece_grid.y == active_piece.y)
            else $error("Test 3 FAILED: x/y mismatch for T, ROT_180");

        assert (cnt == 4)
            else $error("Test 3 FAILED: T, ROT_180 should have 4 blocks, got %0d", cnt);

        print_piece("Test 3: T, ROT_180", active_piece_grid);

        // --------------------------------------------------------
        // Test 4: Z piece, ROT_270
        // --------------------------------------------------------
        active_piece = '0;
        active_piece.piece_type = PIECE_Z;
        active_piece.rotation   = ROT_270;
        active_piece.x          = 1;
        active_piece.y          = 5;

        #1;

        cnt = count_active_cells(active_piece_grid);

        assert (active_piece_grid.x == active_piece.x &&
                active_piece_grid.y == active_piece.y)
            else $error("Test 4 FAILED: x/y mismatch for Z, ROT_270");

        assert (cnt == 4)
            else $error("Test 4 FAILED: Z, ROT_270 should have 4 blocks, got %0d", cnt);

        print_piece("Test 4: Z, ROT_270", active_piece_grid);

        $display("=== tb_piece_decoder finished ===");
        $stop; // <--- as requested
    end

endmodule
