`include "define.v"

module pipeline_control (
    input wire [3:0] D_icode_i,
    input wire [3:0] d_srcA_i,
    input wire [3:0] d_srcB_i,
    input wire [3:0] E_icode_i,
    input wire [3:0] E_dstM_i,
    input wire       E_branch_taken_i,
    input wire       e_Cnd_i,
    input wire [3:0] M_icode_i,
    input wire [2:0] m_stat_i,
    input wire [2:0] W_stat_i,

    output wire      F_stall_o,
    output wire      D_stall_o,
    output wire      D_bubble_o,
    output wire      E_bubble_o,
    output wire      M_bubble_o,
    output wire      W_stall_o
);

wire h_load_use;
wire h_ret;
wire h_mispredict;

assign h_load_use = (E_icode_i == `IMRMOVQ || E_icode_i == `IPOPQ) &&
    (E_dstM_i == d_srcB_i || (E_dstM_i == d_srcA_i && 
    !(D_icode_i == `IRMMOVQ || D_icode_i == `IPUSHQ)));

assign h_ret = D_icode_i == `IRET || E_icode_i == `IRET || M_icode_i == `IRET;

assign h_mispredict = (E_icode_i == `IJXX) & (e_Cnd_i ^ E_branch_taken_i);

assign F_stall_o = h_load_use | h_ret;
    
assign D_bubble_o = h_mispredict | (~h_load_use & h_ret);

assign D_stall_o = h_load_use;

assign E_bubble_o = h_load_use | h_mispredict;

assign M_bubble_o = (m_stat_i == `SADR || m_stat_i == `SINS || m_stat_i == `SHLT) ||
    (W_stat_i == `SADR || W_stat_i == `SINS || W_stat_i == `SHLT);

assign W_stall_o = (W_stat_i == `SADR || W_stat_i == `SINS || W_stat_i == `SHLT);
endmodule