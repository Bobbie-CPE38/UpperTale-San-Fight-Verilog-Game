module PlatformCollision #(
    parameter NUM_LANES = 2
) (
    input  wire        i_pix_clk,            // 25 MHz clk
    input  wire        i_rst,
    input  wire [9:0]  i_heart_x,              // top-left of heart
    input  wire [9:0]  i_heart_y,
    input  wire [9:0]  i_platforms_x0,         // left X of platforms (from platform_sprite)
    input  wire [9:0]  i_platforms_y0,
    input  wire [9:0]  i_platforms_x1,         // top Y of platforms (from platform_sprite)
    input  wire [9:0]  i_platforms_y1,
    output reg         o_player_on_platform, // 1 when heart is standing on a platform
    output reg [9:0]   o_platform_y          // Y of platform standing on
);

    // Heart dimension
    localparam HEART_W = 24;
    localparam HEART_H = 24;
    
    // Platform dimension
    localparam PLATFORM_W = 64;

    // tolerance for landing (number of pixels below or above exact top we accept as landing)
    localparam LAND_TOL = 3;
    
    // Game border coordinate
    localparam BOTTOM = 391;
    localparam THICK  = 6;
    
    // Bottom edge of playable area
    localparam PLAY_BOTTOM = BOTTOM - THICK;
    
    // Platform Y positions
    reg [9:0] platforms_x [0:NUM_LANES-1];
    reg [9:0] platforms_y [0:NUM_LANES-1];

    // Heart bottom position
    wire [9:0] heart_bottom = i_heart_y + HEART_H;
    
    // Init platform arrays
    always @(*) begin
        platforms_x[0] = i_platforms_x0;
        platforms_y[0] = i_platforms_y0;
        platforms_x[1] = i_platforms_x1;
        platforms_y[1] = i_platforms_y1;
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
                if ((i_heart_x + HEART_W > platforms_x[i]) &&
                    (i_heart_x < platforms_x[i] + PLATFORM_W) &&
                    (heart_bottom >= platforms_y[i] - LAND_TOL) &&
                    (heart_bottom <= platforms_y[i])) begin
                    
                    o_player_on_platform <= 1;
                    o_platform_y  <= platforms_y[i];
                end
            end
        end
    end
endmodule
