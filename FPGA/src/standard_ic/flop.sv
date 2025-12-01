//James Kaden Cassidy jkc.cassidy@gmail.com 12/19/2024

module flopR #(
    WIDTH = 32
) (
    input   logic               clk,
    input   logic               reset,
    input   logic[WIDTH-1:0]    D,

    output  logic[WIDTH-1:0]    Q
);

    always_ff @( posedge clk ) begin 
        if (reset)  Q <= 0;
        else        Q <= D;
    end
    
endmodule

module flopRE #(
    WIDTH = 32
) (
    input   logic               clk,
    input   logic               reset,
    input   logic               en,
    input   logic[WIDTH-1:0]    D,

    output  logic[WIDTH-1:0]    Q
);

    always_ff @( posedge clk ) begin 
        if (reset)      Q <= 0;
        else if (en)    Q <= D;
    end

endmodule

module flopRS #(
    WIDTH = 32
) (
    input   logic               clk,
    input   logic               reset,
    input   logic               stall,
    input   logic[WIDTH-1:0]    D,

    output  logic[WIDTH-1:0]    Q
);

    always_ff @( posedge clk ) begin 
        if (reset)      Q <= 0;
        else if (~stall)    Q <= D;
    end

endmodule

module flopRF #(
    WIDTH = 32
) (
    input   logic               clk,
    input   logic               reset,
    input   logic               flush,
    input   logic[WIDTH-1:0]    D,

    output  logic[WIDTH-1:0]    Q
);

    always_ff @( posedge clk ) begin 
        if (reset | flush)  Q <= 0;
        else                Q <= D;
    end

endmodule

module flopRFS #(
    WIDTH = 32
) (
    input   logic               clk,
    input   logic               reset,
    input   logic               stall,
    input   logic               flush,
    input   logic[WIDTH-1:0]    D,

    output  logic[WIDTH-1:0]    Q
);

    always_ff @( posedge clk ) begin 
        if (reset | flush)  Q <= 0;
        else if (~stall)    Q <= D;
    end

endmodule