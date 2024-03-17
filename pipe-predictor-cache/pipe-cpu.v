`timescale 1ns/1ps

`include "fetch.v"
`include "select_pc.v"
`include "predictor.v"
`include "decode.v"
`include "execute.v"
`include "memory.v"
`include "F_pipe_reg.v"
`include "fetch_D_pipe_reg.v"
`include "decode_E_pipe_reg.v"
`include "execute_M_pipe_reg.v"
`include "memory_W_pipe_reg.v"
`include "pipeline_control.v"

module pipe_tb;

reg clk;
reg rst_n;

wire F_bubble, F_stall;
wire D_bubble, D_stall;
wire E_bubble, E_stall;
wire M_bubble, M_stall;
wire W_bubble, W_stall;

wire [63:0] F_predPC;
wire [63:0] f_PC;
wire [ 3:0] f_icode;
wire [ 3:0] f_ifun;
wire [ 3:0] f_rA;
wire [ 3:0] f_rB;
wire [63:0] f_valC;
wire [63:0] f_valP;
wire [63:0] f_predPC;
wire [ 2:0] f_stat;
wire        f_branch_taken;
wire [63:0] D_PC;
wire [ 3:0] D_icode;
wire [ 3:0] D_ifun;
wire [ 3:0] D_rA;
wire [ 3:0] D_rB;
wire [63:0] D_valC;
wire [63:0] D_valP;
wire [63:0] D_predPC;
wire [ 2:0] D_stat;
wire        D_branch_taken;
wire [63:0] d_valA;
wire [63:0] d_valB;
wire [ 3:0] d_dstE;
wire [ 3:0] d_dstM;
wire [ 3:0] d_srcA;
wire [ 3:0] d_srcB;
wire [63:0] E_PC;
wire [ 2:0] E_stat;
wire [ 3:0] E_icode;
wire [ 3:0] E_ifun;
wire        E_branch_taken;
wire [63:0] E_valC;
wire [63:0] E_valA;
wire [63:0] E_valB;
wire [ 3:0] E_dstM;
wire [ 3:0] E_dstE;
wire [ 3:0] E_srcA;
wire [ 3:0] E_srcB;
wire [ 3:0] e_dstE;
wire [63:0] e_valE;
wire        e_Cnd;
wire [63:0] e_valA;
wire [3:0]  M_dstE;
wire [63:0] M_valE;
wire [ 3:0] M_dstM;
wire [ 2:0] M_stat;
wire [ 3:0] M_icode;
wire        M_Cnd;
wire        M_branch_taken;
wire [63:0] M_valA;
wire [63:0] m_valM;
wire [ 2:0] m_stat;
wire [ 3:0] W_dstM;
wire [63:0] W_valM;
wire [ 3:0] W_dstE;
wire [63:0] W_valE;
wire [ 2:0] W_stat;
wire [ 3:0] W_icode;

wire [63:0] mem_addr;
wire [63:0] mem_wdata;
wire        mem_re;
wire        mem_we;
wire        dmem_error;
wire [63:0] mem_rdata;
wire        h_cache_access;
reg         done = 0;

F_pipe_reg F_preg(
    .clk_i(clk),
    .F_stall_i(F_stall),
    .F_bubble_i(~rst_n),
    .f_predPC_i(f_predPC),
    .F_predPC_o(F_predPC)
);

select_pc Select_PC(
    .F_predPC_i(F_predPC),
    .M_icode_i(M_icode),
    .M_Cnd_i(M_Cnd),
    .M_valA_i(M_valA),
    .M_valE_i(M_valE),
    .M_branch_taken_i(M_branch_taken),
    .W_icode_i(W_icode),
    .W_valM_i(W_valM),
    .f_PC_o(f_PC)
);

predictor PredictPC(
    .clk_i(clk),
    .rst_n_i(rst_n),
    .f_PC_i(f_PC),
    .f_icode_i(f_icode),
    .f_valC_i(f_valC),
    .f_valP_i(f_valP),
    .E_PC_i(E_PC),
    .E_icode_i(E_icode),
    .E_branch_taken_i(E_branch_taken),
    .e_Cnd_i(e_Cnd),
    .f_predPC_o(f_predPC),
    .f_branch_taken_o(f_branch_taken)
);

fetch Fetch(
    .f_PC_i(f_PC),
    .f_icode_o(f_icode),
    .f_ifun_o(f_ifun),
    .f_rA_o(f_rA),
    .f_rB_o(f_rB),
    .f_valC_o(f_valC),
    .f_valP_o(f_valP),
    .f_stat_o(f_stat)
);

fetch_D_pipe_reg D_preg(
    .clk_i(clk),
    .D_stall_i(D_stall),
    .D_bubble_i(~rst_n || D_bubble),
    
    .f_PC_i(f_PC),
    .f_stat_i(f_stat),
    .f_icode_i(f_icode),
    .f_ifun_i(f_ifun),
    .f_rA_i(f_rA),
    .f_rB_i(f_rB),
    .f_valC_i(f_valC),
    .f_valP_i(f_valP),
    .f_branch_taken_i(f_branch_taken),
    
    .D_PC_o(D_PC),
    .D_stat_o(D_stat),
    .D_icode_o(D_icode),
    .D_ifun_o(D_ifun),
    .D_rA_o(D_rA),
    .D_rB_o(D_rB),
    .D_valC_o(D_valC),
    .D_valP_o(D_valP),
    .D_branch_taken_o(D_branch_taken)
);

decode Decode(
    .clk_i(clk),
    .D_icode_i(D_icode),
    .D_ifun_i(D_ifun),
    .D_rA_i(D_rA),
    .D_rB_i(D_rB),
    .D_valC_i(D_valC),
    .D_valP_i(D_valP),
    .e_dstE_i(e_dstE),
    .e_valE_i(e_valE),
    .M_dstE_i(M_dstE),
    .M_valE_i(M_valE),
    .m_valM_i(m_valM),
    .M_dstM_i(M_dstM),
    .W_dstM_i(W_dstM),
    .W_valM_i(W_valM),
    .W_dstE_i(W_dstE),
    .W_valE_i(W_valE),
    .d_valA_o(d_valA),
    .d_valB_o(d_valB),
    .d_dstE_o(d_dstE),
    .d_dstM_o(d_dstM),
    .d_srcA_o(d_srcA),
    .d_srcB_o(d_srcB),
    .done(done)
);

decode_E_pipe_reg E_preg(
    .clk_i(clk),
    .E_stall_i(E_stall),
    .E_bubble_i(~rst_n || E_bubble),

    .D_PC_i(D_PC),
    .D_stat_i(D_stat),
    .D_icode_i(D_icode),
    .D_ifun_i(D_ifun),
    .D_valC_i(D_valC),
    .D_branch_taken_i(D_branch_taken),
    .d_valA_i(d_valA),
    .d_valB_i(d_valB),
    .d_dstE_i(d_dstE),
    .d_dstM_i(d_dstM),
    .d_srcA_i(d_srcA),
    .d_srcB_i(d_srcB),
    .E_PC_o(E_PC),
    .E_stat_o(E_stat),
    .E_icode_o(E_icode),
    .E_ifun_o(E_ifun),
    .E_valC_o(E_valC),
    .E_valA_o(E_valA),
    .E_valB_o(E_valB),
    .E_dstE_o(E_dstE),
    .E_dstM_o(E_dstM),
    .E_srcA_o(E_srcA),
    .E_srcB_o(E_srcB),
    .E_branch_taken_o(E_branch_taken)
);

execute Execute(
    .clk_i(clk),
    .rst_n_i(rst_n),
    .E_icode_i(E_icode),
    .E_ifun_i(E_ifun),
    .E_valC_i(E_valC),
    .E_valA_i(E_valA),
    .E_valB_i(E_valB),
    .E_dstE_i(E_dstE),
    .E_dstM_i(E_dstM),
    .E_srcA_i(E_srcA),
    .M_dstM_i(M_dstM),
    .m_valM_i(m_valM),
    .m_stat_i(m_stat),
    .W_stat_i(W_stat),
    .e_Cnd_o(e_Cnd),
    .e_valA_o(e_valA),
    .e_valE_o(e_valE),
    .e_dstE_o(e_dstE),
    .e_dstM_o(E_dstM)
);

execute_M_pipe_reg M_preg(
    .clk_i(clk),
    .M_bubble_i(~rst_n),
    .M_stall_i(M_stall),

    .E_stat_i(E_stat),
    .E_icode_i(E_icode),
    .E_branch_taken_i(E_branch_taken),
    .e_Cnd_i(e_Cnd),
    .e_valE_i(e_valE),
    .e_valA_i(e_valA),
    .e_dstE_i(e_dstE),
    .E_dstM_i(E_dstM),
    .M_stat_o(M_stat),
    .M_icode_o(M_icode),
    .M_Cnd_o(M_Cnd),
    .M_valE_o(M_valE),
    .M_valA_o(M_valA),
    .M_dstE_o(M_dstE),
    .M_dstM_o(M_dstM),
    .M_branch_taken_o(M_branch_taken)
);

memory Memory(
    .clk_i(clk),
    .rst_n_i(rst_n),
    .M_stat_i(M_stat),
    .M_icode_i(M_icode),
    .M_valE_i(M_valE),
    .M_valA_i(M_valA),
    .M_dstE_i(M_dstE),
    .M_dstM_i(M_dstM),
    .m_stat_o(m_stat),
    .m_valM_o(m_valM),
    .h_cache_access_o(h_cache_access),
    .done(done)
);

memory_W_pipe_reg W_preg(
    .clk_i(clk),
    .W_stall_i(W_stall),
    .W_bubble_i(~rst_n || W_bubble),
    .m_stat_i(m_stat),
    .M_icode_i(M_icode),
    .M_valE_i(M_valE),
    .m_valM_i(m_valM),
    .M_dstE_i(M_dstE),
    .M_dstM_i(M_dstM),
    .W_stat_o(W_stat),
    .W_icode_o(W_icode),
    .W_valE_o(W_valE),
    .W_valM_o(W_valM),
    .W_dstE_o(W_dstE),
    .W_dstM_o(W_dstM)
);

pipeline_control Pipeline_Control(
    .D_icode_i(D_icode),
    .d_srcA_i(d_srcA),
    .d_srcB_i(d_srcB),
    .E_icode_i(E_icode),
    .E_dstM_i(E_dstM),
    .E_branch_taken_i(E_branch_taken),
    .e_Cnd_i(e_Cnd),
    .M_icode_i(M_icode),
    .m_stat_i(m_stat),
    .W_stat_i(W_stat),
    .h_cache_access_i(h_cache_access),
    .F_stall_o(F_stall),
    .D_stall_o(D_stall),
    .D_bubble_o(D_bubble),
    .E_stall_o(E_stall),
    .E_bubble_o(E_bubble),
    .M_stall_o(M_stall),
    .M_bubble_o(M_bubble),
    .W_stall_o(W_stall),
    .W_bubble_o(W_bubble)
);

initial clk = 0;
always #5 clk = ~clk;

always @(*) begin
    if (W_icode == `IHALT) begin
        done = 1;
        #10 $finish;
    end
end

initial begin
    $dumpfile("wave.vcd");
    $dumpvars(0, pipe_tb);
end

initial begin
    // Start!
    rst_n = 0; #10;
    rst_n = 1; 
    #4000000000;$finish;
end
endmodule