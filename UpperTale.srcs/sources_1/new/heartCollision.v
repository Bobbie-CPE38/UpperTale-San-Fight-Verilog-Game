`timescale 1ns / 1ps

module heart_collision(
    input  wire        clk,
    input  wire        reset,

    // Heart center position (top-left)
    input  wire [9:0]  heart_x,
    input  wire [9:0]  heart_y,

    // Object bounding box
    input  wire [9:0]  obj_x,
    input  wire [9:0]  obj_y,
    input  wire [9:0]  obj_w,
    input  wire [9:0]  obj_h,
    input  wire        obj_active,

    // Output
    output reg         collided
);

    // Heart bounding box (Undertale heart = 24x24)
    localparam HEART_W = 24;
    localparam HEART_H = 24;

    // AABB collision check
    wire overlap =
        obj_active &&
        (heart_x + HEART_W > obj_x) &&
        (heart_x < obj_x + obj_w) &&
        (heart_y + HEART_H > obj_y) &&
        (heart_y < obj_y + obj_h);

    always @(posedge clk or posedge reset) begin
        if (reset)
            collided <= 1'b0;
        else
            collided <= overlap;
    end

endmodule
