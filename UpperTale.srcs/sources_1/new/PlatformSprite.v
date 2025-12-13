module PlatformSprite #(
    parameter NUM_LANES = 2
) (
    input  wire        i_pix_clk,   // Pixel clock
    input  wire [9:0]  pixel_x,
    input  wire [9:0]  pixel_y,
    input  wire        i_active,
    output reg         o_sprite_on,
    output reg [9:0]   o_platforms_x0,
    output reg [9:0]   o_platforms_y0,
    output reg [9:0]   o_platforms_x1,
    output reg [9:0]   o_platforms_y1,
    output wire [7:0]  o_data
);

    // Map bound
    localparam LEFT   = 130;
    localparam RIGHT  = 506;
    localparam THICK  = 6;
    localparam PLAY_LEFT  = LEFT + THICK; // Left edge of playable area: 136
    localparam PLAY_RIGHT = RIGHT - THICK;  // Right edge of playable area: 504

    // Platform properties
    localparam PLATFORM_W = 64;
    localparam PLATFORM_H = 6;
    localparam SPEED = 1;

    // --- ROM for 64x16 tile ---
    reg  [11:0] rom_addr = 0;
    
    // Platforms
    reg [9:0] platforms_x [0:NUM_LANES-1]; // x position of platform
    reg [9:0] next_x; // temp next x position
    reg [9:0] platforms_y [0:NUM_LANES-1]; // y position of platform
    reg signed [9:0] platforms_vx [0:NUM_LANES-1]; // velocity of each platform

    // Read ROM
    platform_rom tile_rom (
        .i_addr(rom_addr),
        .i_pix_clk(i_pix_clk),
        .o_data(o_data)
    );
    
    // Init platform position
    initial begin
        platforms_x[0]   = PLAY_LEFT + 40;
        platforms_y[0]   = 297;
        platforms_vx[0]  = SPEED;

        platforms_x[1]   = PLAY_LEFT + 200;
        platforms_y[1]   = 345;
        platforms_vx[1]  = -SPEED;
    end

    integer i; // To use in for loop
    
    // Movement
    always @(posedge i_pix_clk) begin
        if (pixel_x == 639 && pixel_y == 479) begin
            for (i = 0; i < NUM_LANES; i = i + 1) begin
                next_x = platforms_x[i] + platforms_vx[i];
    
                // Right boundary
                if (next_x + PLATFORM_W >= PLAY_RIGHT) begin
                    platforms_x[i]  <= PLAY_RIGHT - PLATFORM_W;
                    platforms_vx[i] <= -SPEED;
                end
                // Left boundary
                else if (next_x <= PLAY_LEFT) begin
                    platforms_x[i]  <= PLAY_LEFT;
                    platforms_vx[i] <= SPEED;
                end
                // Normal movement
                else begin
                    platforms_x[i] <= next_x;
                end
            end
        end
    end
    
    // Rendering
    always @(*) begin
        o_sprite_on = 0;
        rom_addr    = 12'd0;

        if (i_active) begin
            for (i = 0; i < NUM_LANES; i = i + 1) begin
                if (pixel_x >= platforms_x[i] &&
                    pixel_x <  platforms_x[i] + PLATFORM_W &&
                    pixel_y >= platforms_y[i] &&
                    pixel_y <  platforms_y[i] + PLATFORM_H)
                begin
                    rom_addr =
                        (pixel_y - platforms_y[i]) * PLATFORM_W +
                        (pixel_x - platforms_x[i]);

                    o_sprite_on = (o_data != 8'h00);
                end
            end
        end
    end
    
    // Output platform positions
    always @(*) begin
        o_platforms_x0 = platforms_x[0];
        o_platforms_y0 = platforms_y[0];
        o_platforms_x1 = platforms_x[1];
        o_platforms_y1 = platforms_y[1];
    end
endmodule
