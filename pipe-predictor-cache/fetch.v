`include "define.v"

module fetch(
  input   wire [63:0] f_PC_i,
  output  wire [3:0]  f_icode_o,
  output  wire [3:0]  f_ifun_o,
  output  wire [3:0]  f_rA_o,
  output  wire [3:0]  f_rB_o,
  output  wire [63:0] f_valC_o,
  output  wire [63:0] f_valP_o,
  output  wire [2:0]  f_stat_o
);
wire [79:0] instr;
wire        instr_valid;
wire        imem_error;
wire        need_regids;
wire        need_valC;

instr_memory mem(
  .raddr_i(f_PC_i),
  .rdata_o(instr),
  .imem_error_o(imem_error)
);

assign f_icode_o    = instr[7:4];
assign f_ifun_o     = instr[3:0];
assign instr_valid  = (f_icode_o < 4'hC);
assign need_regids  = (f_icode_o == `IRRMOVQ) || (f_icode_o == `IIRMOVQ) || 
    (f_icode_o == `IMRMOVQ) || (f_icode_o == `IOPQ) || 
    (f_icode_o == `IRMMOVQ) || (f_icode_o == `IPUSHQ) || (f_icode_o == `IPOPQ);
assign need_valC = (f_icode_o == `IIRMOVQ) || (f_icode_o == `IRMMOVQ) || 
    (f_icode_o == `IMRMOVQ) || (f_icode_o == `IJXX) || (f_icode_o == `ICALL);
assign f_rA_o = need_regids ? instr[15:12] : 4'hF;
assign f_rB_o = need_regids ? instr[11: 8] : 4'hF;    

assign f_valC_o = need_regids ? instr[79:16] : instr[71:8];
assign f_valP_o = f_PC_i + 1 + 8 * need_valC + need_regids;
assign f_stat_o = imem_error ? `SADR : 
    ~instr_valid ? `SINS : 
    f_icode_o == `IHALT ? `SHLT : `SAOK;
endmodule

module instr_memory (
  input   wire [63:0] raddr_i,
  output  wire [79:0] rdata_o,
  output  wire        imem_error_o
);

localparam MEM_MAX_SIZE = 2048;
reg [7:0] mem[0:MEM_MAX_SIZE-1];

assign imem_error_o = (raddr_i >= MEM_MAX_SIZE);
assign rdata_o = {
  mem[raddr_i + 9], mem[raddr_i + 8], mem[raddr_i + 7],
  mem[raddr_i + 6], mem[raddr_i + 5], mem[raddr_i + 4],
  mem[raddr_i + 3], mem[raddr_i + 2], mem[raddr_i + 1],
  mem[raddr_i]
};

initial begin
  $readmemh("../input.txt", mem);
end
endmodule