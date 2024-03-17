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
    input  wire        done,

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
    .rvalB_o(d_rvalB),
    .done(done)
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
    input  wire         done,

    output wire [63:0]  rvalA_o,
    output wire [63:0]  rvalB_o
);
reg [63:0] regs[14:0];

assign rvalA_o = srcA_i != `RNONE ? regs[srcA_i] : 64'b0;
assign rvalB_o = srcB_i != `RNONE ? regs[srcB_i] : 64'b0;

always @(posedge clk_i) begin
    if (dstE_i != `RNONE) regs[dstE_i] <= valE_i;
    if (dstM_i != `RNONE) regs[dstM_i] <= valM_i;
end    

integer fd;
always @(posedge done) begin
  fd = $fopen("./output.txt", "w");
  $fdisplay(fd, "Changes to registers:");
  if (0 != regs[0]) $fdisplay(fd, "%%rax:\t0x%016h\t0x%016h", 0, regs[0]);
  if (0 != regs[1]) $fdisplay(fd, "%%rcx:\t0x%016h\t0x%016h", 0, regs[1]);    
  if (0 != regs[2]) $fdisplay(fd, "%%rdx:\t0x%016h\t0x%016h", 0, regs[2]);
  if (0 != regs[3]) $fdisplay(fd, "%%rbx:\t0x%016h\t0x%016h", 0, regs[3]);
  if (0 != regs[4]) $fdisplay(fd, "%%rsp:\t0x%016h\t0x%016h", 0, regs[4]);
  if (0 != regs[5]) $fdisplay(fd, "%%rbp:\t0x%016h\t0x%016h", 0, regs[5]);
  if (0 != regs[6]) $fdisplay(fd, "%%rsi:\t0x%016h\t0x%016h", 0, regs[6]);
  if (0 != regs[7]) $fdisplay(fd, "%%rdi:\t0x%016h\t0x%016h", 0, regs[7]);
  if (0 != regs[8]) $fdisplay(fd, "%%r8:\t0x%016h\t0x%016h", 0, regs[8]);
  if (0 != regs[9]) $fdisplay(fd, "%%r9:\t0x%016h\t0x%016h", 0, regs[9]);
  if (0 != regs[10]) $fdisplay(fd, "%%r10:\t0x%016h\t0x%016h", 0, regs[10]);
  if (0 != regs[11]) $fdisplay(fd, "%%r11:\t0x%016h\t0x%016h", 0, regs[11]);
  if (0 != regs[12]) $fdisplay(fd, "%%r12:\t0x%016h\t0x%016h", 0, regs[12]);
  if (0 != regs[13]) $fdisplay(fd, "%%r13:\t0x%016h\t0x%016h", 0, regs[13]);
  if (0 != regs[14]) $fdisplay(fd, "%%r14:\t0x%016h\t0x%016h", 0, regs[14]);
  $fclose(fd);
end

integer i;
initial begin
    for (i = 0; i < 15; i = i + 1) regs[i] = 0;
end
endmodule