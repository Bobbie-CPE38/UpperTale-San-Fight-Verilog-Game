`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12/11/2025 12:06:13 PM
// Design Name: 
// Module Name: platform_rom
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module platform_rom(
    input  wire [11:0] i_addr,     // 64*16 = 1024 entries (10 bits needed)
    input  wire        i_pix_clk,
    output reg  [7:0]  o_data
);

    (*ROM_STYLE="block"*) reg [7:0] memory_array [0:1023];

    initial begin
        $readmemh("platform_tile.mem", memory_array);
    end

    always @(posedge i_pix_clk)
        o_data <= memory_array[i_addr];

endmodule

