module HeartSprite #(
    parameter NUM_LANES = 2
) (
    input  wire        i_pix_clk,      // 25MHz pixel clock
    input  wire        i_rst,
    input  wire [9:0]  i_x,            // VGA pixel X
    input  wire [9:0]  i_y,            // VGA pixel Y
    input  wire        i_active,
    input  wire        i_btn_l,
    input  wire        i_btn_r,
    input  wire        i_btn_u,
    input  wire        i_btn_d,
    input  wire [9:0]  i_platforms_y0, // Y position of top platform
    input  wire [9:0]  i_platforms_y1, // Y position of top platform
    output wire [7:0]  o_data,         // Sprite data
    output reg [9:0]   heart_x,        // keep 10 bits for X 
    output reg [8:0]   heart_y,        // keep 9 bits to match Top's expectation
    output reg         o_sprite_on     // 1=on, 0=off
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
    
    // Platform position 
    reg        on_platform; // Check if player is on platform
    reg [9:0]  platform_top; // Platform position that player is on
    wire [9:0] i_platforms_y [0:NUM_LANES-1];
    assign i_platforms_y[0] = i_platforms_y0;
    assign i_platforms_y[1] = i_platforms_y1;


    // Movement parameters
    localparam H_SPEED = 10; // Horizontal
    localparam V_SPEED = 10; // Vertical
    
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
            on_platform = 0;
            if (i_btn_u)
                heart_y <= (heart_y >= PLAY_TOP + V_SPEED) ? heart_y - V_SPEED : PLAY_TOP;
            else if (i_btn_d)
                heart_y <= (heart_y <= PLAY_BOTTOM - HEART_HEIGHT - V_SPEED) ? heart_y + V_SPEED : (PLAY_BOTTOM - HEART_HEIGHT);
            else begin
                // Check if on any platform
                platform_top = PLAY_BOTTOM - HEART_HEIGHT;
                for (i = 0; i < NUM_LANES; i = i+1) begin
                    if ((heart_y + HEART_HEIGHT >= i_platforms_y[i] - 3) &&
                        (heart_y + HEART_HEIGHT <= i_platforms_y[i])) begin
                        on_platform = 1;
                        platform_top = i_platforms_y[i] - HEART_HEIGHT;
                    end
                end
                // Set player vertical position
                if (on_platform)
                    heart_y <= platform_top[8:0];
                else if (!i_btn_u && !i_btn_d && heart_y <= PLAY_BOTTOM - HEART_HEIGHT - 3)
                    heart_y <= heart_y + 3; // gravity
                else
                    heart_y <= PLAY_BOTTOM - HEART_HEIGHT;
            end
        end
    end


    // Draw heart at current position
    always @(posedge i_pix_clk) begin
        if (i_active) begin
            // Check if x and y is in Heart area
            if ((i_x >= heart_x) && (i_x < heart_x + HEART_WIDTH) &&
                (i_y >= heart_y) && (i_y < heart_y + HEART_HEIGHT)) begin
                address <= (i_x - heart_x) + ((i_y - heart_y) * HEART_WIDTH);
                o_sprite_on <= 1'b1;
            end
            else begin
                o_sprite_on <= 1'b0;
            end
        end
        else begin
            o_sprite_on <= 1'b0;
        end
    end
endmodule
