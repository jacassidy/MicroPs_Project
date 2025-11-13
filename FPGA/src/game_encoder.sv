// Game Encoder
// James Kaden Cassidy 
// kacassidy@hmc.edu
// 11/12/2025

module game_encoder (
    output  logic                           GAME_new_frame_ready,
    output  game_state_pkg::game_state_t    GAME_next_frame,

    input   logic                           HSOSC_clk      // 48 MHz
);

    import game_state_pkg::*;

    // Two instances of game_state_t
    game_state_t gs_vertical;
    game_state_t gs_horizontal;

    // Current output frame
    game_state_t current_frame;

    // ----------------------------------------------------------------
    // Timing parameters (based on 48 MHz HSOSC)
    // ----------------------------------------------------------------
    localparam int unsigned HSOSC_FREQ_HZ      = 48_000_000;
    localparam int unsigned HALF_SEC_TICKS     = HSOSC_FREQ_HZ / 2;   // 0.5 s
    localparam int unsigned TENTH_SEC_TICKS    = HSOSC_FREQ_HZ / 10;  // 0.1 s

    localparam int unsigned HALF_SEC_CNT_WIDTH  = $clog2(HALF_SEC_TICKS);
    localparam int unsigned TENTH_SEC_CNT_WIDTH = $clog2(TENTH_SEC_TICKS);

    logic [HALF_SEC_CNT_WIDTH-1:0]  half_sec_cnt;
    logic [TENTH_SEC_CNT_WIDTH-1:0] ready_cnt;

    // 0 = vertical, 1 = horizontal
    logic frame_select;

    // Drive the output
    assign GAME_next_frame = current_frame;

    // ----------------------------------------------------------------
    // Initialize the two game_state patterns (vertical / horizontal)
    // ----------------------------------------------------------------
    initial begin : init_game_states
        integer y;

        // ----------------------------
        // Vertical bars (varying widths)
        // ----------------------------
        logic [19:0] vertical_pattern;

        vertical_pattern = '0;
        vertical_pattern[3:1]   = '1;   // width 3
        vertical_pattern[7:6]   = '1;   // width 2
        vertical_pattern[13:10] = '1;   // width 4
        vertical_pattern[16]    = 1'b1; // width 1
        vertical_pattern[19:18] = '1;   // width 2

        for (y = 0; y < 10; y++) begin
            gs_vertical.screen[y] = vertical_pattern;
        end

        // ----------------------------
        // Horizontal bars (varying thickness)
        // ----------------------------
        for (y = 0; y < 10; y++) begin
            gs_horizontal.screen[y] = '0;
        end

        // Bar 1: thickness 1 row (row 0)
        gs_horizontal.screen[0] = 20'hFFFFF;

        // Bar 2: thickness 2 rows (rows 2–3)
        gs_horizontal.screen[2] = 20'hFFFFF;
        gs_horizontal.screen[3] = 20'hFFFFF;

        // Bar 3: thickness 3 rows (rows 6–8)
        gs_horizontal.screen[6] = 20'hFFFFF;
        gs_horizontal.screen[7] = 20'hFFFFF;
        gs_horizontal.screen[8] = 20'hFFFFF;

        // ----------------------------
        // Init counters / state
        // ----------------------------
        half_sec_cnt          = '0;
        ready_cnt             = '0;
        frame_select          = 1'b0;
        GAME_new_frame_ready  = 1'b0;
        current_frame         = gs_vertical;
    end

    // ----------------------------------------------------------------
    // 0.5 s toggling + 0.1 s "new frame ready" pulse
    // ----------------------------------------------------------------
    always_ff @(posedge HSOSC_clk) begin
        // 0.5 s counter
        if (half_sec_cnt == HALF_SEC_TICKS - 1) begin
            half_sec_cnt <= '0;

            // Toggle which frame we are using
            frame_select <= ~frame_select;
            if (~frame_select)
                current_frame <= gs_horizontal;
            else
                current_frame <= gs_vertical;

            // Start the "new frame ready" pulse
            GAME_new_frame_ready <= 1'b1;
            ready_cnt            <= '0;
        end
        else begin
            half_sec_cnt <= half_sec_cnt + 1;
        end

        // 0.1 s pulse width for GAME_new_frame_ready
        if (GAME_new_frame_ready) begin
            if (ready_cnt == TENTH_SEC_TICKS - 1) begin
                GAME_new_frame_ready <= 1'b0;
            end
            else begin
                ready_cnt <= ready_cnt + 1;
            end
        end
    end

endmodule
