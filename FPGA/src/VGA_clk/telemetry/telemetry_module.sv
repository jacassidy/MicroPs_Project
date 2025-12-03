// telemetry_module.sv
// James Kaden Cassidy 
// kacassidy@hmce.edu
// 12/2/2025

//
// Displays 7 lines of "LABEL: value" at the top-left using telemetry_box.
//
// Depends on:
//   - vga_pkg::vga_params_t params
//   - telemetry_box.sv
//   - font_rom_8x16.sv (used inside telemetry_box)
//
function automatic int clog_base (int value, int base);
    int v, result;
    begin
        if (value <= 1) return 1;
        if (base  <= 1) $fatal(1, "clog_base: base (%0d) must be > 1", base);

        // We want smallest result such that base**result >= value
        v      = value - 1;
        result = 0;
        while (v > 0) begin
            v = v / base;
            result++;
        end
        return result;
    end
endfunction

module telemetry_module #(
    parameter vga_pkg::vga_params_t             params,
    parameter int                               BOX_X0,
    parameter int                               BOX_Y0,
    parameter int                               TELEMETRY_NUM_SIGNALS,    
    parameter int                               TELEMETRY_VALUE_WIDTH,
    parameter int                               TELEMETRY_BASE
) (
    input  logic                                clk,
    input  logic                                reset,

    // From your VGA controller
    input  logic [params.pixel_x_bits-1:0]      pixel_x_target_next,
    input  logic [params.pixel_y_bits-1:0]      pixel_y_target_next,

    // Telemetry values (9-bit each, e.g. 0..511)
    input  logic [TELEMETRY_VALUE_WIDTH-1:0]    telemetry_values [TELEMETRY_NUM_SIGNALS],

    // Output pixel from telemetry overlay (to OR with your game pixel)
    output logic                                telemetry_pixel
);

    // ------------------------------------------------------------------------
    // Panel configuration
    // ------------------------------------------------------------------------

    localparam int NUM_ROWS         = TELEMETRY_NUM_SIGNALS;
    localparam int NUM_COLS         = clog_base(1 << TELEMETRY_VALUE_WIDTH, TELEMETRY_BASE);

    // Telemetry character buffer that telemetry_box will render
    logic [7:0] telemetry_chars [NUM_ROWS][NUM_COLS];

    // Shared temp for decimal digits (used in always_comb)
    logic [7:0] digits [NUM_COLS];


    // ------------------------------------------------------------------------
    // Helpers: ASCII digit + fixed-width decimal encoder
    // ------------------------------------------------------------------------

    function automatic [7:0] ascii_digit (input int d);
        int d_m10 = d - 10;
        if (d <= 9 && d >= 0) ascii_digit = "0" + d[3:0];  // assumes 0 <= d <= 9
        else                  ascii_digit = "A" + d_m10[3:0];
    endfunction

    task automatic encode_decimal_fixed (
        input  logic [TELEMETRY_VALUE_WIDTH-1:0] v,
        output logic [7:0]             digits_out [NUM_COLS]
    );
        int unsigned tmp;
        int i;

        tmp = v;  // zero-extend to int

        // Fill digits from least-significant to most, left-padded with zeros
        for (i = NUM_COLS-1; i >= 0; i--) begin
            digits_out[i] = ascii_digit(tmp % TELEMETRY_BASE);
            tmp           = tmp / TELEMETRY_BASE;
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
        for (s = 0; s < TELEMETRY_NUM_SIGNALS; s++) begin
            // 3) Encode decimal digits for this value
            encode_decimal_fixed(telemetry_values[s], digits);

            // 4) Place digits immediately after "LABEL: "
            for (d = 0; d < NUM_COLS; d++) begin
                telemetry_chars[s][d] = digits[d];
            end
        end
    end

    // ------------------------------------------------------------------------
    // Telemetry overlay: use telemetry_box anchored at top-left (0,0)
    // ------------------------------------------------------------------------

    logic telemetry_pixel_int;

    telemetry_box #(
        .params   (params),
        .BOX_X0   (BOX_X0),         // top-left corner of screen
        .BOX_Y0   (BOX_Y0),
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
