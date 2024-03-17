module cache_data(
  input wire          clk_i,
  input wire [  3:0]  data_req_index_i,
  input wire          data_req_we_i,
  input wire [255:0]  data_write_i,

  output wire [255:0] data_read_o
);

reg [255:0] data_mem[0:15];

assign data_read_o = data_mem[data_req_index_i];

always @(posedge clk_i) begin
  if (data_req_we_i)
    data_mem[data_req_index_i] <= data_write_i;
end

integer i;
initial begin
  for (i = 0; i < 16; i = i + 1) begin
    data_mem[i] = 0;
  end
end
endmodule