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
    wire [9:0] x; // pixel x position: 10-bit value: 0-1023 : only need 800
    wire [9:0] y; // pixel y position: 10-bit value: 0-1023 : only need 525
    wire active; // high during active pixel drawing
    wire pix_clk; // 25MHz pixel clock
    
    // Color palette
    reg [7:0] palette [0:191];
    wire [7:0] palette_data;
    wire [7:0] palette_addr;
    reg [7:0] palette_addr_d; // 1 clk delay of palette addr to compensate non-blocking logic
    wire palette_done;
    reg init_done;
    
    // Color define
    reg [7:0] BG = 0; // background colour palette value
    reg [7:0] GROUND = 63; // Playarea border color
    
    
    // Platforms
    wire [9:0] platforms_x0;
    wire [9:0] platforms_y0;
    wire [9:0] platforms_x1;
    wire [9:0] platforms_y1;
    wire platform_sprite_on;
    wire [7:0] platform_data;
    
    // Platform collisions
    wire player_on_platform;
    wire [9:0] platform_y;
    
    // Heart
    wire heart_sprite_on;
    wire [7:0] heart_data;
    wire [9:0] heart_x;
    wire [8:0] heart_y;
    
    // Heart hit detection
    wire heart_hit;
    
    // Health bar
    wire hp_bar_sprite_on;
    wire [7:0] hp_bar_data;
    
    // Gaster blaster
    wire [2:0] six_counter;
    wire clk_sec; // 1 second clock
    wire gaster_sprite_on;
    wire [7:0] gaster_data;
    
    // Blaster laser
    wire blaster_laser_active;
    wire blaster_laser_sprite_on;
    wire [9:0] blaster_laser_x;
    wire [9:0] blaster_laser_y;
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
        .i_btn_l(btn_l),
        .i_btn_r(btn_r),
        .i_btn_u(btn_u),
        .i_btn_d(btn_d),
        .i_player_on_platform(player_on_platform),
        .i_platform_y(platform_y),
        .o_data(heart_data),
        .heart_x(heart_x),
        .heart_y(heart_y),
        .o_sprite_on(heart_sprite_on)
    );
    
    HeartHitDetection hhd (
        .i_pix_clk(pix_clk),
        .i_rst(RESET),
        .heart_x(heart_x),
        .heart_y(heart_y),
        .laser_x(blaster_laser_x),
        .laser_y(blaster_laser_y),
        .laser_active(blaster_laser_active),
        .o_hit(heart_hit)
    );
    
    HealthBar hp_bar (
        .i_pix_clk(pix_clk),
        .i_rst(RESET),
        .i_x(x),
        .i_y(y),
        .i_hit(heart_hit),
        .o_sprite_on(hp_bar_sprite_on),
        .o_data(hp_bar_data)
    );

    GasterBlasterSprite gasterblaster_sprite (
        .i_pix_clk(pix_clk),
        .pixel_x(x),
        .pixel_y(y),
        .six_counter(six_counter),
        .heart_x(heart_x),
        .heart_y(heart_y),
        .o_sprite_on(gaster_sprite_on),
        .o_data(gaster_data)
    );
    
    BlasterLaserSprite blaster_laster_sprite (
        .i_pix_clk(pix_clk),
        .i_sec_clk(clk_sec),
        .pixel_x(x),
        .pixel_y(y),
        .six_counter(six_counter),
        .o_laser_x(blaster_laser_x),
        .o_laser_y(blaster_laser_y),
        .o_active(blaster_laser_active),
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
        .o_platforms_x0(platforms_x0),
        .o_platforms_y0(platforms_y0),
        .o_platforms_x1(platforms_x1),
        .o_platforms_y1(platforms_y1),
        .o_data(platform_data)
    );
    
    PlatformCollision platform_collision (
        .i_pix_clk(pix_clk),
        .i_rst(RESET),
        .i_heart_x(heart_x),
        .i_heart_y(heart_y),
        .i_platforms_x0(platforms_x0),
        .i_platforms_y0(platforms_y0),
        .i_platforms_x1(platforms_x1),
        .i_platforms_y1(platforms_y1),
        .o_player_on_platform(player_on_platform),
        .o_platform_y(platform_y)
    );

    ColorPaletteRom palette_rom (
        .i_pix_clk(pix_clk),
        .i_rst(RESET),
        .o_data(palette_data),
        .o_addr(palette_addr),
        .o_done(palette_done)
    );

    // Fill local palette at startup
    always @(posedge pix_clk) begin
        palette_addr_d <= palette_addr;
        if (!init_done) begin
            palette[palette_addr_d] <= palette_data;
            if (palette_done)
                init_done <= 1;
        end
    end

    //------------------------------------------------------------
    // RENDERING PRIORITY
    // 1. Hit flash (red)
    // 2. HP bar
    // 3. Gaster Blaster
    // 4. Ground
    // 5. Heart
    // 6. Platform
    // 7. Laser
    // 8. Background
    //------------------------------------------------------------
    always @ (posedge pix_clk) begin
        if (active && init_done) begin
//                RED   <= palette[8*3] >> 4;
//                GREEN <= palette[8*3+1] >> 4;
//                BLUE  <= palette[8*3+2] >> 4;
            if (heart_hit) begin
                RED <= 4'hF;
                GREEN <= 4'h0;
                BLUE <= 4'h0;
            end
            else if (hp_bar_sprite_on) begin
                RED   <= palette[hp_bar_data*3]   >> 4;
                GREEN <= palette[hp_bar_data*3+1] >> 4;
                BLUE  <= palette[hp_bar_data*3+2] >> 4;
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
                // Temp color
                RED   <= palette[57*3]   >> 4;
                GREEN <= palette[57*3+1] >> 4;
                BLUE  <= palette[57*3+2] >> 4;
            end
            else if (blaster_laser_sprite_on) begin
                RED   <= palette[blaster_laser_data*3]   >> 4;
                GREEN <= palette[blaster_laser_data*3+1] >> 4;
                BLUE  <= palette[blaster_laser_data*3+2] >> 4;
            end
            else begin
                 RED   <= palette[BG*3]   >> 4;
                 GREEN <= palette[BG*3+1] >> 4;
                 BLUE  <= palette[BG*3+2] >> 4;
            end
        end 
        else begin
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
