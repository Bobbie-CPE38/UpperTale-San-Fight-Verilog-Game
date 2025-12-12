module GasterBlasterSprite(
    input wire        i_pix_clk, // 25Mhz
    input wire [9:0]  pixel_x,
    input wire [9:0]  pixel_y,
    input wire [2:0]  six_counter,
    input wire [9:0]  heart_x,
    input wire [8:0]  heart_y,
    output reg        o_sprite_on,
    output wire [7:0] o_data
);

    // Dimension of gaster blaster sprite
    localparam HEAD_W = 30;
    localparam HEAD_H = 40;

    // Border
    localparam LEFT   = 110;
    localparam RIGHT  = 510;
    localparam TOP    = 251;
    localparam BOTTOM = 391;
    localparam THICK  = 6;

    // Play area
    localparam PLAY_LEFT   = LEFT + THICK;
    localparam PLAY_RIGHT  = RIGHT - THICK;

    // Spawn points
    localparam SPAWN_LEFT  = LEFT - HEAD_W;
    localparam SPAWN_RIGHT = RIGHT + THICK;

    // Y position of gaster blasters
    localparam ROW1 = 258;
    localparam ROW2 = 304;
    localparam ROW3 = 355;

    reg [9:0] gx, gy; // Position of gaster
    reg       is_left_glance;

    reg [7:0] shot_timer;
    reg [2:0] latched_idx;

    //------------------------------------------------------------
    // SPAWN & SHOT TIMER
    //------------------------------------------------------------
    always @(posedge i_pix_clk) begin
            case (six_counter)
                3'd1: begin gy <= ROW1; gx <= SPAWN_LEFT;  is_left_glance <= 1'b0; end
                3'd2: begin gy <= ROW2; gx <= SPAWN_LEFT;  is_left_glance <= 1'b0; end
                3'd3: begin gy <= ROW3; gx <= SPAWN_LEFT;  is_left_glance <= 1'b0; end
                3'd4: begin gy <= ROW1; gx <= SPAWN_RIGHT; is_left_glance <= 1'b1; end
                3'd5: begin gy <= ROW2; gx <= SPAWN_RIGHT; is_left_glance <= 1'b1; end
                3'd6: begin gy <= ROW3; gx <= SPAWN_RIGHT; is_left_glance <= 1'b1; end
                default: begin gy <= ROW1; gx <= SPAWN_LEFT; is_left_glance <= 1'b0; end
            endcase
    end
    
    //------------------------------------------------------------
    // DRAW HEAD + BEAM (rectangular draw only)
    //------------------------------------------------------------
    wire inside_head = // Normally it should be pixel_x >= gx, but there's artifact, IDK why
        (pixel_x > gx) && (pixel_x < gx + HEAD_H) &&
        (pixel_y >= gy) && (pixel_y < gy + HEAD_W);
        
    //------------------------------------------------------------
    // ROM PIXEL FETCH (NO ROTATION)
    //------------------------------------------------------------
    reg [11:0] address;
    reg [11:0] lx, ly; // Local sprite coordinates
    always @(*) begin
        lx = pixel_x - gx;
        ly = pixel_y - gy;
    
        if (is_left_glance) begin
            // +90 deg rotate
            address = (HEAD_H-lx-1)*HEAD_W + ly;
        end else begin
            // -90 deg rotate
            address = (lx)*HEAD_W + ly;
        end
    end

    // output "on/off"
    always @(*) begin
        o_sprite_on = inside_head && o_data != 8'h00;
    end
    
    GasterBlasterRom g_rom (
        .i_addr(address),
        .i_pix_clk(i_pix_clk),
        .o_data(o_data)
    );
endmodule
