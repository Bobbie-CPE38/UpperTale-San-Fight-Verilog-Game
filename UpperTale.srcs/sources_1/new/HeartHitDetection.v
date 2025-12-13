module HeartHitDetection(
    input  wire        i_pix_clk,
    input  wire        i_rst,
    input  wire [9:0]  heart_x, // Top-left position of heart
    input  wire [9:0]  heart_y,
    input  wire [9:0]  laser_x, // Top-left position of blaster laser
    input  wire [9:0]  laser_y,
    input  wire        laser_active,
    output reg         o_hit
);

    // Heart dimension
    localparam HEART_W = 24;
    localparam HEART_H = 24;
    
    // Laser dimension
    localparam LASER_W = 365; // Width of playable area
    localparam LASER_H = 42;  // Height of platform space

    // Check if player (heart) is inside laser
    wire inside_laser =
        laser_active &&
        (heart_x + HEART_W > laser_x) &&
        (heart_x < laser_x + LASER_W) &&
        (heart_y + HEART_H > laser_y) &&
        (heart_y < laser_y + LASER_H);

    always @(posedge i_pix_clk or posedge i_rst) begin
        if (i_rst)
            o_hit <= 0;
        else
            o_hit <= inside_laser;
    end

endmodule
