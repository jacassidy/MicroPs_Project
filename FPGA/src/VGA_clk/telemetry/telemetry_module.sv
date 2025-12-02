// telemetry_module.sv
//
// Displays 7 lines of "LABEL: value" at the top-left using telemetry_box.
//
// Depends on:
//   - vga_pkg::vga_params_t params
//   - telemetry_box.sv
//   - font_rom_8x16.sv (used inside telemetry_box)
//

module telemetry_module #(
    parameter vga_pkg::vga_params_t params
) (
    input  logic                           clk,
    input  logic                           reset,

    // From your VGA controller
    input  logic [params.pixel_x_bits-1:0] pixel_x_target_next,
    input  logic [params.pixel_y_bits-1:0] pixel_y_target_next,

    // Telemetry values (9-bit each, e.g. 0..511)
    input  logic [8:0]                     sig0,
    input  logic [8:0]                     sig1,
    input  logic [8:0]                     sig2,
    input  logic [8:0]                     sig3,
    input  logic [8:0]                     sig4,
    input  logic [8:0]                     sig5,
    input  logic [8:0]                     sig6,

    // Output pixel from telemetry overlay (to OR with your game pixel)
    output logic                           telemetry_pixel
);

    // ------------------------------------------------------------------------
    // Panel configuration
    // ------------------------------------------------------------------------

    localparam int NUM_SIGNALS      = 7;    // 7 lines
    localparam int LABEL_LEN        = 10;   // max label length
    localparam int NUM_VALUE_DIGITS = 3;    // 9 bits -> 0..511 -> 3 digits
    localparam int VALUE_WIDTH      = 9;

    localparam int NUM_ROWS         = NUM_SIGNALS;
    localparam int NUM_COLS         = LABEL_LEN + 2 + NUM_VALUE_DIGITS;
    //                      label   + ": " + digits

    // Telemetry character buffer that telemetry_box will render
    logic [7:0] telemetry_chars [NUM_ROWS][NUM_COLS];

    // Hard-coded labels: label[signal][char]
    logic [7:0] labels [NUM_SIGNALS][LABEL_LEN];

    // Values as an array for easier indexing in loops
    logic [VALUE_WIDTH-1:0] values [NUM_SIGNALS];

    // Shared temp for decimal digits (used in always_comb)
    logic [7:0] digits [NUM_VALUE_DIGITS];

    // Map individual inputs to array
    assign values[0] = sig0;
    assign values[1] = sig1;
    assign values[2] = sig2;
    assign values[3] = sig3;
    assign values[4] = sig4;
    assign values[5] = sig5;
    assign values[6] = sig6;

    // ------------------------------------------------------------------------
    // Label initialization (hard-coded strings)
    // ------------------------------------------------------------------------

    initial begin
        // Default all labels to spaces
        for (int s = 0; s < NUM_SIGNALS; s++) begin
            for (int i = 0; i < LABEL_LEN; i++) begin
                labels[s][i] = " ";
            end
        end

        // 0: "SCORE     "
        labels[0][0] = "S";
        labels[0][1] = "C";
        labels[0][2] = "O";
        labels[0][3] = "R";
        labels[0][4] = "E";

        // 1: "LINES     "
        labels[1][0] = "L";
        labels[1][1] = "I";
        labels[1][2] = "N";
        labels[1][3] = "E";
        labels[1][4] = "S";

        // 2: "LEVEL     "
        labels[2][0] = "L";
        labels[2][1] = "E";
        labels[2][2] = "V";
        labels[2][3] = "E";
        labels[2][4] = "L";

        // 3: "SPEED     "
        labels[3][0] = "S";
        labels[3][1] = "P";
        labels[3][2] = "E";
        labels[3][3] = "E";
        labels[3][4] = "D";

        // 4: "FPS       "
        labels[4][0] = "F";
        labels[4][1] = "P";
        labels[4][2] = "S";

        // 5: "ROWS      "
        labels[5][0] = "R";
        labels[5][1] = "O";
        labels[5][2] = "W";
        labels[5][3] = "S";

        // 6: "COLS      "
        labels[6][0] = "C";
        labels[6][1] = "O";
        labels[6][2] = "L";
        labels[6][3] = "S";
    end

    // ------------------------------------------------------------------------
    // Helpers: ASCII digit + fixed-width decimal encoder
    // ------------------------------------------------------------------------

    function automatic [7:0] ascii_digit (input int d);
        ascii_digit = "0" + d[3:0];  // assumes 0 <= d <= 9
    endfunction

    task automatic encode_decimal_fixed (
        input  logic [VALUE_WIDTH-1:0] v,
        output logic [7:0]             digits_out [NUM_VALUE_DIGITS]
    );
        int unsigned tmp;
        int i;

        tmp = v;  // zero-extend to int

        // Fill digits from least-significant to most, left-padded with zeros
        for (i = NUM_VALUE_DIGITS-1; i >= 0; i--) begin
            digits_out[i] = ascii_digit(tmp % 10);
            tmp           = tmp / 10;
        end
    endtask

    // ------------------------------------------------------------------------
    // Build "LABEL: 123" lines into telemetry_chars[][]
    // ------------------------------------------------------------------------

    integer r, c, s, d;

    always_comb begin
        // Default all cells to spaces
        for (r = 0; r < NUM_ROWS; r++) begin
            for (c = 0; c < NUM_COLS; c++) begin
                telemetry_chars[r][c] = " ";
            end
        end

        // For each signal (row)
        for (s = 0; s < NUM_SIGNALS; s++) begin
            // 1) Copy label (LABEL_LEN chars)
            for (c = 0; c < LABEL_LEN; c++) begin
                telemetry_chars[s][c] = labels[s][c];
            end

            // 2) Colon and space after label
            if (LABEL_LEN < NUM_COLS)
                telemetry_chars[s][LABEL_LEN] = ":";

            if (LABEL_LEN + 1 < NUM_COLS)
                telemetry_chars[s][LABEL_LEN + 1] = " ";

            // 3) Encode decimal digits for this value
            encode_decimal_fixed(values[s], digits);

            // 4) Place digits immediately after "LABEL: "
            for (d = 0; d < NUM_VALUE_DIGITS; d++) begin
                int col_idx = LABEL_LEN + 2 + d;
                if (col_idx < NUM_COLS)
                    telemetry_chars[s][col_idx] = digits[d];
            end
        end
    end

    // ------------------------------------------------------------------------
    // Telemetry overlay: use telemetry_box anchored at top-left (0,0)
    // ------------------------------------------------------------------------

    logic telemetry_pixel_int;

    telemetry_box #(
        .params   (params),
        .BOX_X0   (0),         // top-left corner of screen
        .BOX_Y0   (100),
        .NUM_COLS (NUM_COLS),
        .NUM_ROWS (NUM_ROWS)
    ) telemetry_box_i (
        .pixel_x_target_next (pixel_x_target_next),
        .pixel_y_target_next (pixel_y_target_next),
        .pixel_value_next    (telemetry_pixel_int),
        .chars               (telemetry_chars)
    );

    // Drive output port
    assign telemetry_pixel = telemetry_pixel_int;

endmodule
