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
        if (reset)          Q <= 0;
        else if (~stall) begin
            if (flush)      Q <= 0;
            else            Q <= D;
        end
        
    end

endmodule

module flopRFS_2clk #(
    parameter int WIDTH = 32
) (
    // Clock tree clock (real clock domain)
    input  logic               clk_tree,
    // Asynchronous / target clock whose edges we want to react to
    input  logic               target_clk,

    input  logic               reset,
    input  logic               stall,
    input  logic               flush,
    input  logic [WIDTH-1:0]   D,

    output logic [WIDTH-1:0]   Q
);

    // ------------------------------------------------------------
    // Synchronize target_clk into clk_tree domain and edge-detect
    // ------------------------------------------------------------
    logic target_meta, target_sync, target_sync_d;

    always_ff @(posedge clk_tree) begin
        if (reset) begin
            target_meta   <= 1'b0;
            target_sync   <= 1'b0;
            target_sync_d <= 1'b0;
        end else begin
            target_meta   <= target_clk;      // 1st stage (may metastabilize)
            target_sync   <= target_meta;     // 2nd stage (now in clk_tree domain)
            target_sync_d <= target_sync;     // delayed copy for edge detect
        end
    end

    // One-cycle pulse in clk_tree domain when target_clk rises
    wire target_rise = target_sync & ~target_sync_d;

    // Only update when:
    //  - we are not stalled
    //  - AND this cycle corresponds to a target_clk rising edge
    wire stall_int = stall | ~target_rise;

    // ------------------------------------------------------------
    // Original flopRFS behavior, but gated by stall_int
    // ------------------------------------------------------------
    always_ff @(posedge clk_tree) begin 
        if (reset) begin
            Q <= '0;
        end else if (~stall_int) begin
            if (flush)  Q <= '0;
            else        Q <= D;
        end
    end

endmodule
