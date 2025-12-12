`timescale 1ns / 1ps

// Testbench for the topModule, designed to observe timing and control signals.
module TopSim;
    reg clk;
    reg reset;
    reg switch_up;
    reg switch_down;
    reg switch_left;
    reg switch_right;
    
    wire HS, VS;
    wire [3:0] RED, GREEN, BLUE;

    Top dut (
        .CLK(clk),
        .RESET(reset),
        .btn_u(switch_up),
        .btn_d(switch_down),
        .btn_l(switch_left),
        .btn_r(switch_right),
        .HSYNC(HS),
        .VSYNC(VS),
        .RED(RED),
        .GREEN(GREEN),
        .BLUE(BLUE)
    );

    always #1 clk = ~clk;

    initial begin
        // Initialize inputs
        clk <= 1'b1;
        reset <= 1'b1; // Start in reset
        
        switch_up <= 1'b0;
        switch_down <= 1'b0;
        switch_left <= 1'b0;
        switch_right <= 1'b0;

        // De-assert reset after 100ns
        #100 reset <= 1'b0;
        // Run for a longer period to ensure Game Manager cycles
        // Game manager clock is 10ms. Running for 100ms should show events.
        #1_000_000_000 // Wait 100ms (100,000,000 ns)

        // End simulation
        $finish;
    end
    
    
    reg [7:0] palette [0:191];
    wire active;
    
    assign active = dut.active;
    
    wire [9:0] x;
    wire [9:0] y;
    
    assign x = dut.x;
    assign y = dut.y;
    
    wire gaster_sprite_on;
    wire [7:0] gaster_data;
    assign gaster_sprite_on = dut.gaster_sprite_on;
    assign gaster_data = dut.gaster_data;

    // Blaster laser
    wire blaster_laser_sprite_on;
    wire [7:0] blaster_laser_data;
    assign blaster_laser_sprite_on = dut.blaster_laser_sprite_on;
    assign blaster_laser_data = dut.blaster_laser_data;

    // Level/Ground
    wire ground_sprite_on;
    assign ground_sprite_on = dut.ground_sprite_on;

    wire heart_sprite_on;
    assign heart_sprite_on = dut.heart_sprite_on;

    wire platform_sprite_on;
    assign platform_sprite_on = dut.platform_sprite_on;
        
    wire inside_heart;
    
    assign inside_heart = dut.heart_sprite.inside_heart;
    
    wire [7:0] o_data;
    assign o_data = dut.heart_sprite.o_data;
    
//    wire [10-1:0] attack_i;
//    wire [10-1:0] platform_i;
//    assign attack_i        = dut.attack_i;
//    assign platform_i      = dut.platform_i;
    
//    // Display Log
//    wire [9:0]  display_pos_x1;
//    wire [9:0]  display_pos_y1;
//    wire [9:0]  display_pos_x2;
//    wire [9:0]  display_pos_y2;
    
//    assign display_pos_x1 = dut.display_pos_x1;
//    assign display_pos_y1 = dut.display_pos_y1;
//    assign display_pos_x2 = dut.display_pos_x2;
//    assign display_pos_y2 = dut.display_pos_y2;
    
//    // Player Log
//    wire on_ground;
//    wire [13:0] jump_height_hires;
//    wire [9:0] player_pos_x;
//    wire [9:0] player_pos_y;
//    wire [9:0] player_w;
    
//    assign jump_height_hires = dut.player_position.jump_height_hires;
//    assign on_ground = dut.player_position.on_ground;
//    assign player_pos_x = dut.player_pos_x;
//    assign player_pos_y = dut.player_pos_y;
//    assign player_w = dut.player_w;
    

//     wire is_collider_ground_player;
//     wire [9:0] collider_ground_h_player;
//     wire [9:0] collider_ground_w_player;
     
//     assign collider_ground_h_player = dut.collider_ground_h_player;
//     assign collider_ground_w_player = dut.multi_object_collider_runtime_execute.collider_ground_w_player;
//     assign is_collider_ground_player = dut.is_collider_ground_player;
     
//     wire clk_centi_second;
////     wire [7:0] centi_second;
//     wire [7:0] object_destroy_time;
//     assign object_destroy_time = dut.multi_object_collider_runtime_execute.object_destroy_time;
//     assign clk_centi_second = dut.multi_object_collider_runtime_execute.clk_centi_second;
////     assign centi_second = dut.multi_object_collider_runtime_execute.object_collider_position_control[i].centi_second;

//    // Iterator Log
//    localparam integer OBJECT_AMOUNT = 30;   
//    wire [OBJECT_AMOUNT-1: 0] object_ready_state;
    
//    assign object_ready_state = dut.multi_object_collider_runtime_execute.object_ready_state;
    
//    // Iterator Log
//    localparam integer OBJECT_AMOUNT_T = 100;   
//    wire [OBJECT_AMOUNT_T-1: 0] object_ready_state_T;
    
//    assign object_ready_state_T = dut.muti_object_trigger_runtime_execute.object_ready_state;

    
   

endmodule