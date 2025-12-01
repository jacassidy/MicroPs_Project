// tetris_pkg.sv
// Noah Fotenos
// nfotenos@hmc.edu
// 12/1/2025


package tetris_pkg;

  // 7 classic Tetris pieces, but we can start with fewer if you want
  typedef enum logic [2:0] {
    PIECE_I,
    PIECE_O,
    PIECE_T,
    PIECE_L,
    PIECE_J,
    PIECE_S,
    PIECE_Z
  } piece_type_t;

  typedef enum logic [1:0] {
    ROT_0,
    ROT_90,
    ROT_180,
    ROT_270
  } rotation_t;

  // Active falling piece state in board coordinates
  typedef struct packed {
    piece_type_t  piece_type;
    rotation_t    rotation;
    logic  [3:0]  x;   // 0..9 (board columns)
    logic  [4:0]  y;   // 0..19 (board rows)
  } active_piece_t;

  typedef struct packed {
    logic  [3:0]  piece [3:0];
    logic  [3:0]  x;   // 0..9 (starting x of top left of grid)
    logic  [4:0]  y;   // 0..19 (starting y of top left)
  } active_piece_grid_t;

  // Simple command enum from MCU (or buttons)
  typedef enum logic [2:0] {
    CMD_NONE,
    CMD_LEFT,
    CMD_RIGHT,
    CMD_ROTATE,
    CMD_SOFT_DROP
  } command_t;

endpackage : tetris_pkg
