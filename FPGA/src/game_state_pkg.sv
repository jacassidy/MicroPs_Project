// game_state_pkg.sv
// James Kaden Cassidy 
// kacassidy@hmce.edu
// 11/12/2025

package game_state_pkg;

  typedef struct {
    // screen[x][y] : 20 rows, each 10 bits wide
    logic [19:0] screen [9:0];
  } game_state_t;

  localparam game_state_t blank_game_state = '{default: '0};

endpackage : game_state_pkg