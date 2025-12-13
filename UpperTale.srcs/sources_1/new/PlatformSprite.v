module PlatformSprite #(
    parameter NUM_LANES = 2
) (
    input  wire        i_pix_clk,   // Pixel clock
    input  wire [9:0]  pixel_x,
    input  wire [9:0]  pixel_y,
    input  wire        i_active,
    output reg         o_sprite_on,
    output reg [9:0]   o_platforms_y0,
    output reg [9:0]   o_platforms_y1,
    output wire [7:0]  o_data
);

    // Map bound
    localparam LEFT   = 130;
    localparam RIGHT  = 506;
    localparam THICK  = 6;
    localparam PLAY_LEFT  = LEFT + THICK; // Left edge of playable area: 136
    localparam PLAY_RIGHT = RIGHT - THICK;  // Right edge of playable area: 504

    // Tile dimension
    localparam TILE_W = 64;
    localparam TILE_H = 16;

    // --- ROM for 64x16 tile ---
    reg  [11:0] rom_addr = 0;
    
    // Platforms Y positions
    reg [9:0] ROWS [0:NUM_LANES-1];
    // Init platforms Y position
    initial begin
        ROWS[0] = 287; // Top platform
        ROWS[1] = 335; // Bottom platform
    end

    // Check if x position is in platform area
    wire in_x_range = (pixel_x >= PLAY_LEFT) && (pixel_x <= PLAY_RIGHT);
    
    wire [6:0] tile_x = (pixel_x - PLAY_LEFT) % TILE_W;  // 0..63

    platform_rom tile_rom (
        .i_addr(rom_addr),
        .i_pix_clk(i_pix_clk),
        .o_data(o_data)
    );

    integer i; // To use in for loop
    // Output calculation
    always @(*) begin
        o_sprite_on = 0;
        rom_addr = 12'd0;
        
        // Export ROWS into module outputs
        o_platforms_y0 = ROWS[0];
        o_platforms_y1 = ROWS[1];

        if (i_active && in_x_range) begin
            for (i = 0; i < NUM_LANES; i = i + 1) begin
                if (pixel_y >= ROWS[i] &&
                    pixel_y <  ROWS[i] + TILE_H)
                begin
                    rom_addr = (pixel_y - ROWS[i]) * TILE_W + tile_x;
                    o_sprite_on = (o_data != 8'h00);
                end
            end
        end
    end
endmodule
