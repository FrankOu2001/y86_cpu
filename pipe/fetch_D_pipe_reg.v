`include "define.v"

module fetch_D_pipe_reg(
    input   wire          clk_i,
    input   wire          D_bubble_i,
    input   wire          D_stall_i,
    
    input   wire [2:0]    f_stat_i,
    input   wire [3:0]    f_icode_i,
    input   wire [3:0]    f_ifun_i,
    input   wire [3:0]    f_rA_i,
    input   wire [3:0]    f_rB_i,
    input   wire [63:0]   f_valC_i,
    input   wire [63:0]   f_valP_i,

    
    output  reg  [2:0]    D_stat_o,
    output  reg  [3:0]    D_icode_o,
    output  reg  [3:0]    D_ifun_o,
    output  reg  [3:0]    D_rA_o,
    output  reg  [3:0]    D_rB_o,
    output  reg  [63:0]   D_valC_o,
    output  reg  [63:0]   D_valP_o
);
always @(posedge clk_i) begin
    if (D_bubble_i) begin
        D_stat_o  <= 3'b0;
        D_icode_o <= `INOP; 
        D_ifun_o  <= `FNONE;
        D_rA_o    <= 4'b0;
        D_rB_o    <= 4'b0;
        D_valC_o  <= 64'b0;
        D_valP_o  <= 64'b0;
    end
    else if (~D_stall_i) begin
        D_stat_o  <= f_stat_i;
        D_icode_o <= f_icode_i;
        D_ifun_o  <= f_ifun_i;
        D_rA_o    <= f_rA_i;
        D_rB_o    <= f_rB_i;
        D_valC_o  <= f_valC_i;
        D_valP_o  <= f_valP_i;
    end
end

endmodule