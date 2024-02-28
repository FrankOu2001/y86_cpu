module ram (
  input  wire         clk_i,
  input  wire         mem_valid_i,
  input  wire [63:0]  mem_addr_i,
  input  wire [255:0] mem_wdata_i,
  input  wire         mem_rw_i,

  output wire         dmem_error_o,
  output reg         mem_ready_o,
  output wire [255:0] mem_rdata_o
);

parameter MAX_SIZE = 2048;
reg [7:0] mem[0:MAX_SIZE-1];
wire [9:0] addr;
assign addr = mem_addr_i;
assign dmem_error_o = mem_valid_i & (mem_addr_i + 8 >= MAX_SIZE) ? 1 : 0;
// assign mem_ready_o = mem_valid_i & ~dmem_error_o;
always @(posedge clk_i) begin
  mem_ready_o = mem_valid_i & ~dmem_error_o;
  if (mem_valid_i & ~dmem_error_o) begin
    if (mem_rw_i) {
      mem[addr + 31], mem[addr + 30],
      mem[addr + 29], mem[addr + 28],
      mem[addr + 27], mem[addr + 26],
      mem[addr + 25], mem[addr + 24],
      mem[addr + 23], mem[addr + 22], 
      mem[addr + 21], mem[addr + 20],
      mem[addr + 19], mem[addr + 18],
      mem[addr + 17], mem[addr + 16],
      mem[addr + 15], mem[addr + 14],
      mem[addr + 13], mem[addr + 12],
      mem[addr + 11], mem[addr + 10],
      mem[addr + 9],  mem[addr + 8],
      mem[addr + 7],  mem[addr + 6], 
      mem[addr + 5],  mem[addr + 4],
      mem[addr + 3],  mem[addr + 2],
      mem[addr + 1],  mem[addr] 
    } <= mem_wdata_i;
  end
end

assign mem_rdata_o = (mem_valid_i & ~dmem_error_o & ~mem_rw_i) ? {
  mem[addr + 31], mem[addr + 30],
  mem[addr + 29], mem[addr + 28],
  mem[addr + 27], mem[addr + 26],
  mem[addr + 25], mem[addr + 24],
  mem[addr + 23], mem[addr + 22], 
  mem[addr + 21], mem[addr + 20],
  mem[addr + 19], mem[addr + 18],
  mem[addr + 17], mem[addr + 16],
  mem[addr + 15], mem[addr + 14],
  mem[addr + 13], mem[addr + 12],
  mem[addr + 11], mem[addr + 10],
  mem[addr + 9],  mem[addr + 8],
  mem[addr + 7],  mem[addr + 6], 
  mem[addr + 5],  mem[addr + 4],
  mem[addr + 3],  mem[addr + 2],
  mem[addr + 1],  mem[addr] 
} : 0;

initial begin
end

endmodule