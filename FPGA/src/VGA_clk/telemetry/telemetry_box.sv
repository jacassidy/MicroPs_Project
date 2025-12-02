// telemetry_box.sv
//
// Text-mode overlay box using 8x16 characters.
// Parameterized by box location and size in characters.

module telemetry_box #(
    parameter vga_pkg::vga_params_t params,

    // Box top-left in pixels
    parameter int BOX_X0    = 400,
    parameter int BOX_Y0    = 16,

    // Number of character columns/rows
    parameter int NUM_COLS  = 20,
    parameter int NUM_ROWS  = 4
) (
    input  logic [params.pixel_x_bits-1:0]  pixel_x_target_next,
    input  logic [params.pixel_y_bits-1:0]  pixel_y_target_next,
    output logic                            pixel_value_next,

    // chars[row][col] = 8-bit ASCII/CP437 code
    input  logic [7:0]                      chars [NUM_ROWS][NUM_COLS]
);

    // Fixed 8x16 font
    localparam int CHAR_W      = 8;
    localparam int CHAR_H      = 16;
    localparam int CHAR_W_LOG2 = 3;  // 2^3 = 8
    localparam int CHAR_H_LOG2 = 4;  // 2^4 = 16

    localparam int BOX_WIDTH   = NUM_COLS * CHAR_W;
    localparam int BOX_HEIGHT  = NUM_ROWS * CHAR_H;

    // Internal signals
    logic inside_box;

    logic [params.pixel_x_bits-1:0] rel_x;
    logic [params.pixel_y_bits-1:0] rel_y;

    logic [$clog2(NUM_COLS)-1:0] col_idx;
    logic [$clog2(NUM_ROWS)-1:0] row_idx;

    logic [CHAR_W_LOG2-1:0] glyph_x; // 0..7
    logic [CHAR_H_LOG2-1:0] glyph_y; // 0..15

    logic [7:0] char_code;
    logic [7:0] glyph_row_bits;

    // Figure out if (x,y) is in the box and which cell/offset it maps to
    always_comb begin
        inside_box = 1'b0;
        rel_x      = '0;
        rel_y      = '0;
        col_idx    = '0;
        row_idx    = '0;
        glyph_x    = '0;
        glyph_y    = '0;
        char_code  = 8'h20; // space

        if ((pixel_x_target_next >= BOX_X0) &&
            (pixel_x_target_next <  BOX_X0 + BOX_WIDTH) &&
            (pixel_y_target_next >= BOX_Y0) &&
            (pixel_y_target_next <  BOX_Y0 + BOX_HEIGHT)) begin

            inside_box = 1'b1;

            rel_x = pixel_x_target_next - BOX_X0;
            rel_y = pixel_y_target_next - BOX_Y0;

            // Character cell indices: divide by 8x16 via shifts.
            col_idx = rel_x >> CHAR_W_LOG2;  // = rel_x / 8
            row_idx = rel_y >> CHAR_H_LOG2;  // = rel_y / 16

            // Pixel inside cell
            glyph_x = rel_x[CHAR_W_LOG2-1:0]; // rel_x % 8
            glyph_y = rel_y[CHAR_H_LOG2-1:0]; // rel_y % 16

            if (row_idx < NUM_ROWS && col_idx < NUM_COLS)
                char_code = chars[row_idx][col_idx];
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
