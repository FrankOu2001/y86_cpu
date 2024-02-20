`include "define.v"

module execute (
  input  wire        clk_i,
  input  wire        rst_n_i,
  input  wire [ 3:0] E_icode_i,
  input  wire [ 3:0] E_ifun_i,
  input  wire [63:0] E_valC_i,
  input  wire [63:0] E_valA_i,
  input  wire [63:0] E_valB_i,
  input  wire [ 3:0] E_dstE_i,
  input  wire [ 3:0] E_dstM_i,
  input  wire [ 3:0] E_srcA_i,
  input  wire [ 3:0] M_dstM_i,
  input  wire [63:0] m_valM_i,
  input  wire [ 2:0] m_stat_i,
  input  wire [ 2:0] W_stat_i,

  output wire        e_Cnd_o,
  output wire [63:0] e_valA_o,
  output wire [63:0] e_valE_o,
  output wire [ 3:0] e_dstE_o,
  output wire [ 3:0] e_dstM_o
);

wire [63:0] aluA, aluB;
wire [3:0]  alu_fun;
wire set_cc;
wire zf, sf, of;

reg [2:0] new_cc, cc;

assign aluA = (E_icode_i == `IRRMOVQ || E_icode_i == `IOPQ) ? E_valA_i :
  (E_icode_i == `IIRMOVQ || E_icode_i == `IRMMOVQ ||
      E_icode_i == `IMRMOVQ || E_icode_i == `IJXX)          ? E_valC_i :
  (E_icode_i == `ICALL   || E_icode_i == `IPUSHQ)           ? -8   :
  (E_icode_i == `IRET    || E_icode_i == `IPOPQ)            ? 8    : 64'd0;

assign aluB = (E_icode_i == `IRMMOVQ || E_icode_i == `IMRMOVQ ||
  E_icode_i == `IOPQ   || E_icode_i == `ICALL ||
  E_icode_i == `IPUSHQ || E_icode_i == `IRET  ||
  E_icode_i == `IPOPQ) ? E_valB_i : 64'd0;
  // (E_icode_i == `IRRMOVQ || E_icode_i == `IIRMOVQ) ? 0 : 0;

assign alu_fun = (E_icode_i == `IOPQ) ? E_ifun_i : `ALUADD;

assign e_valA_o = (E_icode_i == `IRMMOVQ || E_icode_i == `IPUSHQ) &&
  E_srcA_i == M_dstM_i ? m_valM_i : E_valA_i;

assign e_valE_o = (alu_fun == `ALUSUB) ? aluB - aluA :
  (alu_fun == `ALUAND) ? aluB & aluA :
  (alu_fun == `ALUXOR) ? aluB ^ aluA : aluB + aluA;

assign {zf, sf, of} = cc;

assign set_cc = E_icode_i == `IOPQ &&
  ~(m_stat_i == `SADR || m_stat_i == `SINS || m_stat_i == `SHLT) &&
  ~(W_stat_i == `SADR || W_stat_i == `SINS || W_stat_i == `SHLT);

always @(*) begin
  new_cc[2] = (e_valE_o == 0) ? 1 : 0;
  new_cc[1] = e_valE_o[63];
  new_cc[0] = (alu_fun == `ALUADD) ?
    ~(aluA[63] ^ aluB[63]) & (aluB[63] ^ e_valE_o[63]) :
    (alu_fun == `ALUSUB) ?
    (aluA[63] ^ aluB[63]) & (aluB[63] ^ e_valE_o[63]) : 0;
end

always @(posedge clk_i) begin
  cc <= ~rst_n_i ? 3'b100 :
        set_cc   ? new_cc : cc;
end

assign e_Cnd_o = (E_ifun_i == `C_YES) ||                  //
              (E_ifun_i == `C_LE  && ((sf ^ of) | zf)) || // <=
              (E_ifun_i == `C_L   && (sf ^ of)) ||        // <
              (E_ifun_i == `C_E   && zf) ||               // ==
              (E_ifun_i == `C_NE  && ~zf) ||              // !=
              (E_ifun_i == `C_GE  && ~(sf ^ of)) ||       // >=
              (E_ifun_i == `C_G   && (~(sf ^ of) & ~zf)); // >

assign e_dstE_o = ((E_icode_i == `IRRMOVQ) && ~e_Cnd_o) ? `RNONE : E_dstE_i;
endmodule
