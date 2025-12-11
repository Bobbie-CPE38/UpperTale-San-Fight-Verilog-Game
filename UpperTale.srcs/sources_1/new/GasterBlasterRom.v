module GasterBlasterRom(
    input  wire [11:0] i_addr,   // address range 0–1199
    input  wire        i_pix_clk,
    output reg  [7:0]  o_data
);

    // 30 × 40 = 1200 entries
    (* ROM_STYLE="block" *)
    reg [7:0] memory_array [0:1199];

    initial begin
        $readmemh("gasterBlasterTransparent.mem", memory_array);
    end

    always @(posedge i_pix_clk) begin
        o_data <= memory_array[i_addr];
    end

endmodule
