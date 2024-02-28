module F_pipe_reg (
    input  wire        clk_i,
    input  wire        F_stall_i,
    input  wire        F_bubble_i,
    input  wire [63:0] f_predPC_i,
    output reg  [63:0] F_predPC_o
);
always @(posedge clk_i) begin
    if (F_bubble_i) F_predPC_o <= 64'b0;
    else if (~F_stall_i) F_predPC_o <= f_predPC_i;
end 
endmodule