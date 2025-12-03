// James Kaden Cassidy jkc.cassidy@gmail.com 12/19/2024

// ------------------------------------------------------------
// 1-clock flops
// ------------------------------------------------------------

module flopR #(
    WIDTH = 32
) (
    input   logic               clk,
    input   logic               reset,
    input   logic [WIDTH-1:0]   D,

    output  logic [WIDTH-1:0]   Q
);

    always_ff @(posedge clk) begin
        if (reset)  Q <= '0;
        else        Q <= D;
    end

endmodule


module flopRE #(
    WIDTH = 32
) (
    input   logic               clk,
    input   logic               reset,
    input   logic               en,
    input   logic [WIDTH-1:0]   D,

    output  logic [WIDTH-1:0]   Q
);

    always_ff @(posedge clk) begin
        if (reset)      Q <= '0;
        else if (en)    Q <= D;
    end

endmodule


module flopRS #(
    WIDTH = 32
) (
    input   logic               clk,
    input   logic               reset,
    input   logic               stall,
    input   logic [WIDTH-1:0]   D,

    output  logic [WIDTH-1:0]   Q
);

    always_ff @(posedge clk) begin
        if (reset)          Q <= '0;
        else if (~stall)    Q <= D;
    end

endmodule


module flopRF #(
    WIDTH = 32
) (
    input   logic               clk,
    input   logic               reset,
    input   logic               flush,
    input   logic [WIDTH-1:0]   D,

    output  logic [WIDTH-1:0]   Q
);

    always_ff @(posedge clk) begin
        if (reset | flush)  Q <= '0;
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
    input   logic [WIDTH-1:0]   D,

    output  logic [WIDTH-1:0]   Q
);

    always_ff @(posedge clk) begin
        if (reset)          Q <= '0;
        else if (~stall) begin
            if (flush)      Q <= '0;
            else            Q <= D;
        end
    end

endmodule


// ------------------------------------------------------------
// 2-clock flops
//   - clk_tree: real clock tree clock (single clock domain)
//   - target_clk: async/small-domain clock whose rising edge
//                 we want to react to
//   All Q updates only occur on target_clk rising edges as
//   observed in the clk_tree domain.
// ------------------------------------------------------------

module flopR_2clk #(
    WIDTH = 32
) (
    input  logic               clk_tree,
    input  logic               target_clk,

    input  logic               reset,
    input  logic [WIDTH-1:0]   D,

    output logic [WIDTH-1:0]   Q
);

    // Synchronize target_clk into clk_tree domain and edge-detect
    logic target_meta, target_sync, target_sync_d;

    always_ff @(posedge clk_tree) begin
        if (reset) begin
            target_meta   <= 1'b0;
            target_sync   <= 1'b0;
            target_sync_d <= 1'b0;
        end else begin
            target_meta   <= target_clk;
            target_sync   <= target_meta;
            target_sync_d <= target_sync;
        end
    end

    wire target_rise = target_sync & ~target_sync_d;

    always_ff @(posedge clk_tree) begin
        if (reset)          Q <= '0;
        else if (target_rise) Q <= D;
    end

endmodule


module flopRE_2clk #(
    WIDTH = 32
) (
    input  logic               clk_tree,
    input  logic               target_clk,

    input  logic               reset,
    input  logic               en,
    input  logic [WIDTH-1:0]   D,

    output logic [WIDTH-1:0]   Q
);

    // Synchronize target_clk into clk_tree domain and edge-detect
    logic target_meta, target_sync, target_sync_d;

    always_ff @(posedge clk_tree) begin
        if (reset) begin
            target_meta   <= 1'b0;
            target_sync   <= 1'b0;
            target_sync_d <= 1'b0;
        end else begin
            target_meta   <= target_clk;
            target_sync   <= target_meta;
            target_sync_d <= target_sync;
        end
    end

    wire target_rise = target_sync & ~target_sync_d;

    always_ff @(posedge clk_tree) begin
        if (reset)                  Q <= '0;
        else if (en && target_rise) Q <= D;
    end

endmodule


module flopRS_2clk #(
    WIDTH = 32
) (
    input  logic               clk_tree,
    input  logic               target_clk,

    input  logic               reset,
    input  logic               stall,
    input  logic [WIDTH-1:0]   D,

    output logic [WIDTH-1:0]   Q
);

    // Synchronize target_clk into clk_tree domain and edge-detect
    logic target_meta, target_sync, target_sync_d;

    always_ff @(posedge clk_tree) begin
        if (reset) begin
            target_meta   <= 1'b0;
            target_sync   <= 1'b0;
            target_sync_d <= 1'b0;
        end else begin
            target_meta   <= target_clk;
            target_sync   <= target_meta;
            target_sync_d <= target_sync;
        end
    end

    wire target_rise = target_sync & ~target_sync_d;

    always_ff @(posedge clk_tree) begin
        if (reset)                          Q <= '0;
        else if (~stall && target_rise)     Q <= D;
    end

endmodule


module flopRF_2clk #(
    WIDTH = 32
) (
    input  logic               clk_tree,
    input  logic               target_clk,

    input  logic               reset,
    input  logic               flush,
    input  logic [WIDTH-1:0]   D,

    output logic [WIDTH-1:0]   Q
);

    // Synchronize target_clk into clk_tree domain and edge-detect
    logic target_meta, target_sync, target_sync_d;

    always_ff @(posedge clk_tree) begin
        if (reset) begin
            target_meta   <= 1'b0;
            target_sync   <= 1'b0;
            target_sync_d <= 1'b0;
        end else begin
            target_meta   <= target_clk;
            target_sync   <= target_meta;
            target_sync_d <= target_sync;
        end
    end

    wire target_rise = target_sync & ~target_sync_d;

    always_ff @(posedge clk_tree) begin
        if (reset) begin
            Q <= '0;
        end else if (target_rise) begin
            if (flush)  Q <= '0;
            else        Q <= D;
        end
    end

endmodule


module flopRFS_2clk #(
    WIDTH = 32
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

    // Synchronize target_clk into clk_tree domain and edge-detect
    logic target_meta, target_sync, target_sync_d;

    always_ff @(posedge clk_tree) begin
        if (reset) begin
            target_meta   <= 1'b0;
            target_sync   <= 1'b0;
            target_sync_d <= 1'b0;
        end else begin
            target_meta   <= target_clk;      // 1st stage
            target_sync   <= target_meta;     // 2nd stage (now in clk_tree domain)
            target_sync_d <= target_sync;     // delayed copy for edge detect
        end
    end

    wire target_rise = target_sync & ~target_sync_d;
    wire update      = target_rise & ~stall;

    always_ff @(posedge clk_tree) begin
        if (reset) begin
            Q <= '0;
        end else if (update) begin
            if (flush)  Q <= '0;
            else        Q <= D;
        end
    end

endmodule
