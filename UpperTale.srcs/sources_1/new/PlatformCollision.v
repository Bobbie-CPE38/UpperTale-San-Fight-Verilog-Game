module PlatformCollision #(
    parameter NUM_LANES = 2
) (
    input  wire        i_pix_clk,            // 25 MHz clk
    input  wire        i_rst,
    input  wire [9:0]  heart_x,              // top-left of heart
    input  wire [9:0]  heart_y,
    input  wire [9:0]  platforms_y0,         // top Y of platforms (from platform_sprite)
    input  wire [9:0]  platforms_y1,
    output reg         o_player_on_platform, // 1 when heart is standing on a platform
    output reg [9:0]   o_platform_y          // Y of platform standing on
);

    // Dimension of Heart
    localparam HEART_W = 24;
    localparam HEART_H = 24;

    // tolerance for landing (number of pixels below or above exact top we accept as landing)
    localparam LAND_TOL = 3;
    
    // Game border coordinate
    localparam BOTTOM = 391;
    localparam THICK  = 6;
    
    localparam PLAY_BOTTOM = BOTTOM - THICK;
    
    // Platform Y positions
    reg [9:0] platforms_y [0:NUM_LANES-1];

    // Heart bottom position
    wire [9:0] heart_bottom = heart_y + HEART_H;
    
    always @(*) begin
        platforms_y[0] = platforms_y0;
        platforms_y[1] = platforms_y1;
    end

    integer i; // To use within for loops
    // Find the platform that player is on
    always @(posedge i_pix_clk or posedge i_rst) begin
        if (i_rst) begin
            o_player_on_platform <= 0;
            o_platform_y <= PLAY_BOTTOM; // ground by default
        end
        else begin
            o_player_on_platform <= 0;
            o_platform_y  <= PLAY_BOTTOM; // ground by default
    
            for (i = 0; i < NUM_LANES; i = i + 1) begin
                if ((heart_bottom >= platforms_y[i] - LAND_TOL) &&
                    (heart_bottom <= platforms_y[i])) begin
                    o_player_on_platform <= 1;
                    o_platform_y  <= platforms_y[i];
                end
            end
        end
    end
endmodule
