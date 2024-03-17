module ram (
  input  wire         clk_i,
  input  wire         mem_valid_i,
  input  wire [63:0]  mem_addr_i,
  input  wire [255:0] mem_wdata_i,
  input  wire         mem_rw_i,
  input  wire         done,

  output wire         dmem_error_o,
  output reg         mem_ready_o,
  output wire [255:0] mem_rdata_o
);

parameter MAX_SIZE = 2048;
reg [7:0] mem[0:MAX_SIZE-1];
reg [7:0] mem_copy[0:MAX_SIZE-1];
wire [10:0] addr;
assign addr = mem_addr_i[10:0];
assign dmem_error_o = mem_valid_i & (mem_addr_i + 8 >= MAX_SIZE) ? 1 : 0;

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