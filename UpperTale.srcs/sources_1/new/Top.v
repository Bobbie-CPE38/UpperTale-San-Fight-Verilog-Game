`timescale 1ns / 1ps

module Top(
    input wire CLK, // Onboard clock 100MHz : INPUT Pin W5
    input wire RESET, // Reset button : INPUT Pin U18
    output wire HSYNC, // VGA horizontal sync : OUTPUT Pin P19
    output wire VSYNC, // VGA vertical sync : OUTPUT Pin R19    
    output reg [3:0] RED, // 4-bit VGA Red
    output reg [3:0] GREEN, // 4-bit VGA Green
    output reg [3:0] BLUE, // 4-bit VGA Blue
    input btn_l,
    input btn_r,
    input btn_u,
    input btn_d
    );

    //------------------------------------------------------------
    // VGA Controller
    //------------------------------------------------------------
    wire [9:0] x;
    wire [9:0] y;
    wire active;
    wire pix_clk;

    vga640x480 display (
        .i_clk(CLK),
        .i_rst(RESET),
        .o_hsync(HSYNC),
        .o_vsync(VSYNC),
        .o_x(x),
        .o_y(y),
        .o_active(active),
        .o_pix_clk(pix_clk)
    );

    //------------------------------------------------------------
    // Heart Sprite
    //------------------------------------------------------------
    wire heart_sprite_on;
    wire [7:0] heart_data;

    wire [9:0] heart_posX;
    wire [8:0] heart_posY;

    HeartSprite heart_display (
            .i_pix_clk(pix_clk),
            .i_rst(RESET),
            .i_x(x),
            .i_y(y),
            .i_active(active),
            .i_btn_l(btn_l),
            .i_btn_r(btn_r),
            .i_btn_u(btn_u),
            .i_btn_d(btn_d),
    
            // platform inputs (connected to platform modules below)
            .i_on_platform(on_platform),
            .i_platform_idx(platform_idx),
            .i_lane_y1(lane1_y),
            .i_lane_y2(lane2_y),
            .i_lane_y3(lane3_y),
            .o_sprite_on(heart_sprite_on),
            .o_data(heart_data),
            .heart_x(heart_posX),
            .heart_y(heart_posY),
            .o_heart_hit(heart_hit_internal)
        );

    //------------------------------------------------------------
    // Gaster Blaster
    //------------------------------------------------------------
    wire gaster_sprite_on;
    wire [7:0] gaster_data;

    wire gaster_shot_active;
    wire gaster_hit; // <-- hit signal used for rendering

    gaster_blaster GasterDisplay (
        .i_pix_clk(pix_clk),
        .i_spawn_clk(clk_sec),
        .pixel_x(x),
        .pixel_y(y),
        .six_counter(six_counter),
        .heart_x(heart_posX),
        .heart_y(heart_posY),
        .o_sprite_on(gaster_sprite_on),
        .o_data(gaster_data),
        .o_shot_active(gaster_shot_active),
        .o_hit(gaster_hit)
    );

    //------------------------------------------------------------
    // Level / Ground
    //------------------------------------------------------------
    wire ground_sprite_on;
    level_display leve1_Sprite(
        .pixel_x(x),
        .pixel_y(y),
        .o_sprite_on(ground_sprite_on)
    );
    
    wire platform_sprite_on;
    wire [7:0]
    wire [9:0] lane1_y, lane2_y, lane3_y;
    platform_sprite Psprite (
        .i_pix_clk(pix_clk),
        .i_tick(clk_sec),    // 1Hz or your game tick (for subtle bob)
        .pixel_x(x),
        .pixel_y(y),
        .i_active(active),
        .o_sprite_on(platform_sprite_on),
        .lane_y1(lane1_y),
        .lane_y2(lane2_y),
        .lane_y3(lane3_y)
    );
    
    wire on_platform;
    wire [1:0] platform_idx;
    
    platform_collision Pcol (
        .clk(pix_clk),
        .reset(RESET),
        .heart_x(heart_posX),
        .heart_y(heart_posY),
        .lane_y1(lane1_y),
        .lane_y2(lane2_y),
        .lane_y3(lane3_y),
        .lane_active1(1'b1),
        .lane_active2(1'b1),
        .lane_active3(1'b1),
        .on_platform(on_platform),
        .platform_index(platform_idx)
    );



    //------------------------------------------------------------
    // Palette Memory
    //------------------------------------------------------------
    reg [7:0] palette [0:191];
    reg [7:0] COL = 0;
    reg [7:0] GROUND = 63;

    initial begin
        $readmemh("pal24bit.mem", palette);
    end

    //------------------------------------------------------------
    // RENDERING PRIORITY
    // 1. Hit flash (red)
    // 2. Gaster Blaster
    // 3. Ground
    // 4. Heart
    // 5. Background
    //------------------------------------------------------------
    always @ (posedge pix_clk) begin
        if (active) begin
            //Debug when hit
            if (gaster_hit) begin
                RED <= 4'hF;
                GREEN <= 4'h0;
                BLUE <= 4'h0;
            end
            else if (gaster_sprite_on) begin
                RED   <= palette[gaster_data*3]   >> 4;
                GREEN <= palette[gaster_data*3+1] >> 4;
                BLUE  <= palette[gaster_data*3+2] >> 4;
            end
            else if (ground_sprite_on) begin
                RED   <= palette[GROUND*3]   >> 4;
                GREEN <= palette[GROUND*3+1] >> 4;
                BLUE  <= palette[GROUND*3+2] >> 4;
            end
            else if (heart_sprite_on) begin
                RED   <= palette[heart_data*3]   >> 4;
                GREEN <= palette[heart_data*3+1] >> 4;
                BLUE  <= palette[heart_data*3+2] >> 4;
            end
            else if (platform_sprite_on) begin
                RED   <= palette[heart_data*3]   >> 4;
                GREEN <= palette[heart_data*3+1] >> 4;
                BLUE  <= palette[heart_data*3+2] >> 4;
            end
            else begin
                RED   <= palette[COL*3]   >> 4;
                GREEN <= palette[COL*3+1] >> 4;
                BLUE  <= palette[COL*3+2] >> 4;
            end

        end else begin
            RED   <= 0;
            GREEN <= 0;
            BLUE  <= 0;
        end
    end

    //------------------------------------------------------------
    // Clock divider + Random gen
    //------------------------------------------------------------
    wire clk_sec;
    wire [2:0] six_counter;

    clk_div_player_control cts(
        .rst_ni(RESET),
        .clk_i(CLK),
        .clk_o(clk_sec)
    );

    prime_random_gen random_generator (
        .clk(pix_clk),
        .rst(RESET),
        .enable(clk_sec),
        .rand_out(six_counter)
    );

endmodule
