`timescale 1ns / 1ps

module HeartSprite(
    input  wire        i_pix_clk,      // 25MHz pixel clock
    input  wire        i_rst,
    input  wire [9:0]  i_x,            // VGA pixel X
    input  wire [9:0]  i_y,            // VGA pixel Y
    input  wire        i_active,
    input  wire        i_btn_l,
    input  wire        i_btn_r,
    input  wire        i_btn_u,
    input  wire        i_btn_d,
    input  wire        i_on_platform,
    input  wire [1:0]  i_platform_idx,
    input  wire [9:0]  i_lane_y1,
    input  wire [9:0]  i_lane_y2,
    input  wire [9:0]  i_lane_y3,
    output reg         o_sprite_on,    // 1=on, 0=off
    output wire [7:0]  o_data,
    output reg [9:0]  heart_x,         // keep 10 bits for X (was 10 previously)
    output reg [8:0]  heart_y,         // keep 9 bits to match Top's expectation
    output wire        o_heart_hit
);

    // Heart ROM
    reg [9:0] address; // 24x24 = 576 pixels
    HeartRom heart_rom (
        .i_addr(address),
        .i_pix_clk(i_pix_clk),
        .o_data(o_data)
    );

    // Heart position and size
    localparam HEART_WIDTH  = 24;
    localparam HEART_HEIGHT = 24;

    // initialize
    initial begin
        heart_x = 320 - HEART_WIDTH/2;
        heart_y = 240 - HEART_HEIGHT/2;
    end

    // Movement logic (pixel clock)
    localparam H_SPEED = 10; // Horizontal
    localparam V_SPEED = 10; // Vertical
    localparam LEFT   = 130;
    localparam RIGHT  = 506;
    localparam TOP    = 251;
    localparam BOTTOM = 391;
    localparam THICK  = 6;

    // INNER playable area
    localparam PLAY_LEFT   = LEFT   + THICK;
    localparam PLAY_RIGHT  = RIGHT  - THICK;
    localparam PLAY_TOP    = TOP    + THICK;
    localparam PLAY_BOTTOM = BOTTOM - THICK;

    // temporary for snapping (10-bit to avoid overflow)
    reg [9:0] snap_y;

    // ---------- Movement / gravity (sequential) ----------
    always @(posedge i_pix_clk or posedge i_rst) begin
        if (i_rst) begin
            heart_x <= PLAY_LEFT + ((PLAY_RIGHT-PLAY_LEFT) - HEART_WIDTH)/2;
            heart_y <= PLAY_TOP  + ((PLAY_BOTTOM-PLAY_TOP) - HEART_HEIGHT)/2;
        end
        else if (i_x == 639 && i_y == 479) begin
            // LEFT
            if (i_btn_l) begin
                if (heart_x >= PLAY_LEFT + H_SPEED)
                    heart_x <= heart_x - H_SPEED;
                else
                    heart_x <= PLAY_LEFT;
            end

            // RIGHT
            if (i_btn_r) begin
                if (heart_x <= (PLAY_RIGHT - HEART_WIDTH - H_SPEED))
                    heart_x <= heart_x + H_SPEED;
                else
                    heart_x <= (PLAY_RIGHT - HEART_WIDTH);
            end

            // UP
            if (i_btn_u) begin
                if (heart_y >= PLAY_TOP + V_SPEED)
                    heart_y <= heart_y - V_SPEED;
                else
                    heart_y <= PLAY_TOP;
            end

            // DOWN
            if (i_btn_d) begin
                if (heart_y <= (PLAY_BOTTOM - HEART_HEIGHT - V_SPEED))
                    heart_y <= heart_y + V_SPEED;
                else
                    heart_y <= (PLAY_BOTTOM - HEART_HEIGHT);
            end

            // Gravity & platform snapping
            if (~i_btn_u) begin
                if (~i_on_platform) begin
                    // falling
                    if (heart_y <= (PLAY_BOTTOM - HEART_HEIGHT - 5))
                        heart_y <= heart_y + 2;
                end else begin
                    // snap to platform top depending on platform index
                    case (i_platform_idx)
                        2'd1: snap_y <= i_lane_y1 - HEART_HEIGHT;
                        2'd2: snap_y <= i_lane_y2 - HEART_HEIGHT;
                        2'd3: snap_y <= i_lane_y3 - HEART_HEIGHT;
                        default: snap_y <= heart_y;
                    endcase
                    // assign lower 9 bits (heart_y is 9-bit)
                    heart_y <= snap_y[8:0];
                end
            end
        end
    end

    // ---------- Draw heart at current position (separate sequential block) ----------
    always @(posedge i_pix_clk) begin
        if (i_active) begin
            if ((i_x >= heart_x) && (i_x < heart_x + HEART_WIDTH) &&
                (i_y >= heart_y) && (i_y < heart_y + HEART_HEIGHT)) begin
                address <= (i_x - heart_x) + ((i_y - heart_y) * HEART_WIDTH);
                o_sprite_on <= 1'b1;
            end else begin
                o_sprite_on <= 1'b0;
            end
        end else begin
            o_sprite_on <= 1'b0;
        end
    end

    heart_collision heart_col_inst (
        .clk(i_pix_clk),
        .reset(i_rst),
        .heart_x(heart_x),
        .heart_y(heart_y),
    
        // connect your attack hitboxes here
        .obj_x(attack_x),
        .obj_y(attack_y),
        .obj_w(attack_w),
        .obj_h(attack_h),
        .obj_active(attack_active),
    
        .collided(o_heart_hit)
    );

endmodule
