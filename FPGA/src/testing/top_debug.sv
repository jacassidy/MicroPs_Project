// Top Debugger
// James Kaden Cassidy 
// kacassidy@hmc.edu
// 11/13/2025

module top_debug #(
        parameter vga_pkg::vga_params_t params = vga_pkg::VGA_640x480_60
    )(
        output  logic       h_sync,
        output  logic       v_sync,
        output  logic       pixel_signal
    );

    // VGA Signals
    logic   HSOSC_clk, VGA_clk;
    logic   pixel_value_next;

    logic[params.pixel_x_bits-1:0] pixel_x_target_next;
    logic[params.pixel_y_bits-1:0] pixel_y_target_next;

    // State manager signals
    logic VGA_new_frame_ready, GAME_new_frame_ready;
    
    game_state_pkg::game_state_t GAME_next_frame, VGA_frame;

    ////----MODULES----////

    vga_controller #(
        .params(params)
    ) VGA_Controller (
        .reset_n(1'b1),
        // pixel addressing (for renderer)
        .pixel_x_target_next,
        .pixel_y_target_next,
        .pixel_value_next,          // 1=on, 0=off
        // VGA pins
        .h_sync,
        .v_sync,
        .pixel_signal, // core will gate to visible region
        .VGA_clk,
        .HSOSC_clk
    );

    state_manager State_Manager(.reset(1'b0), .VGA_new_frame_ready, .GAME_new_frame_ready, 
        .GAME_next_frame, .VGA_frame);

    game_decoder #(.params(params)) Game_Decoder(.VGA_new_frame_ready, .VGA_frame, .pixel_x_target_next, .pixel_y_target_next, 
        .pixel_value_next, .v_sync);

    game_encoder Game_Encoder(.GAME_new_frame_ready, .GAME_next_frame, .HSOSC_clk);

endmodule  