module BlasterLaserSprite(
    input wire       i_pix_clk, // 25 MHz clk
    input wire       i_rst,       // <<< ADD THIS
    input wire       i_sec_clk, // 1 Hz clk, use to deactivate laser
    input wire       i_freeze,  // Don't shoot during preparation state
    input wire [9:0] pixel_x,
    input wire [9:0] pixel_y,
    input wire [2:0] six_counter,
    output reg [9:0] o_laser_x, // X position of laser
    output reg [9:0] o_laser_y, // Y position of laser
    output reg       o_active, // True => player take damage
    output reg       o_sprite_on,
    output reg [7:0] o_data
);

    // Dimension of laser
    localparam LASER_W = 365; // Width of playable area
    localparam LASER_H = 42;  // Height of platform space
    
    // X position of lasers
    localparam SPAWN_LEFT = 136; // Same for all lasers
    
    // Y position of platform spaces
    localparam ROW1 = 257;
    localparam ROW2 = 303;
    localparam ROW3 = 350;
    
    // Delay before activating the laser
    localparam integer LASER_DELAY = 20_000_000;
    
    // Current Y position of blaster laser
    reg [9:0] bl_y;
    
    // Check if x, y is in laser area
    wire inside_laser =
        (pixel_x >= SPAWN_LEFT) && (pixel_x < SPAWN_LEFT + LASER_W) &&
        (pixel_y >= bl_y) && (pixel_y < bl_y + LASER_H);
    // If you're going to read from ROM, make sure to use inside_laser_d
    
    // Counter for delay 0.8s (count to 20M)
    reg [24:0] delay_counter;
    
    // Rising edge detector to deactivate laser
    reg sec_d1, sec_d2;
    wire sec_rising;
    
    // Sync laser to global sec clk in top module
    reg wait_first_sec;
    
    // Laser position
    always @(posedge i_pix_clk) begin
        case (six_counter)
            3'd1: bl_y <= ROW1;
            3'd2: bl_y <= ROW2;
            3'd3: bl_y <= ROW3;
            3'd4: bl_y <= ROW1;
            3'd5: bl_y <= ROW2;
            3'd6: bl_y <= ROW3;
            default: bl_y <= ROW1;
        endcase
        o_laser_x <= SPAWN_LEFT;
        o_laser_y <= bl_y;
    end
    
    // Clock synchronization
    assign sec_rising = sec_d1 & ~sec_d2;
    always @(posedge i_pix_clk or posedge i_rst) begin
        if (i_rst) begin
            sec_d1 <= 0;
            sec_d2 <= 0;
        end else begin
            sec_d1 <= i_sec_clk;
            sec_d2 <= sec_d1;
        end
    end
    
    // Laser activation
    always @(posedge i_pix_clk or posedge i_rst) begin
        if (i_rst) begin
            delay_counter <= 0;
            o_active <= 0;
            wait_first_sec <= 1;
        end else begin
            if (i_freeze) begin
                delay_counter <= 0;
                o_active <= 0;
                wait_first_sec <= 1;
            end
            else if (wait_first_sec) begin
                delay_counter <= 0;
                o_active <= 0;
                if (sec_rising)
                    wait_first_sec <= 0;
            end
            else if (sec_rising) begin
                delay_counter <= 0;
                o_active <= 0;
            end
            else if (delay_counter < LASER_DELAY) begin
                delay_counter <= delay_counter + 1;
                o_active <= 0;
            end
            else begin
                o_active <= 1;
            end
        end
    end
    
    // Draw laser blaster at current position
    always @(*) begin
        o_data = o_active ? 8'h16 : 8'h2B; // Placeholder
        o_sprite_on = inside_laser && o_data != 8'h00;
    end
    
endmodule
