// Game Decoder
// James Kaden Cassidy 
// kacassidy@hmc.edu
// 11/12/2025

module game_decoder #(
        parameter vga_pkg::vga_params_t params
    )(
        output  logic                           VGA_new_frame_ready,

        input   game_state_pkg::game_state_t    VGA_frame,

        input   logic[params.pixel_x_bits-1:0]  pixel_x_target_next,
        input   logic[params.pixel_y_bits-1:0]  pixel_y_target_next,
        output  logic                           pixel_value_next,

        input   logic                           v_sync
    );

    logic[10:0] x_idx, y_idx;

    // when vsync goes low to indicate new fame, we allow a new game state to be loaded to display
    assign VGA_new_frame_ready  = ~v_sync;

    assign x_idx                = (pixel_x_target_next-240);
    assign y_idx                = (pixel_y_target_next-80);
    assign pixel_value_next     = VGA_frame.screen[x_idx[params.pixel_x_bits-1:4]][y_idx[params.pixel_x_bits-1:4]] 
                                    & pixel_x_target_next >= 240 & pixel_x_target_next < 400
                                    & pixel_y_target_next >= 80 & pixel_y_target_next < 400;

endmodule