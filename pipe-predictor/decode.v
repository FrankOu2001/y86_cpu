`include "define.v"

module decode(
    input  wire        clk_i,
    input  wire [ 3:0] D_icode_i,
    input  wire [ 3:0] D_ifun_i,
    input  wire [ 3:0] D_rA_i,
    input  wire [ 3:0] D_rB_i,
    input  wire [63:0] D_valC_i,
    input  wire [63:0] D_valP_i,
    
    input  wire [ 3:0] e_dstE_i,
    input  wire [63:0] e_valE_i,
    input  wire [ 3:0] M_dstE_i,
    input  wire [63:0] M_valE_i,
    input  wire [ 3:0] M_dstM_i,
    input  wire [63:0] m_valM_i,
    input  wire [ 3:0] W_dstM_i,
    input  wire [63:0] W_valM_i,
    input  wire [ 3:0] W_dstE_i,
    input  wire [63:0] W_valE_i,

    output wire [63:0] d_valA_o,
    output wire [63:0] d_valB_o,
    output wire [ 3:0] d_dstE_o,
    output wire [ 3:0] d_dstM_o,
    output wire [ 3:0] d_srcA_o,
    output wire [ 3:0] d_srcB_o
);
wire [63:0] d_rvalA;
wire [63:0] d_rvalB;

register_file files(
    .clk_i(clk_i),
    .srcA_i(d_srcA_o),
    .srcB_i(d_srcB_o),
    .dstE_i(W_dstE_i),
    .valE_i(W_valE_i),
    .dstM_i(W_dstM_i),
    .valM_i(W_valM_i),
    .rvalA_o(d_rvalA),
    .rvalB_o(d_rvalB)
);

assign d_srcA_o = (D_icode_i == `IRRMOVQ || D_icode_i == `IRMMOVQ || 
    D_icode_i == `IOPQ || D_icode_i == `IPUSHQ) ? D_rA_i :
    (D_icode_i == `IRET || D_icode_i == `IPOPQ) ? `RRSP : `RNONE;
assign d_srcB_o = (D_icode_i == `IRMMOVQ || 
        D_icode_i == `IOPQ || D_icode_i == `IMRMOVQ) ? D_rB_i :
    (D_icode_i == `ICALL || D_icode_i == `IRET || 
        D_icode_i == `IPUSHQ || D_icode_i == `IPOPQ) ? `RRSP : `RNONE;

assign d_dstE_o = (D_icode_i == `IOPQ ||
        D_icode_i == `IRRMOVQ || D_icode_i == `IIRMOVQ) ? D_rB_i :
    (D_icode_i == `IPUSHQ || D_icode_i == `IPOPQ ||
        D_icode_i == `ICALL || D_icode_i == `IRET) ? `RRSP : `RNONE;
assign d_dstM_o = (D_icode_i == `IMRMOVQ || D_icode_i == `IPOPQ) ? D_rA_i : `RNONE;

assign d_valA_o = (D_icode_i == `ICALL || D_icode_i == `IJXX) ? D_valP_i :
                d_srcA_o == e_dstE_i ? e_valE_i :
                d_srcA_o == M_dstM_i ? m_valM_i :
                d_srcA_o == M_dstE_i ? M_valE_i :
                d_srcA_o == W_dstM_i ? W_valM_i :
                d_srcA_o == W_dstE_i ? W_valE_i : d_rvalA;
assign d_valB_o = d_srcB_o == e_dstE_i ? e_valE_i :
                d_srcB_o == M_dstM_i ? m_valM_i :
                d_srcB_o == M_dstE_i ? M_valE_i :
                d_srcB_o == W_dstM_i ? W_valM_i :
                d_srcB_o == W_dstE_i ? W_valE_i : d_rvalB;

endmodule

module register_file (
    input  wire         clk_i,
    input  wire [3:0]   srcA_i,
    input  wire [3:0]   srcB_i,
    input  wire [3:0]   dstE_i,
    input  wire [3:0]   dstM_i,
    input  wire [63:0]  valE_i,
    input  wire [63:0]  valM_i,

    output wire [63:0]  rvalA_o,
    output wire [63:0]  rvalB_o
);
reg [63:0] registers[14:0];

assign rvalA_o = srcA_i != `RNONE ? registers[srcA_i] : 64'b0;
assign rvalB_o = srcB_i != `RNONE ? registers[srcB_i] : 64'b0;

always @(posedge clk_i) begin
    if (dstE_i != `RNONE) registers[dstE_i] <= valE_i;
    else if (dstM_i != `RNONE) registers[dstM_i] <= valM_i;
end    

integer i;
initial begin
    for (i = 0; i < 15; i = i + 1) registers[i] = 0;
end
endmodule