`include "define.v"
`include "ram.v"
`include "cache.v"

module memory(
  input  wire        clk_i,
  input  wire        rst_n_i,
  input  wire [ 2:0] M_stat_i,
  input  wire [ 3:0] M_icode_i,
  input  wire [63:0] M_valE_i,
  input  wire [63:0] M_valA_i,
  input  wire [ 3:0] M_dstE_i,
  input  wire [ 3:0] M_dstM_i,
  input  wire        done,
  
  output wire [ 2:0] m_stat_o,
  output wire [63:0] m_valM_o,
  output wire        h_cache_access_o
);

wire         cpu_req_valid;
wire         cpu_req_rw;
wire [63:0]  cpu_req_addr;
wire         cpu_res_ready;
wire [63:0]  cpu_res_data;
wire         dmem_error;
wire         mem_rw;
wire         mem_valid;
wire         mem_ready;
wire [63:0]  mem_addr;
wire [255:0] mem_rdata;
wire [255:0] mem_wdata;

assign m_valM_o = cpu_res_data;
assign cpu_req_valid = (M_icode_i == `IMRMOVQ) | (M_icode_i == `IPOPQ) | 
  (M_icode_i == `IRET) | (M_icode_i == `IRMMOVQ) | 
  (M_icode_i == `IPUSHQ) | (M_icode_i == `ICALL);
assign cpu_req_rw = (M_icode_i == `IRMMOVQ) | (M_icode_i == `IPUSHQ) | (M_icode_i == `ICALL);
assign cpu_req_addr =  (M_icode_i == `IRMMOVQ || M_icode_i == `IMRMOVQ || 
            M_icode_i == `IPUSHQ || M_icode_i == `ICALL) ? M_valE_i : 
            (M_icode_i == `IPOPQ || M_icode_i == `IRET) ? M_valA_i : 64'b0;
assign m_stat_o = dmem_error ? `SADR : M_stat_i;

assign h_cache_access_o = cpu_req_valid & ~cpu_res_ready;

ram RAM(
  .clk_i(clk_i),
  .mem_valid_i(mem_valid),
  .mem_addr_i(mem_addr),
  .mem_wdata_i(mem_wdata),
  .mem_rw_i(mem_rw),
  .dmem_error_o(dmem_error),
  .mem_rdata_o(mem_rdata),
  .mem_ready_o(mem_ready),
  .done(done)
);

cache_fsm CACHE(
  .clk_i(clk_i),
  .rst_n_i(rst_n_i),
  .cpu_req_addr_i(cpu_req_addr),
  .cpu_req_data_i(M_valA_i),
  .cpu_req_rw_i(cpu_req_rw),
  .cpu_req_valid_i(cpu_req_valid),
  /* mem_data */
  .mem_data_data_i(mem_rdata),
  .mem_data_ready_i(mem_ready),

  /* mem_req */
  .mem_req_rw_o(mem_rw),
  .mem_req_valid_o(mem_valid),
  .mem_req_data_o(mem_wdata),
  .mem_req_addr_o(mem_addr),
  /* cpu_res */
  .cpu_res_data_o(cpu_res_data),
  .cpu_res_ready_o(cpu_res_ready)
);
endmodule
