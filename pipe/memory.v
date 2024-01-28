`include "define.v"

module memory(
    input  wire         clk_i,
    input  wire [2:0]   M_stat_i,
    input  wire [3:0]   M_icode_i,
    input  wire [63:0]  M_valE_i,
    input  wire [63:0]  M_valA_i,
    input  wire [3:0]   M_dstE_i,
    input  wire [3:0]   M_dstM_i,

    output wire [2:0]   m_stat_o,
    output wire [63:0]  m_valM_o
);

wire mem_read;
wire mem_write;
wire dmem_error;
wire [63:0] addr;

assign mem_read = (M_icode_i == `IMRMOVQ) | (M_icode_i == `IPOPQ) | (M_icode_i == `IRET);
assign mem_write = (M_icode_i == `IRMMOVQ) | (M_icode_i == `IPUSHQ) | (M_icode_i == `ICALL);
assign addr =  (M_icode_i == `IRMMOVQ || M_icode_i == `IMRMOVQ || 
            M_icode_i == `IPUSHQ || M_icode_i == `ICALL) ? M_valE_i : 
            (M_icode_i == `IPOPQ || M_icode_i == `IRET) ? M_valA_i : 64'b0;
assign m_stat_o = dmem_error ? `SADR : M_stat_i;
ram mem(
    .clk_i(clk_i),
    .addr_i(addr),
    .data_i(M_valA_i),
    .read_i(mem_read),
    .write_i(mem_write),
    .dmem_error_o(dmem_error),
    .data_o(m_valM_o)
);
endmodule

module ram (
    input  wire        clk_i,
    input  wire [63:0] addr_i,
    input  wire [63:0] data_i,
    input  wire        read_i,
    input  wire        write_i,

    output wire        dmem_error_o,
    output wire [63:0] data_o
);

parameter MAX_SIZE = 1024;
reg [7:0] mem[0:1023];

assign dmem_error_o = (addr_i >= MAX_SIZE) ? 1 : 0;

always @(posedge clk_i) begin
    if (write_i) { mem[addr_i + 7], mem[addr_i + 6], 
    mem[addr_i + 5], mem[addr_i + 4],
    mem[addr_i + 3], mem[addr_i + 2],
    mem[addr_i + 1], mem[addr_i] } <= data_i;
end

assign data_o = read_i ? { mem[addr_i + 7], mem[addr_i + 6], 
    mem[addr_i + 5], mem[addr_i + 4],
    mem[addr_i + 3], mem[addr_i + 2],
    mem[addr_i + 1], mem[addr_i] } : 64'b0;

initial begin
//                            | # sample linked list of 3 elements
//0x018:                      |     .align 8
//0x018:                      | Array:
//0x018: 0500000000000000     |     .quad 0x5
    mem[24] = 8'h05;
    mem[25] = 8'h00;
    mem[26] = 8'h00;
    mem[27] = 8'h00;
    mem[28] = 8'h00;
    mem[29] = 8'h00;
    mem[30] = 8'h00;
    mem[31] = 8'h00;
//0x020: 0400000000000000     |     .quad 0x4
    mem[32] = 8'h04;
    mem[33] = 8'h00;
    mem[34] = 8'h00;
    mem[35] = 8'h00;
    mem[36] = 8'h00;
    mem[37] = 8'h00;
    mem[38] = 8'h00;
    mem[39] = 8'h00;
//0x028: 0c00000000000000     |     .quad 0xC
    mem[40] = 8'h0c;
    mem[41] = 8'h00;
    mem[42] = 8'h00;
    mem[43] = 8'h00;
    mem[44] = 8'h00;
    mem[45] = 8'h00;
    mem[46] = 8'h00;
    mem[47] = 8'h00;
//0x030: 0200000000000000     |     .quad 0x2
    mem[48] = 8'h02;
    mem[49] = 8'h00;
    mem[50] = 8'h00;
    mem[51] = 8'h00;
    mem[52] = 8'h00;
    mem[53] = 8'h00;
    mem[54] = 8'h00;
    mem[55] = 8'h00;
//0x038: 0100000000000000     |     .quad 0x1
    mem[56] = 8'h01;
    mem[57] = 8'h00;
    mem[58] = 8'h00;
    mem[59] = 8'h00;
    mem[60] = 8'h00;
    mem[61] = 8'h00;
    mem[62] = 8'h00;
    mem[63] = 8'h00;
//0x040: 0b00000000000000     |     .quad 0xB
    mem[64] = 8'h0b;
    mem[65] = 8'h00;
    mem[66] = 8'h00;
    mem[67] = 8'h00;
    mem[68] = 8'h00;
    mem[69] = 8'h00;
    mem[70] = 8'h00;
    mem[71] = 8'h00;
//                            | 
end
endmodule