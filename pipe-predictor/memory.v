`include "define.v"

module memory(
  input  wire        clk_i,
  input  wire [ 2:0] M_stat_i,
  input  wire [ 3:0] M_icode_i,
  input  wire [63:0] M_valE_i,
  input  wire [63:0] M_valA_i,
  input  wire [ 3:0] M_dstE_i,
  input  wire [ 3:0] M_dstM_i,
  input  wire        done,

  output wire [ 2:0] m_stat_o,
  output wire [63:0] m_valM_o
);

wire        mem_read;
wire        mem_write;
wire        dmem_error;
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
  .data_o(m_valM_o),
  .done(done)
);
endmodule

module ram (
  input  wire        clk_i,
  input  wire [63:0] addr_i,
  input  wire [63:0] data_i,
  input  wire        read_i,
  input  wire        write_i,
  input  wire        done,

  output wire        dmem_error_o,
  output wire [63:0] data_o
);

parameter MAX_SIZE = 2048;
reg [7:0] mem[0:MAX_SIZE-1];
reg [7:0] mem_copy[0:MAX_SIZE-1];

assign dmem_error_o = (addr_i >= MAX_SIZE) ? 1 : 0;

always @(posedge clk_i) begin
  if (write_i & ~dmem_error_o) { 
    mem[addr_i + 7], mem[addr_i + 6], 
    mem[addr_i + 5], mem[addr_i + 4],
    mem[addr_i + 3], mem[addr_i + 2],
    mem[addr_i + 1], mem[addr_i] 
  } <= data_i;
end

assign data_o = (read_i & ~dmem_error_o) ? { 
  mem[addr_i + 7], mem[addr_i + 6], 
  mem[addr_i + 5], mem[addr_i + 4],
  mem[addr_i + 3], mem[addr_i + 2],
  mem[addr_i + 1], mem[addr_i] } : 64'b0;

integer fd;
reg [15:0] i;
reg [63:0] d1, d2;
always @(posedge done) #1 begin
  fd = $fopen("./output.txt", "a");
  $fdisplay(fd, "\nChanges to memory:");
  for (i = 0; i < MAX_SIZE; i = i + 8) begin
    d1 = {
      mem_copy[i + 7], mem_copy[i + 6], 
      mem_copy[i + 5], mem_copy[i + 4],
      mem_copy[i + 3], mem_copy[i + 2],
      mem_copy[i + 1], mem_copy[i]
    };
    d2 = { 
      mem[i + 7], mem[i + 6], 
      mem[i + 5], mem[i + 4],
      mem[i + 3], mem[i + 2],
      mem[i + 1], mem[i] 
    };
    if (d1 != d2) begin
      $fdisplay(fd, "0x%04h:\t0x%016h\t0x%016h\t", i, d1, d2);
    end
  end
  $fclose(fd);
end

initial begin
  $readmemh("../input.txt", mem);
  $readmemh("../input.txt", mem_copy);
end
endmodule