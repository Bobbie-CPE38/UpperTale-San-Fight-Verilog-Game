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

    // VGA Controller
    wire [9:0] x;
    wire [9:0] y;
    wire active;
    wire pix_clk;
    
    // Color palette
    reg [7:0] palette [0:191];
    
    // Platforms
    wire [9:0] platforms_y0; // 2 platforms
    wire [9:0] platforms_y1;
    wire platform_sprite_on;
    wire [7:0] platform_data;
    
    // Heart
    wire heart_sprite_on;
    wire [7:0] heart_data;
    wire [9:0] heart_posX;
    wire [8:0] heart_posY;
    
    // Gaster blaster
    wire [2:0] six_counter;
    wire clk_sec; // 1 second clock
    wire gaster_sprite_on;
    wire [7:0] gaster_data;
    
    // Blaster laser
    wire blaster_laser_sprite_on;
    wire [7:0] blaster_laser_data;
    
    // Level/Ground
    wire ground_sprite_on;

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

    HeartSprite heart_sprite (
        .i_pix_clk(pix_clk),
        .i_rst(RESET),
        .i_x(x),
        .i_y(y),
        .i_active(active),
        .i_btn_l(btn_l),
        .i_btn_r(btn_r),
        .i_btn_u(btn_u),
        .i_btn_d(btn_d),
        .i_platforms_y0(platforms_y0),
        .i_platforms_y1(platforms_y1),
        .o_data(heart_data),
        .heart_x(heart_posX),
        .heart_y(heart_posY),
        .o_sprite_on(heart_sprite_on)
    );

    GasterBlasterSprite gasterblaster_sprite (
        .i_pix_clk(pix_clk),
        .pixel_x(x),
        .pixel_y(y),
        .six_counter(six_counter),
        .heart_x(heart_posX),
        .heart_y(heart_posY),
        .o_sprite_on(gaster_sprite_on),
        .o_data(gaster_data)
    );
    
    BlasterLaserSprite blaster_laster_sprite (
        .i_pix_clk(pix_clk),
        .pixel_x(x),
        .pixel_y(y),
        .six_counter(six_counter),
        .o_sprite_on(blaster_laser_sprite_on),
        .o_data(blaster_laser_data)
    );

    GroundSprite ground_sprite (
        .pixel_x(x),
        .pixel_y(y),
        .o_sprite_on(ground_sprite_on)
    );
    
    PlatformSprite platform_sprite (
        .i_pix_clk(pix_clk),
        .pixel_x(x),
        .pixel_y(y),
        .i_active(active),
        .o_sprite_on(platform_sprite_on),
        .o_platforms_y0(platforms_y0),
        .o_platforms_y1(platforms_y1),
        .o_data(platform_data)
    );

    // Read color palette
    always @(*) begin
        if (RESET) begin
            $readmemh("pal24bit.mem", palette);
        end
    end
    
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
//            if (gaster_hit) begin
//                RED <= 4'hF;
//                GREEN <= 4'h0;
//                BLUE <= 4'h0;
//            end
//            else 
            if (gaster_sprite_on) begin
                RED   <= palette[gaster_data*3]   >> 4;
                GREEN <= palette[gaster_data*3+1] >> 4;
                BLUE  <= palette[gaster_data*3+2] >> 4;
            end
            else if (blaster_laser_sprite_on) begin
                RED   <= palette[blaster_laser_data*3]   >> 4;
                GREEN <= palette[blaster_laser_data*3+1] >> 4;
                BLUE  <= palette[blaster_laser_data*3+2] >> 4;
            end
            else if (ground_sprite_on) begin
                RED   <= 15;
                GREEN <= 15;
                BLUE  <= 15;
            end
            else if (heart_sprite_on) begin
                RED   <= palette[heart_data*3]   >> 4;
                GREEN <= palette[heart_data*3+1] >> 4;
                BLUE  <= palette[heart_data*3+2] >> 4;
            end
            else if (platform_sprite_on) begin
                RED   <= palette[63*3]   >> 4;
                GREEN <= palette[63*3+1] >> 4;
                BLUE  <= palette[63*3+2] >> 4;
//                RED   <= palette[platform_data*3]   >> 4;
//                GREEN <= palette[platform_data*3+1] >> 4;
//                BLUE  <= palette[platform_data*3+2] >> 4;
            end
            else begin
                // RED   <= palette[COL*3]   >> 4;
                RED   <= 0;
                GREEN <= 15;
                BLUE  <= 0;
                // BLUE  <= palette[COL*3+2] >> 4;
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
