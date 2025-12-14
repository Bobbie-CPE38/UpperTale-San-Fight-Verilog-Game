module Top(
    input  wire      CLK,   // Onboard clock 100MHz : INPUT Pin W5
    input  wire      RESET, // Reset button : INPUT Pin U18
    output wire      HSYNC, // VGA horizontal sync : OUTPUT Pin P19
    output wire      VSYNC, // VGA vertical sync : OUTPUT Pin R19
    output reg [3:0] RED,   // 4-bit VGA Red
    output reg [3:0] GREEN, // 4-bit VGA Green
    output reg [3:0] BLUE,  // 4-bit VGA Blue
    // Player controls
    input btn_l,
    input btn_r,
    input btn_u,
    input btn_d
 );

    // VGA Controller
    wire [9:0] x; // pixel x position: 10-bit value: 0-1023 : only need 800
    wire [9:0] y; // pixel y position: 10-bit value: 0-1023 : only need 525
    wire active; // high during active pixel drawing
    wire pix_clk; // 25 MHz pixel clock
    
    // Game state
    localparam START = 2'b00;
    localparam GAMEPLAY = 2'b01;
    localparam END = 2'b10;
    localparam READY_DELAY = 25_000_000 * 2; // 25 MHz * 2 sec
    reg [25:0] ready_counter; // Count up to 50M
    reg gameplay_active; // Start actual game
    reg [1:0] state;
    reg [1:0] state_d; // 1 clk delay of state
    wire freeze_hazards = !gameplay_active; // In preparation stage, freeze everything
    
    // Start image
    wire start_sprite_on;
    wire [7:0] start_data;
    
    // End image
    wire end_sprite_on;
    wire [7:0] end_data;

    // Sans
    wire sans_on;
    wire [7:0] sans_data;
    
    // Sans yap (in preparation state)
    wire sans_yap_on;
    wire [7:0] sans_yap_data;

    // Health decor UI
    wire hp_decor_on;
    wire [7:0] hp_decor_data;
    
    // Bottom bar UI
    wire bottom_bar_on;
    wire [7:0] bottom_bar_data;

    // Health num UI
    localparam HP_X0 = 418;  // start X of HP numbers
    localparam HP_Y0 = 405;  // Y of HP numbers
    localparam DIGIT_W = 12;
    localparam DIGIT_SPACE = 3;
    wire hp_tens_on;
    wire hp_ones_on;
    wire hp_slash_on;
    wire max_hp_tens_on;
    wire max_hp_ones_on;
    wire [3:0] hp_tens_digit   = health / 10;
    wire [3:0] hp_ones_digit   = health % 10;
    wire [3:0] max_hp_tens_digit = max_health / 10;
    wire [3:0] max_hp_ones_digit = max_health % 10;
    wire [7:0] hp_tens_data;
    wire [7:0] hp_ones_data;
    wire [7:0] hp_slash_data;
    wire [7:0] max_hp_tens_data;
    wire [7:0] max_hp_ones_data;
    
    // Score UI
    localparam SCORE_X0 = 135;
    localparam SCORE_Y0 = 405;
    wire score_tens_on;
    wire score_ones_on;
    reg [6:0] score;               // 0..99
    wire [3:0] score_tens_digit;
    wire [3:0] score_ones_digit;
    wire [7:0] score_tens_data;
    wire [7:0] score_ones_data;
    assign score_tens_digit = score / 10;
    assign score_ones_digit = score % 10;
    
    // Score result UI (END state)
    wire score_results_on;
    wire [7:0] score_results_data;
    
    // Best score digits (END state)
    wire best_score_tens_on;
    wire best_score_ones_on;
    wire [6:0] best_score; // 0..99, store the best score
    wire [3:0] best_score_tens_digit;
    wire [3:0] best_score_ones_digit;
    wire [7:0] best_score_tens_data;
    wire [7:0] best_score_ones_data;
    assign best_score_tens_digit = best_score / 10;
    assign best_score_ones_digit = best_score % 10;
    
    // Last score digits (END state)
    wire last_score_tens_on;
    wire [7:0] last_score_tens_data;
    wire last_score_ones_on;
    wire [7:0] last_score_ones_data;
    
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
    wire [6:0] health;
    wire [6:0] max_health;
    wire refill_hp = (state == START) && (state_d != START);
    wire hp_bar_sprite_on;
    wire [7:0] hp_bar_data;
    
    // Gaster blaster
    wire [2:0] six_counter;
    wire clk_sec; // 1 second clock
    wire gaster_sprite_on;
    wire [7:0] gaster_data;
    
    // Blaster laser
    wire blaster_laser_active;
    reg blaster_laser_active_d; // 1 clk delay of blaster_laser_active
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
    
    // Image during start state
    StartImageSprite start_sprite (
        .i_pix_clk(pix_clk),
        .i_rst(RESET),
        .pixel_x(x),
        .pixel_y(y),
        .o_sprite_on(start_sprite_on),
        .o_data(start_data)
    );
    
    // Image during end state
    EndImageSprite end_sprite (
        .i_pix_clk(pix_clk),
        .i_rst(RESET),
        .pixel_x(x),
        .pixel_y(y),
        .o_sprite_on(end_sprite_on),
        .o_data(end_data)
    );
    
    // Sans
    SansSprite sans_sprite (
        .i_pix_clk(pix_clk),
        .i_rst(RESET),
        .pixel_x(x),
        .pixel_y(y),
        .o_sprite_on(sans_on),
        .o_data(sans_data)
    );
    
    // Sans yap, in preparation state
    SansYapSprite sans_yap_sprite (
        .i_pix_clk(pix_clk),
        .i_rst(RESET),
        .pixel_x(x),
        .pixel_y(y),
        .o_sprite_on(sans_yap_on),
        .o_data(sans_yap_data)
    );
    
    // HP decoration text
     HpDecorationSprite hp_decor (
        .i_pix_clk(pix_clk),
        .i_rst(RESET),
        .pixel_x(x),
        .pixel_y(y),
        .o_sprite_on(hp_decor_on),
        .o_data(hp_decor_data)
    );
    
    // Bottom Bar decoration UI
    BottomBarSprite bottom_bar_sprite (
        .i_pix_clk(pix_clk),
        .i_rst(RESET),
        .pixel_x(x),
        .pixel_y(y),
        .o_sprite_on(bottom_bar_on),
        .o_data(bottom_bar_data)
    );
    
    //------------------------------------------------------------
    // HP number UI
    //------------------------------------------------------------
    // Tens digit of current HP
    NumberSprite hp_tens_sprite (
        .i_pix_clk(pix_clk),
        .i_rst(RESET),
        .pixel_x(x),
        .pixel_y(y),
        .i_digit_code(hp_tens_digit),
        .i_x0(HP_X0),
        .i_y0(HP_Y0),
        .o_sprite_on(hp_tens_on),
        .o_data(hp_tens_data)
    );
    // Ones digit of current HP
    NumberSprite hp_ones_sprite (
        .i_pix_clk(pix_clk),
        .i_rst(RESET),
        .pixel_x(x),
        .pixel_y(y),
        .i_digit_code(hp_ones_digit),
        .i_x0(HP_X0 + DIGIT_W + DIGIT_SPACE),
        .i_y0(HP_Y0),
        .o_sprite_on(hp_ones_on),
        .o_data(hp_ones_data)
    );
    // Slash sprite
    NumberSprite hp_slash_sprite (
        .i_pix_clk(pix_clk),
        .i_rst(RESET),
        .pixel_x(x),
        .pixel_y(y),
        .i_x0(HP_X0 + 2*(DIGIT_W + DIGIT_SPACE)),
        .i_y0(HP_Y0),
        .i_digit_code(4'd10), // 10 = slash
        .o_sprite_on(hp_slash_on),
        .o_data(hp_slash_data)
    );
    // Tens digit of max HP
    NumberSprite max_hp_tens_sprite (
        .i_pix_clk(pix_clk),
        .i_rst(RESET),
        .pixel_x(x),
        .pixel_y(y),
        .i_digit_code(max_hp_tens_digit),
        .i_x0(HP_X0 + 3*(DIGIT_W + DIGIT_SPACE)),
        .i_y0(HP_Y0),
        .o_sprite_on(max_hp_tens_on),
        .o_data(max_hp_tens_data)
    );
    // Ones digit of max HP
    NumberSprite max_hp_ones_sprite (
        .i_pix_clk(pix_clk),
        .i_rst(RESET),
        .pixel_x(x),
        .pixel_y(y),
        .i_digit_code(max_hp_ones_digit),
        .i_x0(HP_X0 + 4*(DIGIT_W + DIGIT_SPACE)),
        .i_y0(HP_Y0),
        .o_sprite_on(max_hp_ones_on),
        .o_data(max_hp_ones_data)
    );
    
    //------------------------------------------------------------
    // Score number UI
    //------------------------------------------------------------
    // Tens digit of score
    NumberSprite score_tens_sprite (
        .i_pix_clk(pix_clk),
        .i_rst(RESET),
        .pixel_x(x),
        .pixel_y(y),
        .i_digit_code(score_tens_digit),
        .i_x0(SCORE_X0),
        .i_y0(SCORE_Y0),
        .o_sprite_on(score_tens_on),
        .o_data(score_tens_data)
    );
    // Ones digit of score
    NumberSprite score_ones_sprite (
        .i_pix_clk(pix_clk),
        .i_rst(RESET),
        .pixel_x(x),
        .pixel_y(y),
        .i_digit_code(score_ones_digit),
        .i_x0(SCORE_X0 + DIGIT_W + DIGIT_SPACE), // DIGIT_W = 12 from HP setup
        .i_y0(SCORE_Y0),
        .o_sprite_on(score_ones_on),
        .o_data(score_ones_data)
    );
    
    //------------------------------------------------------------
    // Score result UI (END state)
    //------------------------------------------------------------
    // Score results UI (END state)
    ScoreResultsSprite score_results_sprite (
        .i_pix_clk(pix_clk),
        .i_rst(RESET),
        .pixel_x(x),
        .pixel_y(y),
        .o_sprite_on(score_results_on),
        .o_data(score_results_data)
    );
    // Best score
    BestScoreMemory best_score_mem (
        .i_clk(pix_clk),
        .i_rst(RESET),
        .i_score(score),
        .o_best_score(best_score)
    );
    // Tens digit of best score (END state)
    NumberSprite best_score_tens_sprite (
        .i_pix_clk(pix_clk),
        .i_rst(RESET),
        .pixel_x(x),
        .pixel_y(y),
        .i_x0(341),
        .i_y0(344),
        .i_digit_code(best_score_tens_digit),
        .o_sprite_on(best_score_tens_on),
        .o_data(best_score_tens_data)
    );
    // Ones digit of best score (END state)
    NumberSprite best_score_ones_sprite (
        .i_pix_clk(pix_clk),
        .i_rst(RESET),
        .pixel_x(x),
        .pixel_y(y),
        .i_x0(341 + DIGIT_W + DIGIT_SPACE),
        .i_y0(344),
        .i_digit_code(best_score_ones_digit),
        .o_sprite_on(best_score_ones_on),
        .o_data(best_score_ones_data)
    );
    // Tens digit of last score (END state)
    NumberSprite last_score_tens_sprite (
        .i_pix_clk(pix_clk),
        .i_rst(RESET),
        .pixel_x(x),
        .pixel_y(y),
        .i_x0(341),           // END page tens X
        .i_y0(378),           // END page Y
        .i_digit_code(score_tens_digit), // reuse existing score digit
        .o_sprite_on(last_score_tens_on),
        .o_data(last_score_tens_data)
    );
    // Ones digit of last score (END state)
    NumberSprite last_score_ones_sprite (
        .i_pix_clk(pix_clk),
        .i_rst(RESET),
        .pixel_x(x),
        .pixel_y(y),
        .i_x0(341 + DIGIT_W + DIGIT_SPACE),
        .i_y0(378),
        .i_digit_code(score_ones_digit),
        .o_sprite_on(last_score_ones_on),
        .o_data(last_score_ones_data)
    );


    //------------------------------------------------------------
    // GAME Sprites
    //------------------------------------------------------------
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
        .i_refill(refill_hp),
        .i_x(x),
        .i_y(y),
        .i_hit(heart_hit),
        .o_health(health),
        .o_max_health(max_health),
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
        .i_freeze(freeze_hazards),
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

    // 1 clk delay state
    always @(posedge pix_clk or posedge RESET) begin
        if (RESET)
            state_d <= START;
        else
            state_d <= state;
    end
    
    // Score increment
    always @(posedge pix_clk or posedge RESET) begin
        if (RESET) begin
            blaster_laser_active_d <= 0;
            score <= 0;
        end
        else begin
            // Update previous state
            blaster_laser_active_d <= blaster_laser_active;
    
            // Reset score when restarting from END state
            if (state == END && btn_u) begin
                score <= 0;
            end
            else if (state == GAMEPLAY) begin
                // Increment score on rising edge of blaster laser
                if (blaster_laser_active && !blaster_laser_active_d) begin
                    if (score < 99) 
                        score <= score + 1;
                    else
                        score <= 99; // cap at 99
                end
            end
        end
    end
    
    // Fill local palette at startup
    always @(posedge pix_clk) begin
        palette_addr_d <= palette_addr;
        if (!init_done) begin
            palette[palette_addr_d] <= palette_data;
            if (palette_done)
                init_done <= 1;
        end
    end

    // Game state logic
    always @ (posedge pix_clk or posedge RESET) begin
        if (RESET) begin
            state <= START;
            ready_counter <= 0;
            gameplay_active <= 0;
        end
        else begin
            case (state)
                START: begin
                    if (btn_u) begin
                        state <= GAMEPLAY;
                        ready_counter <= 0;
                        gameplay_active <= 0;
                    end
                end
                GAMEPLAY: begin
                    if (!gameplay_active) begin
                        if (ready_counter < READY_DELAY)
                            ready_counter <= ready_counter + 1;
                        else
                            gameplay_active <= 1;
                    end
                    
                    // End game wwhen player dies
                    if (gameplay_active && health == 0)
                        state <= END;
                end
                END: begin
                    if (btn_u) begin
                        state <= START;
                        gameplay_active <= 0;
                    end
                end 
            endcase
        end
    end
        
    //------------------------------------------------------------
    // RENDERING PRIORITY
    // 1. Hit flash (red) when player is hit
    // 2. Current HP digits (tens, ones) and HP slash
    // 3. Max HP digits (tens, ones)
    // 4. Score digits (tens, ones)
    // 5. Bottom Bar UI
    // 6. Sans character sprite
    // 7. HP bar sprite
    // 8. Gaster Blaster sprite
    // 9. Ground
    // 10. Heart sprite
    // 11. Platform sprite
    // 12. Blaster laser sprite
    // 13. Background
    //------------------------------------------------------------
    
    // Render helper
    task set_rgb;
        input [7:0] index;
        begin
            RED   <= palette[index*3]   >> 4;
            GREEN <= palette[index*3+1] >> 4;
            BLUE  <= palette[index*3+2] >> 4;
        end
    endtask
    
    // Rendering logic
    always @(posedge pix_clk) begin    
        if (active && init_done) begin
            case (state)
                START: begin
                    if (start_sprite_on) set_rgb(start_data);
                    else set_rgb(BG); // background
                end
                GAMEPLAY: begin
                    // Temp readyoverlay
                    if (!gameplay_active && x >= 136 && x <= 500 && y >= 257 && y <= 385) begin
                        if (sans_yap_on) set_rgb(sans_yap_data);
                        else set_rgb(BG); // background
                    end
                    else if (heart_hit) begin
                        RED <= 4'hF;
                        GREEN <= 4'h0;
                        BLUE <= 4'h0;
                    end
                    else if (sans_on)                   set_rgb(sans_data);
                    else if (hp_decor_on)               set_rgb(hp_decor_data);
                    else if (bottom_bar_on)             set_rgb(bottom_bar_data);
                    else if (hp_tens_on)                set_rgb(hp_tens_data);
                    else if (hp_ones_on)                set_rgb(hp_ones_data);
                    else if (hp_slash_on)               set_rgb(hp_slash_data);
                    else if (max_hp_tens_on)            set_rgb(max_hp_tens_data);
                    else if (max_hp_ones_on)            set_rgb(max_hp_ones_data);
                    else if (score_tens_on)             set_rgb(score_tens_data);
                    else if (score_ones_on)             set_rgb(score_ones_data);
                    else if (hp_bar_sprite_on)          set_rgb(hp_bar_data);
                    else if (gaster_sprite_on)          set_rgb(gaster_data);
                    else if (ground_sprite_on)          set_rgb(GROUND);
                    else if (heart_sprite_on)           set_rgb(heart_data);
                    else if (platform_sprite_on)        set_rgb(57); // temp platform color
                    else if (blaster_laser_sprite_on)   set_rgb(blaster_laser_data);
                    else set_rgb(BG); // background
                end
                END: begin
                    if (score_results_on)           set_rgb(score_results_data);
                    else if (best_score_tens_on)    set_rgb(best_score_tens_data);
                    else if (best_score_ones_on)    set_rgb(best_score_ones_data);
                    else if (last_score_tens_on)    set_rgb(last_score_tens_data);
                    else if (last_score_ones_on)    set_rgb(last_score_ones_data);
                    else if (end_sprite_on)         set_rgb(end_data);
                    else                            set_rgb(BG); // background
                end
            endcase
        end 
        else begin
            RED   <= 0;
            GREEN <= 0;
            BLUE  <= 0;
        end
    end
endmodule
