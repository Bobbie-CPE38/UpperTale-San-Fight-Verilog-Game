`timescale 1ns / 1ps

module gaster_laser_collision(
    input clk,  
    input reset,
    input [9:0] heart_x,
    input [9:0] heart_y,
    input [9:0] laser_x,
    input [9:0] laser_y,
    input [9:0] laser_w,
    input [9:0] laser_h,
    input       laser_active,
    output reg  collided
    );
    
    localparam HEART_W = 24;
    localparam HEART_H = 24;
    
    wire overlap;
    
    assign overlap =
        laser_active &&
        !((heart_x + HEART_W - 1) < laser_x ||
          heart_x > (laser_x + laser_w - 1) ||
          (heart_y + HEART_H - 1) < laser_y ||
          heart_y > (laser_y + laser_h - 1));
    
    always @(posedge clk) begin
        if (reset)
            collided <= 0;
        else
            collided <= overlap;
    end
endmodule
