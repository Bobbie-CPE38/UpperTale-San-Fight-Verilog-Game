`timescale 1ns / 1ps

module level_display(
    input  wire [9:0] pixel_x,   // VGA pixel X (0 - 639)
    input  wire [9:0] pixel_y,   // VGA pixel Y (0 - 479)
    output reg        o_sprite_on
    );

    // Border parameters
    localparam LEFT   = 130;
    localparam RIGHT  = 506;
    localparam TOP    = 251;
    localparam BOTTOM = 391;
    localparam THICK  = 6;

    always @(*) begin

        // Inside bounding box?
        if (pixel_x >= LEFT && pixel_x <= RIGHT &&
            pixel_y >= TOP  && pixel_y <= BOTTOM) begin

            // Check thickness area (outer 6px region)
            if ( (pixel_x < LEFT  + THICK)  ||  // left border
                 (pixel_x > RIGHT - THICK) ||  // right border
                 (pixel_y < TOP   + THICK) ||  // top border
                 (pixel_y > BOTTOM - THICK) )  // bottom border
                o_sprite_on = 1;
            else
                o_sprite_on = 0;

        end else begin
            o_sprite_on = 0; // outside rectangle
        end
    end

endmodule
