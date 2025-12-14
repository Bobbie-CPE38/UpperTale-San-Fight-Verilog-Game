module HealthBar(
    input  wire        i_pix_clk,    // 25 MHz clk
    input  wire        i_rst,
    input  wire        i_refill,     // Refill HP when returning to start state
    input  wire [9:0]  i_x,          // VGA pixel X
    input  wire [9:0]  i_y,          // VGA pixel Y
    input  wire        i_hit,        // Player has been hit
    output reg [6:0]  o_health,     // Current health
    output reg [6:0]  o_max_health, // Max health
    output reg         o_sprite_on,  // 1 if x, y in healthbar area
    output reg [7:0]   o_data        // Sprite data
);

    // Dimension of health bar
    localparam HP_BAR_W = 112;
    localparam HP_BAR_H = 20;
    
    localparam MAX_HP = 10;
    
    // Position of healthbar
    localparam hp_bar_x = 257;
    localparam hp_bar_y = 399;
    
    // Counter for delay 0.2s
    reg [22:0] delay_counter;
    
    // Current health
    reg [6:0] health;
    wire [6:0] health_pixels = (health * HP_BAR_W) / MAX_HP;
    
    // Check if x, y is in healthbar area
    wire inside_hp_bar = (i_x >= hp_bar_x) && (i_x < hp_bar_x + HP_BAR_W) &&
                         (i_y >= hp_bar_y) && (i_y < hp_bar_y + HP_BAR_H);
    reg inside_hp_bar_d; // 1 clk delayed inside_hp_bar
                         
    // Check if x, y is in remaining health area
    wire inside_remaining_hp = (i_x >= hp_bar_x) && (i_x < hp_bar_x + health_pixels) &&
                          (i_y >= hp_bar_y) && (i_y < hp_bar_y + HP_BAR_H);
    reg inside_remaining_hp_d; // 1 clk delayed inside_remaining_hp
    
    // HP logic
    always @(posedge i_pix_clk or posedge i_rst) begin
        if (i_rst || i_refill) begin
            health <= MAX_HP;
            o_health <= MAX_HP;
            o_max_health <= MAX_HP;
            delay_counter <= 0;
        end
        else begin
            if (delay_counter < 5_000_000)
                delay_counter <= delay_counter + 1;
            else
                delay_counter <= 5_000_000; // Stop counting
    
            if (i_hit && delay_counter >= 5_000_000) begin
                if (health > 0)
                    health <= health - 1;
                delay_counter <= 0; // reset counter
            end
            
            o_health <= health;
        end
    end
    
    // 1 clk delayed conditions
    always @(posedge i_pix_clk) begin
        inside_hp_bar_d <= inside_hp_bar;
        inside_remaining_hp_d <= inside_remaining_hp;
    end
        
    // Draw at current position
    always @(*) begin
        o_data = inside_remaining_hp_d ? 8'h3D : 8'h08; // Placeholder
        o_sprite_on = inside_hp_bar_d && o_data != 8'h00;
    end
endmodule
