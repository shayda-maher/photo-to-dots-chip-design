// bayer_dither.v
// Streaming 8-bit grayscale -> 1-bit ordered (Bayer 8x8) dithering.
//
// One pixel in per clock, one pixel out per clock, 2-cycle latency.
//
//   Stage 0: position counters (x, y) track where the incoming pixel sits.
//   Stage 1: look up the Bayer threshold for that (x, y) and register it
//            along with the pixel.
//   Stage 2: compare pixel against threshold -> 1-bit output.
//
// Pixels must arrive in raster order (left->right, top->bottom) with
// in_valid high. IMG_W is the image width in pixels.

module bayer_dither #(
    parameter IMG_W = 128
) (
    input  wire       clk,
    input  wire       rst_n,      // active-low asynchronous reset
    input  wire       in_valid,
    input  wire [7:0] in_pixel,   // 0 = black, 255 = white
    output reg        out_valid,
    output reg        out_bit     // 1 = white, 0 = black
);

    localparam XW = (IMG_W > 1) ? $clog2(IMG_W) : 1;

    // ---------------- Stage 0: position counters ----------------
    reg [XW-1:0] x_cnt;
    reg [2:0]    y_cnt;           // only the low 3 bits matter for an 8x8 matrix

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            x_cnt <= {XW{1'b0}};
            y_cnt <= 3'd0;
        end else if (in_valid) begin
            if (x_cnt == IMG_W - 1) begin
                x_cnt <= {XW{1'b0}};
                y_cnt <= y_cnt + 3'd1;
            end else begin
                x_cnt <= x_cnt + 1'b1;
            end
        end
    end

    // ---------------- Bayer threshold (pure combinational) ----------------
    // The 8x8 Bayer matrix needs no ROM. Let a = x ^ y and b = y (3 bits each).
    // Interleaving their bits as {a0,b0,a1,b1,a2,b2} gives the 6-bit matrix
    // value (0..63). Scaling to 8 bits as (value*4 + 2) gives thresholds from
    // 2 to 254, so pure black (0) is never white and pure white (255) is
    // always white.
    wire [2:0] a = x_cnt[2:0] ^ y_cnt;
    wire [2:0] b = y_cnt;
    wire [5:0] bayer6 = {a[0], b[0], a[1], b[1], a[2], b[2]};
    wire [7:0] thresh = {bayer6, 2'b10};

    // ---------------- Stage 1: register pixel + threshold ----------------
    reg [7:0] s1_pixel;
    reg [7:0] s1_thresh;
    reg       s1_valid;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            s1_pixel  <= 8'd0;
            s1_thresh <= 8'd0;
            s1_valid  <= 1'b0;
        end else begin
            s1_pixel  <= in_pixel;
            s1_thresh <= thresh;
            s1_valid  <= in_valid;
        end
    end

    // ---------------- Stage 2: compare ----------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            out_bit   <= 1'b0;
            out_valid <= 1'b0;
        end else begin
            out_bit   <= (s1_pixel > s1_thresh);
            out_valid <= s1_valid;
        end
    end

endmodule
