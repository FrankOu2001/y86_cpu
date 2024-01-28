`include "define.v"

module fetch(
    input   wire [63:0] PC_i,
    output  wire [3:0]  icode_o,
    output  wire [3:0]  ifun_o,
    output  wire [3:0]  rA_o,
    output  wire [3:0]  rB_o,
    output  wire [63:0] valC_o,
    output  wire [63:0] valP_o,
    output  wire [63:0] predPC_o,
    output  wire [2:0]  stat_o
);
wire [79:0] instr;
wire        instr_valid;
wire        imem_error;
wire        need_regids;
wire        need_valC;

instr_memory mem(
    .raddr_i(PC_i),
    .rdata_o(instr),
    .imem_error_o(imem_error)
);

assign icode_o     = instr[7:4];
assign ifun_o      = instr[3:0];
assign instr_valid = (icode_o < 4'hC);
assign halt        = icode_o == `IHALT;
assign need_regids = (icode_o == `IRRMOVQ) || (icode_o == `IIRMOVQ) || 
    (icode_o == `IMRMOVQ) || (icode_o == `IOPQ) || 
    (icode_o == `IRMMOVQ) || (icode_o == `IPUSHQ) || (icode_o == `IPOPQ);
assign need_valC = (icode_o == `IIRMOVQ) || (icode_o == `IRMMOVQ) || 
    (icode_o == `IMRMOVQ) || (icode_o == `IJXX) || (icode_o == `ICALL);
assign rA_o = need_regids ? instr[15:12] : 4'hF;
assign rB_o = need_regids ? instr[11: 8] : 4'hF;    

assign valC_o = need_regids ? instr[79:16] : instr[71:8];
assign valP_o = PC_i + 1 + 8 * need_valC + need_regids;
assign predPC_o = (icode_o == `IJXX || icode_o == `ICALL) ? valC_o : valP_o;

assign stat_o = imem_error ? `SADR : 
    ~instr_valid ? `SINS : 
    icode_o == `IHALT ? `SHLT : `SAOK;
endmodule

module instr_memory (
    input   wire [63:0] raddr_i,
    output  wire [79:0] rdata_o,
    output  wire        imem_error_o
);

parameter MEM_MAX_SIZE = 1024;
reg [7:0] mem[0:1023];

assign imem_error_o = (raddr_i >= MEM_MAX_SIZE);
assign rdata_o = {
    mem[raddr_i + 9], mem[raddr_i + 8], mem[raddr_i + 7],
    mem[raddr_i + 6], mem[raddr_i + 5], mem[raddr_i + 4],
    mem[raddr_i + 3], mem[raddr_i + 2], mem[raddr_i + 1],
    mem[raddr_i]
};

initial begin
//0x000:                      | .pos 0
//                            | 
//0x000: 30f20500000000000000 | irmovq $5, %rdx
    mem[0] = 8'h30;
    mem[1] = 8'hf2;
    mem[2] = 8'h05;
    mem[3] = 8'h00;
    mem[4] = 8'h00;
    mem[5] = 8'h00;
    mem[6] = 8'h00;
    mem[7] = 8'h00;
    mem[8] = 8'h00;
    mem[9] = 8'h00;
//0x00a: 30f40001000000000000 | irmovq $0x100, %rsp
    mem[10] = 8'h30;
    mem[11] = 8'hf4;
    mem[12] = 8'h00;
    mem[13] = 8'h01;
    mem[14] = 8'h00;
    mem[15] = 8'h00;
    mem[16] = 8'h00;
    mem[17] = 8'h00;
    mem[18] = 8'h00;
    mem[19] = 8'h00;
//0x014: 40240000000000000000 | rmmovq %rdx, 0(%rsp)
    mem[20] = 8'h40;
    mem[21] = 8'h24;
    mem[22] = 8'h00;
    mem[23] = 8'h00;
    mem[24] = 8'h00;
    mem[25] = 8'h00;
    mem[26] = 8'h00;
    mem[27] = 8'h00;
    mem[28] = 8'h00;
    mem[29] = 8'h00;
//0x01e: b04f                 | popq %rsp
    mem[30] = 8'hb0;
    mem[31] = 8'h4f;
//0x020: 2040                 | rrmovq %rsp, %rax
    mem[32] = 8'h20;
    mem[33] = 8'h40;
//0x022: 00                   | halt
    mem[34] = 8'h00;

end
endmodule