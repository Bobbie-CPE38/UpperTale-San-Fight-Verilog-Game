module NumberSprite (
    input  wire        i_pix_clk,
    input  wire        i_rst,
    input  wire [9:0]  pixel_x,
    input  wire [9:0]  pixel_y,
    input  wire [9:0]  i_x0,          // top-left corner of the digit
    input  wire [8:0]  i_y0,
    input  wire [3:0]  i_digit_code,  // 0-9, 10 = slash
    output reg         o_sprite_on,
    output reg  [7:0]  o_data
);

    // Sprite properties
    localparam SPR_W = 12;
    localparam SPR_H = 15;
    localparam MEM_SIZE = SPR_W * SPR_H;

    // Separate ROMs for each digit/symbol
    (*ROM_STYLE="block"*) reg [7:0] sprite0  [0:MEM_SIZE-1];
    (*ROM_STYLE="block"*) reg [7:0] sprite1  [0:MEM_SIZE-1];
    (*ROM_STYLE="block"*) reg [7:0] sprite2  [0:MEM_SIZE-1];
    (*ROM_STYLE="block"*) reg [7:0] sprite3  [0:MEM_SIZE-1];
    (*ROM_STYLE="block"*) reg [7:0] sprite4  [0:MEM_SIZE-1];
    (*ROM_STYLE="block"*) reg [7:0] sprite5  [0:MEM_SIZE-1];
    (*ROM_STYLE="block"*) reg [7:0] sprite6  [0:MEM_SIZE-1];
    (*ROM_STYLE="block"*) reg [7:0] sprite7  [0:MEM_SIZE-1];
    (*ROM_STYLE="block"*) reg [7:0] sprite8  [0:MEM_SIZE-1];
    (*ROM_STYLE="block"*) reg [7:0] sprite9  [0:MEM_SIZE-1];
    (*ROM_STYLE="block"*) reg [7:0] sprite10 [0:MEM_SIZE-1]; // slash

    // Convert screen coordinates to sprite coordinates
    wire [9:0] spr_x = pixel_x - i_x0;
    wire [8:0] spr_y = pixel_y - i_y0;

    wire in_bounds = (pixel_x >= i_x0 && pixel_x < i_x0 + SPR_W) &&
                     (pixel_y >= i_y0 && pixel_y < i_y0 + SPR_H);

    // Memory address = y * width + x
    wire [7:0] mem_addr = spr_y * SPR_W + spr_x;

    // Load ROMs at initialization
    initial begin
        $readmemh("0.mem",     sprite0);
        $readmemh("1.mem",     sprite1);
        $readmemh("2.mem",     sprite2);
        $readmemh("3.mem",     sprite3);
        $readmemh("4.mem",     sprite4);
        $readmemh("5.mem",     sprite5);
        $readmemh("6.mem",     sprite6);
        $readmemh("7.mem",     sprite7);
        $readmemh("8.mem",     sprite8);
        $readmemh("9.mem",     sprite9);
        $readmemh("slash.mem", sprite10);
    end

    // Select the correct sprite data
    reg [7:0] sprite_data;
    always @(*) begin
        case (i_digit_code)
            0: sprite_data = sprite0[mem_addr];
            1: sprite_data = sprite1[mem_addr];
            2: sprite_data = sprite2[mem_addr];
            3: sprite_data = sprite3[mem_addr];
            4: sprite_data = sprite4[mem_addr];
            5: sprite_data = sprite5[mem_addr];
            6: sprite_data = sprite6[mem_addr];
            7: sprite_data = sprite7[mem_addr];
            8: sprite_data = sprite8[mem_addr];
            9: sprite_data = sprite9[mem_addr];
            10: sprite_data = sprite10[mem_addr];
            default: sprite_data = sprite0[mem_addr];
        endcase
    end

    // Output logic
    always @(posedge i_pix_clk or posedge i_rst) begin
        if (i_rst) begin
            o_sprite_on <= 1'b0;
            o_data      <= 8'd0;
        end
        else if (in_bounds && sprite_data != 8'd0) begin
            o_sprite_on <= 1'b1;
            o_data      <= sprite_data;
        end
        else begin
            o_sprite_on <= 1'b0;
            o_data      <= 8'd0;
        end
    end

endmodule
