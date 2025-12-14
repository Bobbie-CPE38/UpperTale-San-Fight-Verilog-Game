module StartImageSprite (
    input  wire        i_pix_clk,
    input  wire        i_rst,
    input  wire [9:0]  pixel_x,
    input  wire [9:0]  pixel_y,
    output reg         o_sprite_on,
    output reg  [7:0]  o_data
);

    // Image properties
    localparam IMG_W  = 374;
    localparam IMG_H  = 208;
    localparam IMG_X0 = 132;
    localparam IMG_Y0 = 110;
    localparam IMG_X1 = IMG_X0 + IMG_W; // exclusive
    localparam IMG_Y1 = IMG_Y0 + IMG_H; // exclusive

    // 374 * 208 = 77792 pixels
    (*ROM_STYLE="block"*)
    reg [7:0] image_mem [0:77791];
    
    // Address = y * width + x
    wire [16:0] addr = img_y * IMG_W + img_x;
    
    wire in_bounds =
        (pixel_x >= IMG_X0) && (pixel_x < IMG_X1) &&
        (pixel_y >= IMG_Y0) && (pixel_y < IMG_Y1);

    // Convert screen coord ? image coord
    wire [9:0] img_x = pixel_x - IMG_X0; // 0..373
    wire [8:0] img_y = pixel_y - IMG_Y0; // 0..207
    
    initial begin
        $readmemh("start_state_text.mem", image_mem);
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
