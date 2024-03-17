`include "define.v"

module predictor(
  input  wire        clk_i,
  input  wire        rst_n_i,
  input  wire [63:0] f_PC_i,
  input  wire [3:0]  f_icode_i,
  input  wire [63:0] f_valC_i,
  input  wire [63:0] f_valP_i,
  input  wire [63:0] E_PC_i,
  input  wire [3:0]  E_icode_i,
  input  wire        E_branch_taken_i,
  input  wire        e_Cnd_i,

  output wire [63:0] f_predPC_o,
  output wire        f_branch_taken_o
);
wire predict_taken;
wire predict_valid;
wire train_mispredicted;
wire train_valid;
wire train_taken;

assign predict_valid  = (f_icode_i == `IJXX);
assign train_mispredicted = train_valid & (e_Cnd_i ^ E_branch_taken_i);
assign train_valid    = (E_icode_i == `IJXX);
assign train_taken    = E_branch_taken_i ^ train_mispredicted;
assign f_branch_taken_o = predict_taken;
assign f_predPC_o = ((f_icode_i == `IJXX && predict_taken) || f_icode_i == `ICALL) ? f_valC_i : f_valP_i;

pred_gshare gshare(
  .clk(clk_i),
  .reset(~rst_n_i),
  .predict_valid(predict_valid),
  .train_valid(train_valid),
  .train_taken(train_taken),
  .train_mispredicted(train_mispredicted),
  .f_PC(f_PC_i),
  .E_PC(E_PC_i),
  .predict_taken(predict_taken)
);

endmodule

module pred_gshare (
  input wire        clk,
  input wire        reset,
  input wire        predict_valid,
  input wire        train_valid,
  input wire        train_taken,
  input wire        train_mispredicted,
  input wire [63:0] E_PC,
  input wire [63:0] f_PC,

  output wire predict_taken
);
localparam INDEX_BITS = 7, PHT_SIZE = (1 << INDEX_BITS);
localparam SNT = 2'b00, WNT = 2'b01, WT = 2'b10, ST = 2'b11;

reg [1:0] PHT[PHT_SIZE-1:0];
reg [INDEX_BITS-1:0] predict_history, train_history;

wire [INDEX_BITS-1:0] train_pc    = E_PC[0+:INDEX_BITS];
wire [INDEX_BITS-1:0] predict_pc  = f_PC[0+:INDEX_BITS];

always @(posedge clk) begin
  if (reset) begin
    predict_history <= {INDEX_BITS{1'b0}};
    train_history   <= {INDEX_BITS{1'b0}};
  end
  else if (train_valid & train_mispredicted)
    predict_history <= { train_history[INDEX_BITS-2:0], train_taken };
  else if (predict_valid)
    predict_history <= { predict_history[INDEX_BITS-2:0], predict_taken };
end

integer i;
always @(posedge clk) begin
  if (reset)
      for (i = 0; i < PHT_SIZE; i = i + 1) PHT[i] = WNT;
  else if (train_valid)
      train_history <= { train_history[INDEX_BITS-2:0], train_taken };
      case (PHT[train_pc ^ train_history])
        SNT: PHT[train_pc ^ train_history] <= (train_valid & train_taken) ? WNT : SNT;
        WNT: PHT[train_pc ^ train_history] <= train_valid ? train_taken ? WT : SNT : WNT;
        WT:	 PHT[train_pc ^ train_history] <= train_valid ? train_taken ? ST : WNT : WT;
        ST:	 PHT[train_pc ^ train_history] <= train_valid ? train_taken ? ST : WT : ST;
      endcase
end

assign predict_taken = PHT[predict_pc ^ predict_history][1];

endmodule