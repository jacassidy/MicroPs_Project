// telemetry_box.sv
//
// Text-mode overlay box using 8x16 characters.
// Each "row" in chars[NUM_ROWS][NUM_COLS] is treated as one telemetry string.
// Telemetries are displayed horizontally next to each other with configurable
// spacing and power-of-two scaling.

module telemetry_box #(
    parameter vga_pkg::vga_params_t params,

    // Box top-left in pixels
    parameter int BOX_X0    = 400,
    parameter int BOX_Y0    = 16,

    // Number of characters per telemetry string, and number of telemetry strings
    parameter int NUM_COLS  = 20,
    parameter int NUM_ROWS  = 4,

    // Horizontal spacing (in pixels) between telemetry strings
    parameter int TELE_SPACING_PIX = 8,

    // Size scaling: character pixels are expanded by 2^SCALE_LOG2
    // 0 -> 1x, 1 -> 2x, 2 -> 4x, etc.
    parameter int SCALE_LOG2       = 0
) (
    input  logic [params.pixel_x_bits-1:0]  pixel_x_target_next,
    input  logic [params.pixel_y_bits-1:0]  pixel_y_target_next,
    output logic                            pixel_value_next,

    // chars[telemetry_idx][char_idx] = 8-bit ASCII/CP437 code
    input  logic [7:0]                      chars [NUM_ROWS][NUM_COLS]
);

    // Base font size
    localparam int CHAR_W      = 8;
    localparam int CHAR_H      = 16;
    localparam int CHAR_W_LOG2 = $clog2(CHAR_W);  // 3
    localparam int CHAR_H_LOG2 = $clog2(CHAR_H);  // 4

    // Scaling
    localparam int SCALE            = (1 << SCALE_LOG2);
    localparam int CHAR_W_SCALED    = CHAR_W * SCALE;
    localparam int CHAR_H_SCALED    = CHAR_H * SCALE;

    // One telemetry string width in pixels
    localparam int TELEMETRY_WIDTH  = NUM_COLS * CHAR_W_SCALED;

    // Total box width/height (all telemetries laid out horizontally)
    localparam int BOX_WIDTH  = NUM_ROWS * TELEMETRY_WIDTH
                              + (NUM_ROWS - 1) * TELE_SPACING_PIX;
    localparam int BOX_HEIGHT = CHAR_H_SCALED;

    // Internal signals
    logic                               inside_box;

    logic [params.pixel_x_bits-1:0]     rel_x;
    logic [params.pixel_y_bits-1:0]     rel_y;
    logic [params.pixel_x_bits-1:0]     rel_x_in_tele;

    logic [$clog2(NUM_ROWS)-1:0]        tele_idx;
    logic [$clog2(NUM_COLS)-1:0]        col_idx;

    logic [params.pixel_x_bits-1:0]     glyph_x_full;  // 0..(NUM_COLS*8-1)
    logic [CHAR_W_LOG2-1:0]             glyph_x;       // 0..7
    logic [CHAR_H_LOG2-1:0]             glyph_y;       // 0..15

    logic [7:0]                         char_code;
    logic [7:0]                         glyph_row_bits;
    logic                               have_telemetry;

    // Figure out if (x,y) hits any telemetry string and which one
    always_comb begin
        inside_box     = 1'b0;
        have_telemetry = 1'b0;

        rel_x          = '0;
        rel_y          = '0;
        rel_x_in_tele  = '0;

        tele_idx       = '0;
        col_idx        = '0;

        glyph_x_full   = '0;
        glyph_x        = '0;
        glyph_y        = '0;

        char_code      = 8'h20; // space by default

        // First, check if we're within the overall bounding box
        if ((pixel_x_target_next >= BOX_X0) &&
            (pixel_x_target_next <  BOX_X0 + BOX_WIDTH) &&
            (pixel_y_target_next >= BOX_Y0) &&
            (pixel_y_target_next <  BOX_Y0 + BOX_HEIGHT)) begin

            rel_x = pixel_x_target_next - BOX_X0;
            rel_y = pixel_y_target_next - BOX_Y0;

            // Map Y into font row (0..15) with vertical scaling
            glyph_y = (rel_y >> SCALE_LOG2);//[CHAR_H_LOG2-1:0];

            // Find which telemetry block we're in, if any
            have_telemetry = 1'b0;
            for (int t = 0; t < NUM_ROWS; t++) begin
                if (!have_telemetry &&
                    (rel_x >= t * (TELEMETRY_WIDTH + TELE_SPACING_PIX)) &&
                    (rel_x <  t * (TELEMETRY_WIDTH + TELE_SPACING_PIX) + TELEMETRY_WIDTH)) begin

                    have_telemetry = 1'b1;
                    tele_idx       = t[$clog2(NUM_ROWS)-1:0];

                    // X coordinate within this telemetry block
                    rel_x_in_tele  = rel_x - t * (TELEMETRY_WIDTH + TELE_SPACING_PIX);
                end
            end

            if (have_telemetry) begin
                // Horizontal scaling: collapse SCALEx pixels back to 1 font pixel
                glyph_x_full = (rel_x_in_tele >> SCALE_LOG2);

                // Character column and bit within glyph (0..7)
                col_idx = glyph_x_full >> CHAR_W_LOG2;
                glyph_x = glyph_x_full[CHAR_W_LOG2-1:0];

                if (col_idx < NUM_COLS) begin
                    char_code = chars[tele_idx][col_idx];
                    inside_box = 1'b1;
                end
            end
        end
    end

    // Font ROM lookup
    font_rom_8x16 font_rom_i (
        .char_code (char_code),
        .row       (glyph_y),
        .row_bits  (glyph_row_bits)
    );

    // Pick bit; bit 7 = leftmost pixel in row.
    always_comb begin
        if (inside_box)
            pixel_value_next = glyph_row_bits[CHAR_W-1 - glyph_x];
        else
            pixel_value_next = 1'b0;
    end

endmodule
