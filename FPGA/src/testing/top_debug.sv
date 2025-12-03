// Top Debugger
// James Kaden Cassidy 
// kacassidy@hmc.edu
// 11/13/2025

////`include "parameters.svh"
`define COLORS 3

module top_debug #(
        parameter vga_pkg::vga_params_t params                          = vga_pkg::VGA_640x480_60,
        parameter int                   TELEMETRY_NUM_SIGNALS           = 2,
        parameter int                   TELEMETRY_VALUE_WIDTH           = 8,
        parameter int                   TELEMETRY_BASE                  = 2
    )(
        input   logic       reset_n,
        output  logic       h_sync,
        output  logic       v_sync,
        output  logic       pixel_signal_R,         // gated with visible region
        output  logic       pixel_signal_G,         // gated with visible region
        output  logic       pixel_signal_B,

        input   logic       sck,
        input   logic       sdi,
        output  logic       sdo,
        input   logic       ce,

        input   logic       external_clk_raw,
        output  logic       debug_led
    );
	
    // DEBUG
    logic [5:0]                         debug_window_0 [`COLORS][5:0];
    logic [5:0]                         debug_window_1 [`COLORS][5:0];
    logic [5:0]                         debug_window_2 [`COLORS][5:0];
    logic [5:0]                         debug_window_3 [`COLORS][5:0];
    logic [5:0]                         debug_window_4 [`COLORS][5:0];
    logic [5:0]                         debug_window_5 [`COLORS][5:0];
    // 6 sets of debug signals (2ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¾Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â8-bit each)
    logic [7:0]                         debug_singals_0 [2];
    logic [7:0]                         debug_singals_1 [2];
    logic [7:0]                         debug_singals_2 [2];
    logic [7:0]                         debug_singals_3 [2];
    logic [7:0]                         debug_singals_4 [2];
    logic [7:0]                         debug_singals_5 [2];

    // SPI signals

    logic [7:0] spi_data;
    logic clk_divided;
    logic[2:0] new_piece_value, offset;

    logic easy_clk;

    logic [TELEMETRY_VALUE_WIDTH-1:0]   main_telemetry_values [TELEMETRY_NUM_SIGNALS];

    logic game_clk;
    
    // SPI signals
    logic invalidate_spi_data, spi_data_new, spi_data_valid;
    logic spi_data_new_stalled;

    // VGA Signals
    logic   HSOSC_clk, VGA_clk, LSOSC_clk;
    logic   pixel_value_next_R, pixel_value_next_G, pixel_value_next_B;

    logic[params.pixel_x_bits-1:0] pixel_x_target_next;
    logic[params.pixel_y_bits-1:0] pixel_y_target_next;

    // State manager signals
    logic VGA_new_frame_ready, GAME_new_frame_ready;
    
    game_state_pkg::game_state_t GAME_next_frame, VGA_frame;

    logic [3:0] GAME_frame_select;

    logic synchronized_value, external_clk_sync_debounce;

    logic[7:0] clk_count;

    ////----MODULES----////

    assign main_telemetry_values[0] = clk_count;
    assign main_telemetry_values[1] = spi_data;

    vga_controller #(
        .params(params)
    ) VGA_Controller (
        .reset_n(1'b1),
        // pixel addressing (for renderer)
        .pixel_x_target_next,
        .pixel_y_target_next,
        .pixel_value_next_R, 
        .pixel_value_next_G, 
        .pixel_value_next_B,
        // VGA pins
        .h_sync,
        .v_sync,
        .pixel_signal_R, // core will gate to visible region
        .pixel_signal_G, // core will gate to visible region
        .pixel_signal_B, // core will gate to visible region
        .VGA_clk,
        .HSOSC_clk,
        .LSOSC_clk
    );

    state_manager State_Manager(.reset(1'b0), .VGA_new_frame_ready, .GAME_new_frame_ready, 
        .GAME_next_frame, .VGA_frame);

    game_decoder #(
            .params(params), 
            .TELEMETRY_NUM_SIGNALS(2),  
            .TELEMETRY_VALUE_WIDTH(TELEMETRY_VALUE_WIDTH),
            .TELEMETRY_BASE(TELEMETRY_BASE)
        ) Game_Decoder(
            .VGA_new_frame_ready, .VGA_frame, .pixel_x_target_next, .pixel_y_target_next, 
            .pixel_value_next_R, .pixel_value_next_G, .pixel_value_next_B, .v_sync, .telemetry_values(main_telemetry_values),
            .debug_window_0,
            .debug_window_1,
            .debug_window_2,
            .debug_window_3,
            .debug_window_4,
            .debug_window_5,

            // 6 sets of debug signals (2ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â8-bit each)
            .debug_singals_0,
            .debug_singals_1,
            .debug_singals_2,
            .debug_singals_3,
            .debug_singals_4,
            .debug_singals_5        
        );

    //game_encoder Game_Encoder(.GAME_new_frame_ready(), .GAME_next_frame, .GAME_frame_select(spi_data[3:0]));
    tetris_pkg::active_piece_t new_piece;

    synchronizer #(.bits(3)) Offset_determiner(.clk(game_clk), .raw_input(debug_singals_5[1][2:0]+debug_singals_5[1][5:4]), .synchronized_value(offset));

    assign new_piece_value = spi_data[4:2] + offset;

    always_comb begin
        unique case (new_piece_value)
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

    game_executioner #(
            .TELEMETRY_NUM_SIGNALS(2),    
            .TELEMETRY_VALUE_WIDTH(TELEMETRY_VALUE_WIDTH),
            .TELEMETRY_BASE(TELEMETRY_BASE)
        )Game_Executioner(
            .reset(~reset_n), 
            .move_clk(spi_data_new_stalled), 
            .clk(easy_clk),
            .game_clk, 
            .move(tetris_pkg::command_t'(spi_data[1:0])), 
            .move_valid(spi_data[5]), 
            .new_piece, 
            .GAME_state(GAME_next_frame),
            .debug_window_0,
            .debug_window_1,
            .debug_window_2,
            .debug_window_3,
            .debug_window_4,
            .debug_window_5,

            // 6 sets of debug signals (2ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â8-bit each)
            .debug_singals_0,
            .debug_singals_1,
            .debug_singals_2,
            .debug_singals_3,
            .debug_singals_4,
            .debug_singals_5
            );

    spi SPI(.reset(~reset_n), .clk(HSOSC_clk), .sck, .sdi, .sdo, .ce, .clear(invalidate_spi_data), .data(spi_data), .data_valid(spi_data_valid));

    assign spi_data_new = spi_data_valid; //& ~(^spi_data);

    synchronizer SPI_Syncstalldata(.clk(easy_clk), .raw_input(spi_data_new), .synchronized_value(spi_data_new_stalled));
    synchronizer SPI_Invalidator(.clk(easy_clk), .raw_input(spi_data_new_stalled), .synchronized_value(invalidate_spi_data));
    
    // synchronize value
    synchronizer Synchronizer (LSOSC_clk, external_clk_raw, synchronized_value);

    // debounce individual switch
	assign external_clk_sync_debounce = synchronized_value;
    //switch_debouncer #(.debounce_delay(100)) Switch_Debouncer(LSOSC_clk, ~reset_n, synchronized_value, external_clk_sync_debounce);

    // Once new data has come it and chip enable goes low then assert new frame ready
    assign GAME_new_frame_ready = 1'b1;

    clock_divider #(.div_count(4096)) Clock_Divider(.clk(LSOSC_clk), .reset(~reset_n), .clk_divided);

    assign easy_clk = LSOSC_clk;

    always_ff @(posedge game_clk) begin
        if (~reset_n)   clk_count <= 0;
        else            clk_count <= clk_count + 1;
    end

    // assign game_clk = external_clk_sync_debounce;
    //assign game_clk = 1'b1;
    assign game_clk = clk_divided;

    assign debug_led = game_clk;


endmodule  