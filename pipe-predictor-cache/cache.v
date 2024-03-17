`include "cache_data.v"
`include "cache_tag.v"

module cache_fsm(
  input wire          clk_i,
  input wire          rst_n_i,
  /* cpu_req */
  input wire [63:0]   cpu_req_addr_i,
  input wire [63:0]   cpu_req_data_i,
  input wire          cpu_req_rw_i,
  input wire          cpu_req_valid_i,
  /* mem_data */
  input wire [255:0]  mem_data_data_i,
  input wire          mem_data_ready_i,

  /* mem_req */
  output wire         mem_req_rw_o,
  output wire         mem_req_valid_o,
  output wire [255:0] mem_req_data_o,
  output wire [63:0]  mem_req_addr_o,
  /* cpu_res */
  output wire [63:0]  cpu_res_data_o,
  output wire         cpu_res_ready_o
);
localparam TAGMSB = 63, TAGLSB = 9;
localparam idle = 0, compare_tag = 1, allocate = 2, write_back = 3;

// ! 统计Cache访问花费周期
reg [63:0] c_cycle = 0;
reg [63:0] c_access = 0;
reg [63:0] c_miss = 0;
reg [63:0] c_mem = 0;

always @(posedge clk_i) begin
  if (rstate == idle && vstate == compare_tag) begin
    c_access += 1;
    c_cycle += 1;
  end
  else if (rstate == compare_tag) begin
    if (vstate != idle) c_miss += 1;
    c_cycle += 1;
  end
  else if (rstate == write_back) begin
    c_mem += 1;
    c_cycle += 10;
  end
  else if (rstate == allocate) begin
    c_mem += 1;
    c_cycle += 10;
  end
end
// !

reg [1:0] vstate;
reg [1:0] rstate;

/* signals to tag memory */
wire                 tag_read_valid;
wire                 tag_read_dirty;
wire [TAGMSB:TAGLSB] tag_read_tag;
reg                 tag_write_valid;
reg                 tag_write_dirty;
reg [TAGMSB:TAGLSB] tag_write_tag;
reg [3:0]           tag_req_index;
reg                 tag_req_we;
/* signals to cache data memory */
wire [255:0]         data_read;
reg [255:0]         data_write;
reg [3:0]           data_req_index;
reg                 data_req_we;
/* temporary variable for cache controller result */
reg [63:0]          v_cpu_res_data;
reg                 v_cpu_res_ready;
/* temporary variable for memory controller request */
reg [63:0]          v_mem_req_addr;
reg [255:0]         v_mem_req_data;
reg                 v_mem_req_rw;
reg                 v_mem_req_valid;

assign mem_req_rw_o     = v_mem_req_rw;
assign mem_req_valid_o  = v_mem_req_valid;
assign mem_req_data_o   = v_mem_req_data;
assign mem_req_addr_o   = v_mem_req_addr;
assign cpu_res_data_o   = v_cpu_res_data;
assign cpu_res_ready_o  = v_cpu_res_ready;

always @(*) begin
  vstate = rstate;
  v_cpu_res_data    = 0;
  v_cpu_res_ready   = 0;
  
  tag_write_dirty   = 0;
  tag_write_valid   = 0;
  tag_write_tag     = 0;

  tag_req_we    = 0;
  tag_req_index = cpu_req_addr_i[8:5];

  data_req_we     = 0;
  data_req_index  = cpu_req_addr_i[8:5];
  
  /* cache写入数据 */
  data_write = data_read;
  case (cpu_req_addr_i[4:3])
    2'b00: data_write[63:0]    = cpu_req_data_i;
    2'b01: data_write[127:64]  = cpu_req_data_i;
    2'b10: data_write[191:128] = cpu_req_data_i; 
    2'b11: data_write[255:192] = cpu_req_data_i;
  endcase
  /* cache读取数据 */
  case (cpu_req_addr_i[4:3])
    2'b00: v_cpu_res_data = data_read[63:0];
    2'b01: v_cpu_res_data = data_read[127:64];
    2'b10: v_cpu_res_data = data_read[191:128]; 
    2'b11: v_cpu_res_data = data_read[255:192];
  endcase

  /* cpu访存地址 */
  v_mem_req_addr  = cpu_req_addr_i & (~64'h1F);
  /* cpu访存数据 */
  v_mem_req_data  = data_read;
  v_mem_req_rw    = 0;

  //------Cache FSM------
  case (rstate)
    idle: begin
      v_mem_req_valid = 0;
      /* 如果有cpu访问cache的请求,进入标签比较 */
      if (cpu_req_valid_i)
        vstate = compare_tag;
    end
    compare_tag: begin
      /* cache hit & valid */
      if (cpu_req_addr_i[TAGMSB:TAGLSB] == tag_read_tag && tag_read_valid) begin
        v_cpu_res_ready = 1;
        v_mem_req_valid = 0;
        /* 写命中 */
        if (cpu_req_rw_i) begin
          /* 修改cache行 */
          tag_req_we    = 1; 
          data_req_we   = 1;
          /* tag不做改变 */
          tag_write_tag   = tag_read_tag;
          tag_write_valid = 1;
          /* 标记cache内容修改过 */
          tag_write_dirty = 1;
        end
        vstate = idle;
      end
      /* cache miss */
      else begin
        /* 生成新的tag */
        tag_req_we = 1;
        tag_write_valid = 1;
        /* new tag */
        tag_write_tag = cpu_req_addr_i[TAGMSB:TAGLSB];
        /* 如果要写回, 标记行被修改过 */
        tag_write_dirty = cpu_req_rw_i;

        /* cache miss向内存申请新块 */ 
        v_mem_req_valid = 1;

        /* 强制未命中或未命中干净块 */
        if (tag_read_valid == 1'b0 || tag_read_dirty == 1'b0)
          /* 等待申请到新的块 */
          vstate = allocate;
        /* 未命中修改过的块 */
        else begin
          /* 脏块写回的地址 */
          v_mem_req_addr  = { tag_read_tag, cpu_req_addr_i[TAGLSB-1:0] } & (~64'h1F);
          v_mem_req_rw    = 1;
          /* 等待写回完成 */
          vstate = write_back;
        end
      end
    end
    allocate: begin
      /* 内存控制器响应 */
      if (mem_data_ready_i) begin
        /* 回到compare tag */
        vstate = compare_tag;
        data_write = mem_data_data_i;
        /* 更新cache行的data */
        data_req_we = 1;
      end
    end
    write_back: begin
      /* 写回完成 */
      if (mem_data_ready_i) begin
        /* 发起新的内存请求,请求分配新的cache行 */
        v_mem_req_valid = 1;
        v_mem_req_rw = 0;
        vstate = allocate;
      end
    end
  endcase
end

always @(posedge clk_i) begin
  if (~rst_n_i) rstate <= idle;
  else rstate <= vstate;
end

cache_tag ctag(
  .clk_i(clk_i),
  .rst_n_i(rst_n_i),
  .tag_index_i(tag_req_index),
  .tag_we_i(tag_req_we),
  .tag_write_i({ tag_write_valid, tag_write_dirty, tag_write_tag }),
  .tag_read_o({ tag_read_valid, tag_read_dirty, tag_read_tag })
);
cache_data cdata(
  .clk_i(clk_i),
  .data_req_index_i(data_req_index),
  .data_req_we_i(data_req_we),
  .data_write_i(data_write),
  .data_read_o(data_read)
);

endmodule
