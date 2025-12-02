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

        input   logic       external_clk_raw,
        output  logic       debug_led
    );

    // SPI signals

    logic [7:0] spi_data;
    logic clk_divided;

    logic game_clk;
    
    // SPI signals
    logic invalidate_spi_data, spi_data_valid;

    // VGA Signals
    logic   HSOSC_clk, VGA_clk;
    logic   pixel_value_next;

    logic[8:0] clk_count, sig1, sig2, sig3, sig4, sig5, sig6;

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
        .pixel_value_next, .v_sync,
        .sig0(clk_count),   // logic [8:0]
        .sig1,
        .sig2,
        .sig3,
        .sig4,
        .sig5,
        .sig6
        );

    //game_encoder Game_Encoder(.GAME_new_frame_ready(), .GAME_next_frame, .GAME_frame_select(spi_data[3:0]));
    tetris_pkg::active_piece_t new_piece;

    assign sig6 = spi_data;

    always_comb begin
        unique case (spi_data[4:2])
            3'd0: new_piece = tetris_pkg::HERO;
            3'd1: new_piece = tetris_pkg::SMASH_BOY;
            3'd2: new_piece = tetris_pkg::TEEWEE;
            3'd3: new_piece = tetris_pkg::ORANGE_RICKY;
            3'd4: new_piece = tetris_pkg::BLUE_RICKY;
            3'd5: new_piece = tetris_pkg::RHODE_ISLAND_Z;
            3'd6: new_piece = tetris_pkg::CLEVELAND_Z;
            default: new_piece = tetris_pkg::HERO;  // or '0 if you prefer
        endcase
    end

    game_executioner Game_Executioner(.reset(~reset_n), 
        .move_clk(spi_data_valid), 
		.clk(HSOSC_clk),
        .game_clk, 
        .move(tetris_pkg::command_t'(spi_data[1:0])), 
        .move_valid(spi_data[5]), 
        .new_piece, 
        .GAME_state(GAME_next_frame),
        .sig1,
        .sig2,
        .sig3,
        .sig4,
        .sig5,
        .sig6());

    spi SPI(.reset(~reset_n), .clk(HSOSC_clk), .sck, .sdi, .sdo, .ce, .clear(invalidate_spi_data), .data(spi_data), .data_valid(spi_data_valid));

    synchronizer SPI_Invalidator(.clk(HSOSC_clk), .raw_input(spi_data_valid), .synchronized_value(invalidate_spi_data));

    logic synchronized_value, external_clk_sync_debounce;
    // synchronize value
    synchronizer Synchronizer (HSOSC_clk, external_clk_raw, synchronized_value);

    // debounce individual switch
    switch_debouncer #(.debounce_delay(100000)) Switch_Debouncer(HSOSC_clk, ~reset_n, synchronized_value, external_clk_sync_debounce);

    // Once new data has come it and chip enable goes low then assert new frame ready
    assign GAME_new_frame_ready = 1'b1;

    clock_divider #(.div_count(30000000)) Clock_Divider(.clk(HSOSC_clk), .reset(~reset_n), .clk_divided);

    always_ff @(posedge game_clk) begin
        if (~reset_n)   clk_count <= 0;
        else            clk_count <= clk_count + 1;
    end

    assign game_clk = external_clk_sync_debounce;
    // assign game_clk = clk_divided;

    assign debug_led = spi_data_valid;


endmodule  