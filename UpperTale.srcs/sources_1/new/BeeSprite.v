`timescale 1ns / 1ps

module BeeSprite(
    input wire i_clk,
    input wire i_rst,
    input wire [9:0] i_x,
    input wire [9:0] i_y,
    input wire i_active,
    output reg o_sprite_on,    //1:On 0:OFF
    output [7:0] o_data
    );
    
    //Initiate BeeRom code
    reg [9:0] address;              //2^10 = 1024, need 34x27 = 918
    BeeRom bee_vrom (
        .i_addr(address),
        .i_clk(i_clk),
        .o_data(o_data)
    );
    //Set Bee character position and size
    localparam bee_width = 34;       //Bee width in pixel
    localparam bee_height = 27;      //Bee height in pixel
    reg [9:0] bee_x = 320 - bee_width/2;           //Bee X start position
    reg [8:0] bee_y = 240 - bee_height/2;           //Bee Y start position
    
    //Check if xx, yy in confine of Bee character
    always @ (posedge i_clk)
    begin
        if(i_active)
            begin
                // Reaches 1 pixel before sprite start
                if(i_x==bee_x-1 && i_y==bee_y)
                    begin
                        address <= 0;
                        o_sprite_on <= 1;
                    end
                // Current pixel is in the sprite
                if((i_x>bee_x-1) && (i_x<bee_x+bee_width) && (i_y>bee_y) && (i_y<bee_y + bee_height))
                    begin
                        address <= (i_x-bee_x) + ((i_y-bee_y)*bee_width);
                        o_sprite_on <= 1;
                    end
                // Not inside sprite
                else
                    begin
                        o_sprite_on <= 0;
                    end
            end
    end
endmodule
