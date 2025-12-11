
`timescale 1ns / 1ps

module BeeRom(
    input wire [9:0] i_addr,    //(9:0) or 2^10 = 1024, need 34x27 = 918
    input wire i_clk,
    output reg [7:0] o_data    //8 bit value from Bee.mem
    );
    
    (*ROM_STYLE="block"*) reg [7:0] memory_array [0:917];   //8 bit value for 918 pixels of Bee (34x27)
    initial begin
        $readmemh("Bee.mem", memory_array);
    end
    
    always @ (posedge i_clk)
        o_data <= memory_array[i_addr];
endmodule
