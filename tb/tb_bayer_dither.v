// Testbench: streams build/input.hex through the dither module and writes
// the 1-bit results to build/output.txt (one 0/1 per line, raster order).
`timescale 1ns/1ps

module tb_bayer_dither;
    parameter W = 128;
    parameter H = 128;
    localparam N = W * H;

    reg clk = 0;
    reg rst_n = 0;
    reg in_valid = 0;
    reg [7:0] in_pixel = 0;
    wire out_valid;
    wire out_bit;

    reg [7:0] img [0:N-1];
    integer i, fout, written;

    bayer_dither #(.IMG_W(W)) dut (
        .clk(clk), .rst_n(rst_n),
        .in_valid(in_valid), .in_pixel(in_pixel),
        .out_valid(out_valid), .out_bit(out_bit)
    );

    always #5 clk = ~clk;   // 100 MHz

    // Capture every valid output
    always @(posedge clk) begin
        if (out_valid) begin
            $fwrite(fout, "%0d\n", out_bit);
            written = written + 1;
        end
    end

    initial begin
        $dumpfile("build/dither.vcd");
        $dumpvars(0, tb_bayer_dither);

        $readmemh("build/input.hex", img);
        fout = $fopen("build/output.txt", "w");
        written = 0;

        // reset
        #23 rst_n = 1;

        // drive one pixel per clock on the falling edge (avoids races)
        for (i = 0; i < N; i = i + 1) begin
            @(negedge clk);
            in_valid = 1;
            in_pixel = img[i];
        end
        @(negedge clk);
        in_valid = 0;
        in_pixel = 0;

        // flush the 2-stage pipeline
        repeat (5) @(posedge clk);

        $fclose(fout);
        if (written == N)
            $display("PASS: streamed %0d pixels, captured %0d outputs", N, written);
        else
            $display("FAIL: expected %0d outputs, got %0d", N, written);
        $finish;
    end
endmodule
