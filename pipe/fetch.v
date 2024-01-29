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
// write instructions in here
end
endmodule