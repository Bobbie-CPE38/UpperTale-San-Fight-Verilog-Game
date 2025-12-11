`timescale 1ns / 1ps

module platform_sprite(
    input  wire        i_pix_clk,   // Pixel clock
    input  wire        i_tick,      // Slow tick for bobbing
    input  wire [9:0]  pixel_x,
    input  wire [9:0]  pixel_y,
    input  wire        i_active,
    output reg         o_sprite_on,
    output wire [7:0]   o_data,
    output reg [9:0]   lane_y1,
    output reg [9:0]   lane_y2,
    output reg [9:0]   lane_y3
);

    // Level bounds
    localparam LEFT   = 130;
    localparam RIGHT  = 506;
    localparam THICK  = 6;
    localparam PLAY_LEFT  = LEFT + THICK;   // 136
    localparam PLAY_RIGHT = RIGHT - THICK;  // 504

    // Lane centers
    localparam ROW1 = 258;
    localparam ROW2 = 304;
    localparam ROW3 = 355;

    // Tile properties
    localparam TILE_W = 64;
    localparam TILE_H = 16;

    // Bobbing animation
//    reg [2:0] bob_counter = 0;
//    wire [1:0] bob_phase = bob_counter[2:1]; // 0..3 px

//    always @(posedge i_pix_clk)
//        if (i_tick)
//            bob_counter <= bob_counter + 1;

    // Compute top Y for each lane
    wire [9:0] base_y1 = ROW1 - (TILE_H >> 1);
    wire [9:0] base_y2 = ROW2 - (TILE_H >> 1);
    wire [9:0] base_y3 = ROW3 - (TILE_H >> 1);

    // --- ROM for 64x16 tile ---
    reg  [11:0] rom_addr = 0;
    platform_rom tile_rom (
        .i_addr(rom_addr),
        .i_pix_clk(i_pix_clk),
        .o_data(o_data)
    );

    // --- Helpers for modulo and addressing ---
    wire in_x_range = (pixel_x >= PLAY_LEFT) && (pixel_x <= PLAY_RIGHT);

    wire [6:0] tile_x = (pixel_x - PLAY_LEFT) % TILE_W;  // 0..63
    // tile_y is computed per-lane

    // Output calculation
    always @(*) begin
        o_sprite_on = 0;

//        lane_y1 = base_y1 + bob_phase;
//        lane_y2 = base_y2 + bob_phase;
//        lane_y3 = base_y3 + bob_phase;
        
        lane_y1 = base_y1;
        lane_y2 = base_y2;
        lane_y3 = base_y3;

        rom_addr = 12'd0;

        if (!i_active) begin
            o_sprite_on = 0;
        end else if (in_x_range) begin

            // --- LANE 1 ---
            if (pixel_y >= lane_y1 && pixel_y < lane_y1 + TILE_H) begin
                rom_addr = (pixel_y - lane_y1) * TILE_W + tile_x;
                o_sprite_on = (o_data != 8'h00);
            end

            // --- LANE 2 ---
            else if (pixel_y >= lane_y2 && pixel_y < lane_y2 + TILE_H) begin
                rom_addr = (pixel_y - lane_y2) * TILE_W + tile_x;
                o_sprite_on = (o_data != 8'h00);
            end

            // --- LANE 3 ---
            else if (pixel_y >= lane_y3 && pixel_y < lane_y3 + TILE_H) begin
                rom_addr = (pixel_y - lane_y3) * TILE_W + tile_x;
                o_sprite_on = (o_data != 8'h00);
            end

            else begin
                o_sprite_on = 0;
            end
        end
    end

endmodule
