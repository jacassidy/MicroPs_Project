// Top Debugger
// James Kaden Cassidy 
// kacassidy@hmc.edu
// 11/13/2025

module top_debug #(
        parameter vga_pkg::vga_params_t params = vga_pkg::VGA_640x480_60
    )(
        input   logic       reset_n,
        output  logic       h_sync,
        output  logic       v_sync,
        output  logic       pixel_signal,

        input   logic       sck,
        input   logic       sdi,
        output  logic       sdo,
        input   logic       ce,

        input   logic       external_clk
    );

    // SPI signals

    logic [7:0] spi_data;
    logic clk_divided;

    // VGA Signals
    logic   HSOSC_clk, VGA_clk;
    logic   pixel_value_next;

    logic[params.pixel_x_bits-1:0] pixel_x_target_next;
    logic[params.pixel_y_bits-1:0] pixel_y_target_next;

    // State manager signals
    logic VGA_new_frame_ready, GAME_new_frame_ready;
    
    game_state_pkg::game_state_t GAME_next_frame, VGA_frame;

    logic [3:0] GAME_frame_select;

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

    //game_encoder Game_Encoder(.GAME_new_frame_ready(), .GAME_next_frame, .GAME_frame_select(spi_data[3:0]));

    game_executioner Game_Executioner(.reset(~reset_n), .move_clk(), .game_clk(clk_divided), .move(), .new_piece(tetris_pkg::SQUARE), .GAME_state(GAME_next_frame));

    spi SPI(.reset(reset_led), .sck, .sdi, .sdo, .ce, .data(spi_data));

    // Once new data has come it and chip enable goes low then assert new frame ready
    assign GAME_new_frame_ready = ~clk_divided;

    clock_divider #(.div_count(10000000)) Clock_Divider(.clk(HSOSC_clk), .reset(~reset_n), .clk_divided);


endmodule  