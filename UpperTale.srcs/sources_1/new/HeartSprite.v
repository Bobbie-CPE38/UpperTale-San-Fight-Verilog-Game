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
    output wire [7:0]  o_data         // Sprite data
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
    localparam H_SPEED = 10; // Horizontal
    localparam V_SPEED = 10; // Vertical
    
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
    
    integer i; // To use in for loop
    // ---------- Movement / gravity (sequential) ----------
    always @(posedge i_pix_clk or posedge i_rst) begin
        if (i_rst) begin
            heart_x <= PLAY_LEFT + ((PLAY_RIGHT-PLAY_LEFT) - HEART_WIDTH)/2;
            heart_y <= PLAY_TOP  + ((PLAY_BOTTOM-PLAY_TOP) - HEART_HEIGHT)/2;
        end
        else if (i_x == 639 && i_y == 479) begin
            // Horizontal movement
            if (i_btn_l)
                heart_x <= (heart_x >= PLAY_LEFT + H_SPEED) ? heart_x - H_SPEED : PLAY_LEFT;
            if (i_btn_r)
                heart_x <= (heart_x <= PLAY_RIGHT - HEART_WIDTH - H_SPEED) ? heart_x + H_SPEED : (PLAY_RIGHT - HEART_WIDTH);
    
            
            // Vertical movement
            if (i_btn_u)
                heart_y <= (heart_y >= PLAY_TOP + V_SPEED) ? heart_y - V_SPEED : PLAY_TOP;
            else if (i_btn_d)
                heart_y <= (heart_y <= PLAY_BOTTOM - HEART_HEIGHT - V_SPEED) ? heart_y + V_SPEED : (PLAY_BOTTOM - HEART_HEIGHT);
            else begin
                // Check if on any platform
                if (i_player_on_platform)
                    heart_y <= i_platform_y-HEART_HEIGHT;
                else if (heart_y <= PLAY_BOTTOM - HEART_HEIGHT - 3)
                    heart_y <= heart_y +3; // gravity
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
