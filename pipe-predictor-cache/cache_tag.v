module cache_tag (
  input wire        clk_i,
  input wire        rst_n_i,
  input wire [3:0]  tag_index_i,
  input wire        tag_we_i,
  input wire [56:0] tag_write_i,
  
  output wire [56:0] tag_read_o
);
localparam TAGMSB = 63, TAGLSB = 9;

// valid, dirty, [54:0]tag
reg [56:0] tag_mem[0:15];

assign tag_read_o = tag_mem[tag_index_i];

integer i;
always @(posedge clk_i) begin
  if (~rst_n_i) begin
    for (i = 0; i < 16; i = i + 1) tag_mem[i] = 0;
  end
  else if (tag_we_i)
    tag_mem[tag_index_i] <= tag_write_i;
end

endmodule