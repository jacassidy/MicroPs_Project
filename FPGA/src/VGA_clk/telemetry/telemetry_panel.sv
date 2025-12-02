// telemetry_panel.sv
//
// Wrapper that takes NUM_SIGNALS labels + values, formats
// "LABEL: 123" style text, and renders it in a box near the top-left.
//
// Depends on:
//   - font_rom_8x16.sv
//   - telemetry_box.sv (from previous message)

module telemetry_panel #(
    parameter vga_pkg::vga_params_t params,

    // Number of signals (rows)
    parameter int NUM_SIGNALS      = 7,

    // Max label length in characters
    parameter int LABEL_LEN        = 10,

    // Max number of decimal digits to display for each value
    parameter int NUM_VALUE_DIGITS = 3,  // 9 bits => 0..511 fits in 3 digits

    // Width of each value in bits
    parameter int VALUE_WIDTH      = 9,

    // Derived: columns = LABEL_LEN + ": " + digits
    parameter int NUM_COLS         = LABEL_LEN + 2 + NUM_VALUE_DIGITS,
    parameter int NUM_ROWS         = NUM_SIGNALS,

    // Location of the box in pixels (top-left corner of text area)
    parameter int BOX_X0           = 0,
    parameter int BOX_Y0           = 0
) (
    // Current pixel being requested by VGA pipeline
    input  logic [params.pixel_x_bits-1:0]  pixel_x_target_next,
    input  logic [params.pixel_y_bits-1:0]  pixel_y_target_next,

    // Telemetry overlay pixel output
    output logic                            telemetry_pixel,

    // Hard-coded labels: label[signal][char]
    // These will typically be driven from localparams or an initial block
    input  logic [7:0]                      label   [NUM_SIGNALS][LABEL_LEN],

    // Values per signal
    input  logic [VALUE_WIDTH-1:0]          value   [NUM_SIGNALS]
);

    // ------------------------------------------------------------------------
    // Internal character buffer: chars[row][col] is what telemetry_box renders
    // ------------------------------------------------------------------------
    logic [7:0] chars [NUM_ROWS][NUM_COLS];

    // Small helper: convert 0..9 to ASCII '0'..'9'
    function automatic [7:0] ascii_digit (input int d);
        ascii_digit = "0" + d[3:0];
    endfunction

    // Decimal encoder: fixed-width NUM_VALUE_DIGITS digits, zero-padded on left
    task automatic encode_decimal_fixed (
        input  logic [VALUE_WIDTH-1:0] v,
        output logic [7:0]             digits [NUM_VALUE_DIGITS]
    );
        int unsigned tmp;
        int i;

        tmp = v;  // implicit zero-extend to int

        for (i = NUM_VALUE_DIGITS-1; i >= 0; i--) begin
            digits[i] = ascii_digit(tmp % 10);
            tmp       = tmp / 10;
        end
    endtask

    // Build "LABEL: 123" into chars[][]
    always_comb begin
		int colon_col;
		int space_col;
		logic [7:0] digits [NUM_VALUE_DIGITS];
        // Default all cells to spaces
        for (int r = 0; r < NUM_ROWS; r++) begin
            for (int c = 0; c < NUM_COLS; c++) begin
                chars[r][c] = " ";
            end
        end

        // For each signal (row)
        for (int s = 0; s < NUM_SIGNALS; s++) begin
            // 1) Copy label (truncate if longer than LABEL_LEN)
            for (int i = 0; i < LABEL_LEN; i++) begin
                chars[s][i] = label[s][i];
            end

            // 2) Colon and space after label
            colon_col = LABEL_LEN;
            space_col = LABEL_LEN + 1;

            if (colon_col < NUM_COLS) chars[s][colon_col] = ":";
            if (space_col < NUM_COLS) chars[s][space_col] = " ";

            // 3) Encode decimal digits
            encode_decimal_fixed(value[s], digits);

            // 4) Place digits immediately after "LABEL: "
            for (int d = 0; d < NUM_VALUE_DIGITS; d++) begin
                int col = LABEL_LEN + 2 + d; // label + ": " + digits
                if (col < NUM_COLS)
                    chars[s][col] = digits[d];
            end
        end
    end

    // ------------------------------------------------------------------------
    // Instantiate telemetry_box anchored at top-left
    // ------------------------------------------------------------------------
    telemetry_box #(
        .params   (params),
        .BOX_X0   (BOX_X0),    // top-left (you can change later)
        .BOX_Y0   (BOX_Y0),
        .NUM_COLS (NUM_COLS),
        .NUM_ROWS (NUM_ROWS)
    ) telemetry_box_i (
        .pixel_x_target_next (pixel_x_target_next),
        .pixel_y_target_next (pixel_y_target_next),
        .pixel_value_next    (telemetry_pixel),
        .chars               (chars)
    );

endmodule
