`timescale 1ns / 1ps
// platform_collision.v
// Detects whether a 24x24 heart is standing on one of the 3 platforms.
// Output `on_platform` is asserted when the heart's bottom is resting on top of a platform
// within a small snap window (landing tolerance). Also outputs platform_index (0..3).

module platform_collision(
    input  wire        clk,          // pixel clock (use i_pix_clk)
    input  wire        reset,
    input  wire [9:0]  heart_x,      // top-left of heart
    input  wire [9:0]  heart_y,
    input  wire [9:0]  lane_y1,      // top Y of lane (from platform_sprite)
    input  wire [9:0]  lane_y2,
    input  wire [9:0]  lane_y3,
    input  wire        lane_active1, // if lane exists (1 = present)
    input  wire        lane_active2,
    input  wire        lane_active3,
    output reg         on_platform,  // 1 when heart is standing on a platform
    output reg  [1:0]  platform_index // 0 = none, 1..3 lanes
);

    localparam HEART_W = 24;
    localparam HEART_H = 24;

    // tolerance for landing (number of pixels below or above exact top we accept as landing)
    localparam LAND_TOL = 3;

    wire [9:0] heart_left  = heart_x;
    wire [9:0] heart_right = heart_x + HEART_W - 1;
    wire [9:0] heart_bottom = heart_y + HEART_H - 1;

    // play horizontal extents (platforms only across PLAY_LEFT..PLAY_RIGHT)
    localparam LEFT   = 130;
    localparam THICK  = 6;
    localparam PLAY_LEFT  = LEFT + THICK;
    localparam PLAY_RIGHT = 506 - THICK; // match Top constants

    // helper: check horizontal overlap between heart and platform extents
    function is_horiz_overlap;
        input [9:0] hl, hr;
        begin
            is_horiz_overlap = ~( (hr < PLAY_LEFT) || (hl > PLAY_RIGHT) );
        end
    endfunction

    // Evaluate on pixel clock and latch
    always @(posedge clk) begin
        if (reset) begin
            on_platform <= 0;
            platform_index <= 2'd0;
        end else begin
            on_platform <= 1'b0;
            platform_index <= 2'd0;

            // lane1
            if (lane_active1) begin
                if (is_horiz_overlap(heart_left, heart_right) &&
                    (heart_bottom >= lane_y1 - LAND_TOL) &&
                    (heart_bottom <= lane_y1 + LAND_TOL)) begin
                    on_platform <= 1'b1;
                    platform_index <= 2'd1;
                end
            end

            // lane2
            if (~on_platform && lane_active2) begin
                if (is_horiz_overlap(heart_left, heart_right) &&
                    (heart_bottom >= lane_y2 - LAND_TOL) &&
                    (heart_bottom <= lane_y2 + LAND_TOL)) begin
                    on_platform <= 1'b1;
                    platform_index <= 2'd2;
                end
            end

            // lane3
            if (~on_platform && lane_active3) begin
                if (is_horiz_overlap(heart_left, heart_right) &&
                    (heart_bottom >= lane_y3 - LAND_TOL) &&
                    (heart_bottom <= lane_y3 + LAND_TOL)) begin
                    on_platform <= 1'b1;
                    platform_index <= 2'd3;
                end
            end
        end
    end

endmodule
