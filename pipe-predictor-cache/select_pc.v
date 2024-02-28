`include "define.v"

module select_pc(
    input  wire [ 3:0] M_icode_i,
    input  wire        M_Cnd_i,
    input  wire [63:0] M_valA_i,
    input  wire [63:0] M_valE_i,
    input  wire        M_branch_taken_i,
    input  wire [ 3:0] W_icode_i,
    input  wire [63:0] W_valM_i,
    input  wire [63:0] F_predPC_i,
    output wire [63:0] f_PC_o
);
wire mispredict = M_Cnd_i ^ M_branch_taken_i;

assign f_PC_o = (M_icode_i == `IJXX && mispredict) ? 
        (M_branch_taken_i ? M_valA_i : M_valE_i) : 
    (W_icode_i == `IRET) ? W_valM_i : F_predPC_i;
endmodule