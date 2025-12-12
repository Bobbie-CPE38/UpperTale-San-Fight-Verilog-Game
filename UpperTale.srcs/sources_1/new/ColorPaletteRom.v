module ColorPaletteRom(
    input  wire i_pix_clk,
    input  wire i_rst,
    output reg  [7:0] o_data,
    output reg  [7:0] o_addr,
    output reg        o_done  // high when all palette bytes have been output
    );
    
    (* ROM_STYLE="block" *)
    reg [7:0] memory_array [0:191];

    initial begin
        $readmemh("pal24bit.mem", memory_array);
    end

    always @(posedge i_pix_clk or posedge i_rst) begin
        if (i_rst) begin
            o_addr <= 0;
            o_done <= 0;
            o_data <= 0;
        end else if (!o_done) begin
            o_data <= memory_array[o_addr];
            if (o_addr == 191)
                o_done <= 1;
            else
                o_addr <= o_addr + 1;
        end
    end
endmodule
