module BestScoreMemory (
    input  wire       i_clk,        // system clock
    input  wire       i_rst,        // reset
    input  wire [6:0] i_score,      // current score 0..99
    output reg  [6:0] o_best_score  // best score
);
    always @(posedge i_clk or posedge i_rst) begin
        if (i_rst) 
            o_best_score <= 0;                // reset best score
        else if (i_score > o_best_score)
            o_best_score <= i_score;         // update if new high score
    end

endmodule
