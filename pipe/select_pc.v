`include "define.v"

module select_pc(
    input  wire [ 3:0] M_icode_i,
    input  wire        M_Cnd_i,
    input  wire [63:0] M_valA_i,
    input  wire [ 3:0] W_icode_i,
    input  wire [63:0] W_valM_i,
    input  wire [63:0] F_predPC_i,
    output wire [63:0] f_PC_o
);

assign f_PC_o = (M_icode_i == `IJXX && ~M_Cnd_i) ? M_valA_i :
            (W_icode_i == `IRET) ? W_valM_i : F_predPC_i;

endmodule