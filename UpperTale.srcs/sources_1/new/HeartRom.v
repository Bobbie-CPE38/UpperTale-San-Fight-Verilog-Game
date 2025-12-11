module HeartRom(
    input wire [9:0] i_addr,    
    input wire       i_pix_clk,
    output reg [7:0] o_data    
    );
    
    (*ROM_STYLE="block"*) reg [7:0] memory_array [0:1199];   
    // 30×40 = 1200

    initial begin
        $readmemh("Undertale.mem", memory_array);
    end
    
    always @(posedge i_pix_clk)
        o_data <= memory_array[i_addr];
endmodule
