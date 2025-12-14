module HpDecorationSprite (
    input  wire        i_pix_clk,
    input  wire        i_rst,
    input  wire [9:0]  pixel_x,
    input  wire [9:0]  pixel_y,
    output reg         o_sprite_on,
    output reg  [7:0]  o_data
);

    // Image properties for HP decoration
    localparam IMG_W  = 372;
    localparam IMG_H  = 15;
    localparam IMG_X0 = 27;
    localparam IMG_Y0 = 405;
    localparam IMG_X1 = IMG_X0 + IMG_W; // exclusive
    localparam IMG_Y1 = IMG_Y0 + IMG_H; // exclusive

    // 372 * 15 = 5580 pixels
    (*ROM_STYLE="block"*)
    reg [7:0] image_mem [0:5579];
    
    // Convert screen coordinates to image coordinates
    wire [9:0] img_x = pixel_x - IMG_X0; // 0..371
    wire [3:0] img_y = pixel_y - IMG_Y0; // 0..14

    // Address in memory = y * width + x
    wire [12:0] addr = img_y * IMG_W + img_x;
    
    // Check if the current pixel is within the sprite bounds
    wire in_bounds =
        (pixel_x >= IMG_X0) && (pixel_x < IMG_X1) &&
        (pixel_y >= IMG_Y0) && (pixel_y < IMG_Y1);
    
    initial begin
        $readmemh("hp_decoration.mem", image_mem);
    end
    
    always @(posedge i_pix_clk or posedge i_rst) begin
        if (i_rst) begin
            o_sprite_on <= 1'b0;
            o_data      <= 8'd0;
        end 
        else if (in_bounds && image_mem[addr] != 8'd0) begin
            o_sprite_on <= 1'b1;
            o_data      <= image_mem[addr];
        end 
        else begin
            o_sprite_on <= 1'b0;
            o_data      <= 8'd0;
        end
    end
endmodule
