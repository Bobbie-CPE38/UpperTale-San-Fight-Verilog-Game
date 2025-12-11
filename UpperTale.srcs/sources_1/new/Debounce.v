module Debounce(
    input  wire i_clk,       // 100 MHz clock
    input  wire i_btn_in,    // raw pushbutton
    output reg  o_btn_out    // 1-clock pulse on press
);

    // Synchronizer
    reg r_sync_0 = 0;
    reg r_sync_1 = 0;

    // Debounce storage
    reg r_stable     = 0;
    reg r_prev       = 0;

    // Counter for stability (20 bits ? ~10 ms at 100 MHz)
    reg [19:0] r_counter = 0;

    // Double-flop synchronizer
    always @(posedge i_clk) begin
        r_sync_0 <= i_btn_in;
        r_sync_1 <= r_sync_0;
    end

    // Debounce logic
    always @(posedge i_clk) begin
        if (r_sync_1 != r_stable) begin
            r_counter <= r_counter + 1;

            // stable for ~10 ms
            if (r_counter == 20'hFFFFF) begin
                r_stable <= r_sync_1;
            end
        end else begin
            r_counter <= 0;
        end
    end

    // Output 1-clock pulse on rising edge
    always @(posedge i_clk) begin
        r_prev    <= r_stable;
        o_btn_out <= (r_stable && !r_prev);
    end

endmodule
