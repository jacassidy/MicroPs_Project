// font_rom_8x16.sv
//
// Generic 8x16 bitmap font ROM.
// Expects font8x16.hex with 256 chars * 16 rows = 4096 bytes,
// one 8-bit hex value per line (row-major: char 0 row0..15, char1 row0..15, ...).

module font_rom_8x16 #(
    parameter int NCHARS = 256,
    parameter int NROWS  = 16
) (
    input  logic [7:0] char_code,
    input  logic [3:0] row,
    output logic [7:0] row_bits
);
    logic [7:0] rom [0:NCHARS*NROWS-1];

    initial begin
        $readmemh("font8x16.hex", rom);
    end

    logic [$clog2(NCHARS*NROWS)-1:0] addr;
    always_comb begin
        addr     = {char_code[7:0], row[3:0]}; // char * 16 + row
        row_bits = rom[addr];
    end
endmodule

