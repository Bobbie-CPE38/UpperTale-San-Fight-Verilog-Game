module HeartSprite #(
    parameter NUM_LANES = 2
) (
    input  wire        i_pix_clk,      // 25MHz pixel clock
    input  wire        i_rst,
    input  wire [9:0]  i_x,            // VGA pixel X
    input  wire [9:0]  i_y,            // VGA pixel Y
    input  wire        i_btn_l,
    input  wire        i_btn_r,
    input  wire        i_btn_u,
    input  wire        i_btn_d,
    input  wire        i_player_on_platform,
    input  wire [9:0]  i_platform_y,
    output reg [9:0]   heart_x,        // keep 10 bits for X 
    output reg [8:0]   heart_y,        // keep 9 bits to match Top's expectation
    output reg         o_sprite_on,    // 1=on, 0=off
    output wire [7:0]  o_data          // Sprite data
);

    // Heart position and size
    localparam HEART_WIDTH  = 24;
    localparam HEART_HEIGHT = 24;
    
    // initialize player position
    initial begin
        heart_x = 320 - HEART_WIDTH/2;
        heart_y = 240 - HEART_HEIGHT/2;
    end

    // Area param
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
    
    // Movement parameters
    localparam H_SPEED = 3; // Horizontal
    localparam V_SPEED = 3; // Vertical
    
    // Improved jumping
    localparam JUMP_H    = 55; // pixels
    localparam HANG_TIME = 40;  // frames
    wire on_ground = (heart_y >= PLAY_BOTTOM - HEART_HEIGHT);
    reg jumping;
    wire [9:0] jump_base_y = i_player_on_platform ? i_platform_y : PLAY_BOTTOM;
    reg [9:0] jump_target;
    reg [3:0] hang_counter;     // short pause at top
    reg [3:0] fall_speed;       // gradual gravity
    
    // Check if x, y is in heart area
    wire inside_heart = (i_x >= heart_x) && (i_x < heart_x + HEART_WIDTH) &&
                        (i_y >= heart_y) && (i_y < heart_y + HEART_HEIGHT);
    reg inside_heart_d; // 1 clk delay of inside_heart
    
    // Heart ROM
    reg [9:0] addr; // 24x24 = 576 pixels. 1 clk delay
    
    HeartRom heart_rom (
        .i_addr(addr),
        .i_pix_clk(i_pix_clk),
        .o_data(o_data)
    );
    
    // Horizontal movement
    always @(posedge i_pix_clk or posedge i_rst) begin
        if (i_rst) begin
            heart_x <= PLAY_LEFT + ((PLAY_RIGHT-PLAY_LEFT) - HEART_WIDTH)/2;
        end
        else if (i_x == 639 && i_y == 479) begin
            // Horizontal movement
            if (i_btn_l)
                heart_x <= (heart_x >= PLAY_LEFT + H_SPEED) ? heart_x - H_SPEED : PLAY_LEFT;
            if (i_btn_r)
                heart_x <= (heart_x <= PLAY_RIGHT - HEART_WIDTH - H_SPEED) ? heart_x + H_SPEED : (PLAY_RIGHT - HEART_WIDTH);
        end
    end
    
    // Vertical movement
    always @(posedge i_pix_clk or posedge i_rst) begin
        if (i_rst) begin
            heart_y <= PLAY_TOP  + ((PLAY_BOTTOM-PLAY_TOP) - HEART_HEIGHT)/2;
            jumping       <= 0;
            hang_counter  <= 0;
            fall_speed    <= 0;
            jump_target   <= 0;
        end
        else if (i_x == 639 && i_y == 479) begin
            if (i_btn_d) begin
                heart_y <= (heart_y <= PLAY_BOTTOM - HEART_HEIGHT - V_SPEED) ? heart_y + V_SPEED : (PLAY_BOTTOM - HEART_HEIGHT);
            end
            else if (i_btn_u && (i_player_on_platform || on_ground) &&
                     !jumping && hang_counter==0) begin
                jumping <= 1;
                fall_speed <= 0;
                hang_counter <= 0;
                jump_target <= ((jump_base_y - HEART_HEIGHT - JUMP_H) > PLAY_TOP) ?
                                               (jump_base_y - HEART_HEIGHT - JUMP_H) : PLAY_TOP;
            end
            else if (jumping) begin
                if (heart_y > jump_target && i_btn_u) begin
                    heart_y <= heart_y - V_SPEED;
                end
                else begin
                    hang_counter <= HANG_TIME;
                    jumping <= 0;
                end
            end
            else if (hang_counter > 0) begin
                hang_counter <= hang_counter - 1;
            end
            else if (i_player_on_platform) begin
                heart_y    <= i_platform_y - HEART_HEIGHT;
                fall_speed <= 0;
            end
            else begin
                if (fall_speed < 3)
                    fall_speed <= fall_speed + 1;
                if (heart_y <= PLAY_BOTTOM - HEART_HEIGHT - fall_speed)
                    heart_y <= heart_y + fall_speed; // gravity
                else 
                    heart_y <= PLAY_BOTTOM - HEART_HEIGHT; // ground
            end
        end
    end

    always @(posedge i_pix_clk)
        inside_heart_d <= inside_heart;

    // Calculate address for heart and draw at current position
    always @(*) begin
        addr = (i_x - heart_x) + ((i_y - heart_y) * HEART_WIDTH);
        o_sprite_on = inside_heart_d && o_data != 8'h00;
    end
endmodule
