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

  // Constant function to build the struct so we don't repeat math
  function active_piece_t make_piece(
    piece_type_t piece, rotation_t rotation
  );
    active_piece_t t;

    t.piece_type    = piece;
    t.rotation      = rotation;
    t.y             = 0;
    t.x             = 3;

    return t;
  endfunction

  localparam active_piece_t HERO            = make_piece(PIECE_I, ROT_0);
  localparam active_piece_t SMASH_BOY       = make_piece(PIECE_O, ROT_0);
  localparam active_piece_t TEEWEE          = make_piece(PIECE_T, ROT_0);
  localparam active_piece_t ORANGE_RICKY    = make_piece(PIECE_L, ROT_0);
  localparam active_piece_t BLUE_RICKY      = make_piece(PIECE_J, ROT_0);
  localparam active_piece_t RHODE_ISLAND_Z  = make_piece(PIECE_S, ROT_0);
  localparam active_piece_t CLEVELAND_Z     = make_piece(PIECE_Z, ROT_0);

  typedef struct {
    logic  [3:0]  piece [3:0];
    logic  [3:0]  x;   // 0..9 (starting x of top left of grid)
    logic  [4:0]  y;   // 0..19 (starting y of top left)
  } active_piece_grid_t;

  // Simple command enum from MCU (or buttons)
  typedef enum logic [1:0] {
    CMD_LEFT      = 2'd2,
    CMD_RIGHT     = 2'd3,
    CMD_ROTATE    = 2'd0,
    CMD_SOFT_DROP = 2'd1
  } command_t;

endpackage : tetris_pkg
