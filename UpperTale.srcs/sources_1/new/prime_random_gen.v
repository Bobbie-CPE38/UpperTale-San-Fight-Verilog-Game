module prime_random_gen(
    input  wire clk,
    input  wire rst,
    input  wire enable,
    output reg [2:0] rand_out
);

    reg [7:0] lfsr = 8'hA5;   // seed (prime-ish)
    reg is_once = 1;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            lfsr <= 8'hA5;
            rand_out <= 0;
            is_once <= 1;
        end
        else if (enable && is_once) begin
            // LFSR taps (8,6,5,4)
            lfsr <= {lfsr[6:0], lfsr[7] ^ lfsr[5] ^ lfsr[4] ^ lfsr[3]};
            is_once = 0;
            rand_out <= lfsr[2:0] % 6 + 1;   // output 0–5
        end else if (~enable) begin
            is_once = 1;
        end
    end
endmodule