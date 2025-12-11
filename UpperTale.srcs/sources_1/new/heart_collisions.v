`timescale 1ns / 1ps

module heart_collisions(
    input  wire        clk,
    input  wire        reset,
    input  wire [9:0]  heart_x,
    input  wire [9:0]  heart_y,
    input  wire [9:0]  obj_x,
    input  wire [9:0]  obj_y,
    input  wire [9:0]  obj_w,
    input  wire [9:0]  obj_h,
    input  wire        obj_active,
    output reg         collided
    );
    localparam HEART_W = 24;
    localparam HEART_H = 24;
    
    wire overlap;
    
    assign overlap =
        obj_active &&
        !((heart_x + HEART_W - 1) < obj_x ||
          heart_x > (obj_x + obj_w - 1) ||
          (heart_y + HEART_H - 1) < obj_y ||
          heart_y > (obj_y + obj_h - 1));
    
    always @(posedge clk) begin
        if (reset)
            collided <= 0;
        else
            collided <= overlap;
    end
endmodule
