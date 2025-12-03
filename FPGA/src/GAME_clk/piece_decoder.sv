// piece_decoder.sv
// James Kaden Cassidy
// kacassidy@hmc.edu
// 12/1/2025
module piece_decoder (
    input  tetris_pkg::active_piece_t        active_piece,
    output tetris_pkg::active_piece_grid_t   active_piece_grid
);

    import tetris_pkg::*;

  // 4x4 matrix type: [row][col], row 0 = top, col 0 = left
  typedef logic [3:0] piece_matrix_t [3:0];

  // ---------------------------------------------------------------------------
  // Base (ROT_0) shapes as 4x4 matrices (constants).
  // ---------------------------------------------------------------------------

  localparam piece_matrix_t I_BASE = '{
      '{1'b0, 1'b0, 1'b0, 1'b0}, // row 0
      '{1'b1, 1'b1, 1'b1, 1'b1}, // row 1
      '{1'b0, 1'b0, 1'b0, 1'b0}, // row 2
      '{1'b0, 1'b0, 1'b0, 1'b0}  // row 3
  };

  // localparam piece_matrix_t I_BASE = '{
  //     '{1'b1, 1'b1, 1'b1, 1'b1}, // row 0
  //     '{1'b1, 1'b1, 1'b1, 1'b1}, // row 1
  //     '{1'b1, 1'b1, 1'b1, 1'b1}, // row 2
  //     '{1'b1, 1'b1, 1'b1, 1'b1}  // row 3
  // };

  localparam piece_matrix_t O_BASE = '{
      '{1'b0, 1'b0, 1'b0, 1'b0},
      '{1'b0, 1'b1, 1'b1, 1'b0},
      '{1'b0, 1'b1, 1'b1, 1'b0},
      '{1'b0, 1'b0, 1'b0, 1'b0}
  };

  localparam piece_matrix_t T_BASE = '{
      '{1'b0, 1'b0, 1'b0, 1'b0},
      '{1'b0, 1'b1, 1'b0, 1'b0},
      '{1'b1, 1'b1, 1'b1, 1'b0},
      '{1'b0, 1'b0, 1'b0, 1'b0}
  };

  localparam piece_matrix_t L_BASE = '{
      '{1'b0, 1'b1, 1'b0, 1'b0},
      '{1'b0, 1'b1, 1'b0, 1'b0},
      '{1'b0, 1'b1, 1'b1, 1'b0},
      '{1'b0, 1'b0, 1'b0, 1'b0}
  };

  localparam piece_matrix_t J_BASE = '{
      '{1'b0, 1'b0, 1'b1, 1'b0},
      '{1'b0, 1'b0, 1'b1, 1'b0},
      '{1'b0, 1'b1, 1'b1, 1'b0},
      '{1'b0, 1'b0, 1'b0, 1'b0}
  };

  localparam piece_matrix_t S_BASE = '{
      '{1'b0, 1'b0, 1'b0, 1'b0},
      '{1'b0, 1'b1, 1'b1, 1'b0},
      '{1'b1, 1'b1, 1'b0, 1'b0},
      '{1'b0, 1'b0, 1'b0, 1'b0}
  };

  localparam piece_matrix_t Z_BASE = '{
      '{1'b0, 1'b0, 1'b0, 1'b0},
      '{1'b1, 1'b1, 1'b0, 1'b0},
      '{1'b0, 1'b1, 1'b1, 1'b0},
      '{1'b0, 1'b0, 1'b0, 1'b0}
  };

  // ---------------------------------------------------------------------------
  // Internal 4x4 matrices: base + rotated
  // ---------------------------------------------------------------------------
  piece_matrix_t base_matrix;
  piece_matrix_t rotated;

  // ---------------------------------------------------------------------------
  // Pure combinational decode + rotation + packing
  // ---------------------------------------------------------------------------
  always_comb begin
    int y, x, r, c;

    // Default: clear base_matrix
    for (y = 0; y < 4; y++) begin
      for (x = 0; x < 4; x++) begin
        base_matrix[x][y] = 1'b0;
      end
    end

    // Select base shape for ROT_0
    unique case (active_piece.piece_type)
      PIECE_I: base_matrix = I_BASE;
      PIECE_O: base_matrix = O_BASE;
      PIECE_T: base_matrix = T_BASE;
      PIECE_L: base_matrix = L_BASE;
      PIECE_J: base_matrix = J_BASE;
      PIECE_S: base_matrix = S_BASE;
      PIECE_Z: base_matrix = Z_BASE;
      default: /* keep zeros */;
    endcase

    for (r = 0; r < 4; r++) begin
      for (c = 0; c < 4; c++) begin
          x = 3-c;
          y = 3-r;
          rotated[x][y] = base_matrix[r][c];
      end
    end
    base_matrix = rotated;

    // Apply rotation (combinational, no functions)
    for (y = 0; y < 4; y++) begin
      for (x = 0; x < 4; x++) begin
        unique case (active_piece.rotation)
          ROT_0:   rotated[x][y] = base_matrix[x][y];
          // 90Â° clockwise: (y,x) <- (3-x, y)
          ROT_90:  rotated[x][y] = base_matrix[y][3-x];
          // 180Â°: (y,x) <- (3-y,3-x)
          ROT_180: rotated[x][y] = base_matrix[3-x][3-y];
          // 270Â° clockwise: (y,x) <- (x,3-y)
          ROT_270: rotated[x][y] = base_matrix[3-y][x];
          default: rotated[x][y] = base_matrix[x][y];
        endcase
      end
    end

    // Pack rotated rows into active_piece_grid.piece[y][3:0] = {right..left}
    for (x = 0; x < 4; x++) begin
      active_piece_grid.piece = rotated;
    end

    // Top-left of the 4x4 grid in board coordinates
    active_piece_grid.x = active_piece.x;
    active_piece_grid.y = active_piece.y;
  end

endmodule
