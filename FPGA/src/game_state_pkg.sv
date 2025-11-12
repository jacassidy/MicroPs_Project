// game_state_pkg.sv
// James Kaden Cassidy 
// kacassidy@hmce.edu
// 11/12/2025

package game_state_pkg;

  typedef struct {
    logic[9:0] screen[19:0];
  } game_state_t;

  localparam game_state_t blank_game_state = 0;

endpackage : vga_pkg
