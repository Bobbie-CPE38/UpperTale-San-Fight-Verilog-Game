module gaster_blaster(
    input wire        i_pix_clk,
    input wire        i_spawn_clk,
    input wire [9:0]  pixel_x,
    input wire [9:0]  pixel_y,
    input wire [2:0]  six_counter,
    input wire [9:0]  heart_x,
    input wire [8:0]  heart_y,
    output reg        o_sprite_on,
    output wire [7:0] o_data,
    output reg        o_shot_active,
    output wire       o_hit
);

    localparam HEAD_W = 30;
    localparam HEAD_H = 40;

    // Border
    localparam LEFT   = 110;
    localparam RIGHT  = 510;
    localparam TOP    = 251;
    localparam BOTTOM = 391;
    localparam THICK  = 6;

    // Play area
    localparam PLAY_LEFT   = LEFT   + THICK;
    localparam PLAY_RIGHT  = RIGHT  - THICK;

    //Beam parameter
    localparam BEAM_THICK = 12;      // ? slightly thicker so oval looks better
    localparam SHOT_TICK  = 2;

    // Spawn points
    localparam SPAWN_LEFT  = LEFT - HEAD_W;
    localparam SPAWN_RIGHT = RIGHT + THICK;

    // vertical spawn rows
    localparam ROW1 = 258;
    localparam ROW2 = 304;
    localparam ROW3 = 355;

    reg [9:0] gx, gy;
    reg       is_left_glance;

    reg [7:0] shot_timer;
    reg [2:0] latched_idx;

    //------------------------------------------------------------
    // DETECT RISING EDGE SPAWN CLOCK
    //------------------------------------------------------------
    reg spawn_clk_d;
    always @(posedge i_pix_clk)
        spawn_clk_d <= i_spawn_clk;

    wire spawn_rising = (i_spawn_clk & ~spawn_clk_d);

    //------------------------------------------------------------
    // SPAWN & SHOT TIMER
    //------------------------------------------------------------
    always @(posedge i_pix_clk) begin
        if (spawn_rising && ~o_shot_active) begin
            latched_idx <= six_counter;
            shot_timer  <= SHOT_TICK;
            o_shot_active <= 1'b1;

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
        else if (spawn_rising && o_shot_active) begin
            if (shot_timer > 0)
                shot_timer <= shot_timer - 1;

            if (shot_timer <= 1)
                o_shot_active <= 1'b0;
        end
    end

    //------------------------------------------------------------
    // BEAM GEOMETRY
    //------------------------------------------------------------
    wire [9:0] beam_x1 = is_left_glance ? (gx + HEAD_W) : PLAY_LEFT;
    wire [9:0] beam_x2 = is_left_glance ? PLAY_RIGHT     : (gx - 1);

    wire [9:0] beam_yc = gy + (HEAD_H >> 1);
    wire [9:0] beam_y1 = beam_yc - (BEAM_THICK >> 1);
    wire [9:0] beam_y2 = beam_y1 + BEAM_THICK - 1;

    //------------------------------------------------------------
    // DRAW HEAD + BEAM (rectangular draw only)
    //------------------------------------------------------------
    wire inside_head =
        (pixel_x >= gx) && (pixel_x < gx + HEAD_W) &&
        (pixel_y >= gy) && (pixel_y < gy + HEAD_H);

    wire inside_beam =
        o_shot_active &&
        (pixel_x >= beam_x1) && (pixel_x <= beam_x2) &&
        (pixel_y >= beam_y1) && (pixel_y <= beam_y2);

    //------------------------------------------------------------
    // ROM PIXEL FETCH (NO ROTATION)
    //------------------------------------------------------------
    wire [9:0] lx = pixel_x - gx;
    wire [9:0] ly = pixel_y - gy;

    wire [11:0] address = ly * HEAD_W + lx;

    GasterBlasterRom Grom (
        .i_addr(address),
        .i_pix_clk(i_pix_clk),
        .o_data(o_data)
    );

    always @(*) begin
        if (inside_head)
            o_sprite_on = (o_data != 8'h00);
        else if (inside_beam)
            o_sprite_on = 1'b1;
        else
            o_sprite_on = 1'b0;
    end

    //------------------------------------------------------------
    // OVAL HITBOX COLLISION
    //------------------------------------------------------------
    // Oval center
    wire [10:0] cx = (beam_x1 + beam_x2) >> 1;
    wire [10:0] cy = beam_yc;

    // Radii
    wire [10:0] a = (beam_x2 - beam_x1) >> 1;   // horizontal radius
    wire [10:0] b = BEAM_THICK >> 1;            // vertical radius

    // ? positions
    wire signed [11:0] dx = heart_x - cx;
    wire signed [11:0] dy = heart_y - cy;

    // Compare:
    //   dx² * b² + dy² * a² <= (a² * b²)
    wire [21:0] dx2 = dx * dx;
    wire [21:0] dy2 = dy * dy;
    wire [21:0] a2  = a  * a;
    wire [21:0] b2  = b  * b;

    wire [43:0] left_side  = dx2 * b2 + dy2 * a2;
    wire [43:0] right_side = a2 * b2;

    assign o_hit = o_shot_active && (left_side <= right_side);

endmodule
