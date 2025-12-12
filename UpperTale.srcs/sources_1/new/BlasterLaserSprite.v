module BlasterLaserSprite(
    input wire       i_pix_clk, // 25Mhz clk
    input wire [9:0] pixel_x,
    input wire [9:0] pixel_y,
    input wire [2:0] six_counter,
    output reg       o_sprite_on,
    output reg       o_data
);
    // Dimension of laser
    localparam LASER_W = 364; // Width of playable area
    localparam LASER_H = 42;  // Height of platform space
    
    // X position of lasers
    localparam SPAWN_LEFT = 136; // Same for all lasers
    
    // Y positions of platform space
    localparam ROW1 = 245;
    localparam ROW2 = 293;
    localparam ROW3 = 341;
    
    reg [9:0] bl_y; // Current Y position of blaster laser
    
    // Check if x, y is in laser area
    wire inside_laser =
        (pixel_x >= SPAWN_LEFT) && (pixel_x < SPAWN_LEFT + LASER_W) &&
        (pixel_y >= bl_y) && (pixel_y < bl_y + LASER_H);
    
    // Laser position
    always @(posedge i_pix_clk) begin
        o_data <= 8'h00;
        case (six_counter)
            3'd1: bl_y <= ROW1;
            3'd2: bl_y <= ROW2;
            3'd3: bl_y <= ROW3;
            3'd4: bl_y <= ROW1;
            3'd5: bl_y <= ROW2;
            3'd6: bl_y <= ROW3;
            default: bl_y <= ROW1;
        endcase
    end
        
    always @(*) begin
        o_sprite_on = inside_laser && o_data != 8'h00;
    end
    
endmodule
