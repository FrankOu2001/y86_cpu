`include "define.v"

module fetch(
    input   wire [63:0] PC_i,
    output  wire [3:0]  icode_o,
    output  wire [3:0]  ifun_o,
    output  wire [3:0]  rA_o,
    output  wire [3:0]  rB_o,
    output  wire [63:0] valC_o,
    output  wire [63:0] valP_o,
    output  wire [63:0] predPC_o,
    output  wire [2:0]  stat_o
);
wire [79:0] instr;
wire        instr_valid;
wire        imem_error;
wire        need_regids;
wire        need_valC;

instr_memory mem(
    .raddr_i(PC_i),
    .rdata_o(instr),
    .imem_error_o(imem_error)
);

assign icode_o     = instr[7:4];
assign ifun_o      = instr[3:0];
assign instr_valid = (icode_o < 4'hC);
assign need_regids = (icode_o == `IRRMOVQ) || (icode_o == `IIRMOVQ) || 
    (icode_o == `IMRMOVQ) || (icode_o == `IOPQ) || 
    (icode_o == `IRMMOVQ) || (icode_o == `IPUSHQ) || (icode_o == `IPOPQ);
assign need_valC = (icode_o == `IIRMOVQ) || (icode_o == `IRMMOVQ) || 
    (icode_o == `IMRMOVQ) || (icode_o == `IJXX) || (icode_o == `ICALL);
assign rA_o = need_regids ? instr[15:12] : 4'hF;
assign rB_o = need_regids ? instr[11: 8] : 4'hF;    

assign valC_o = need_regids ? instr[79:16] : instr[71:8];
assign valP_o = PC_i + 1 + 8 * need_valC + need_regids;
assign predPC_o = (icode_o == `IJXX || icode_o == `ICALL) ? valC_o : valP_o;

assign stat_o = imem_error ? `SADR : 
    ~instr_valid ? `SINS : 
    icode_o == `IHALT ? `SHLT : `SAOK;
endmodule

module instr_memory (
    input   wire [63:0] raddr_i,
    output  wire [79:0] rdata_o,
    output  wire        imem_error_o
);

parameter MEM_MAX_SIZE = 1024;
reg [7:0] mem[0:1023];

assign imem_error_o = (raddr_i >= MEM_MAX_SIZE);
assign rdata_o = {
    mem[raddr_i + 9], mem[raddr_i + 8], mem[raddr_i + 7],
    mem[raddr_i + 6], mem[raddr_i + 5], mem[raddr_i + 4],
    mem[raddr_i + 3], mem[raddr_i + 2], mem[raddr_i + 1],
    mem[raddr_i]
};

initial begin
//                            | # Modification of asum code to compute absolute values of entries.
//                            | # This version uses a conditional jump
//                            | # Execution begins at address 0 
//0x000:                      | 	.pos 0 
//0x000: 30f40003000000000000 | 	irmovq stack, %rsp  	# Set up stack pointer  
    mem[0] = 8'h30;
    mem[1] = 8'hf4;
    mem[2] = 8'h00;
    mem[3] = 8'h03;
    mem[4] = 8'h00;
    mem[5] = 8'h00;
    mem[6] = 8'h00;
    mem[7] = 8'h00;
    mem[8] = 8'h00;
    mem[9] = 8'h00;
//0x00a: 801802000000000000   | 	call main		# Execute main program
    mem[10] = 8'h80;
    mem[11] = 8'h18;
    mem[12] = 8'h02;
    mem[13] = 8'h00;
    mem[14] = 8'h00;
    mem[15] = 8'h00;
    mem[16] = 8'h00;
    mem[17] = 8'h00;
    mem[18] = 8'h00;
//0x013: 00                   | 	halt			# Terminate program 
    mem[19] = 8'h00;
//                            | 

//0x218: 30f71800000000000000 | main:	irmovq array,%rdi	
    mem[536] = 8'h30;
    mem[537] = 8'hf7;
    mem[538] = 8'h18;
    mem[539] = 8'h00;
    mem[540] = 8'h00;
    mem[541] = 8'h00;
    mem[542] = 8'h00;
    mem[543] = 8'h00;
    mem[544] = 8'h00;
    mem[545] = 8'h00;
//0x222: 30f64000000000000000 | 	irmovq $64,%rsi
    mem[546] = 8'h30;
    mem[547] = 8'hf6;
    mem[548] = 8'h40;
    mem[549] = 8'h00;
    mem[550] = 8'h00;
    mem[551] = 8'h00;
    mem[552] = 8'h00;
    mem[553] = 8'h00;
    mem[554] = 8'h00;
    mem[555] = 8'h00;
//0x22c: 803602000000000000   | 	call absSum		# absSum(array, 4)
    mem[556] = 8'h80;
    mem[557] = 8'h36;
    mem[558] = 8'h02;
    mem[559] = 8'h00;
    mem[560] = 8'h00;
    mem[561] = 8'h00;
    mem[562] = 8'h00;
    mem[563] = 8'h00;
    mem[564] = 8'h00;
//0x235: 90                   | 	ret 
    mem[565] = 8'h90;
//                            | /* $begin abs-sum-jmp-ys */
//                            | # long absSum(long *start, long count)
//                            | # start in %rdi, count in %rsi
//0x236:                      | absSum:
//0x236: 30f80800000000000000 | 	irmovq $8,%r8           # Constant 8
    mem[566] = 8'h30;
    mem[567] = 8'hf8;
    mem[568] = 8'h08;
    mem[569] = 8'h00;
    mem[570] = 8'h00;
    mem[571] = 8'h00;
    mem[572] = 8'h00;
    mem[573] = 8'h00;
    mem[574] = 8'h00;
    mem[575] = 8'h00;
//0x240: 30f90100000000000000 | 	irmovq $1,%r9	        # Constant 1
    mem[576] = 8'h30;
    mem[577] = 8'hf9;
    mem[578] = 8'h01;
    mem[579] = 8'h00;
    mem[580] = 8'h00;
    mem[581] = 8'h00;
    mem[582] = 8'h00;
    mem[583] = 8'h00;
    mem[584] = 8'h00;
    mem[585] = 8'h00;
//0x24a: 6300                 | 	xorq %rax,%rax		# sum = 0
    mem[586] = 8'h63;
    mem[587] = 8'h00;
//0x24c: 6266                 | 	andq %rsi,%rsi		# Set condition codes
    mem[588] = 8'h62;
    mem[589] = 8'h66;
//0x24e: 707602000000000000   | 	jmp  test
    mem[590] = 8'h70;
    mem[591] = 8'h76;
    mem[592] = 8'h02;
    mem[593] = 8'h00;
    mem[594] = 8'h00;
    mem[595] = 8'h00;
    mem[596] = 8'h00;
    mem[597] = 8'h00;
    mem[598] = 8'h00;
//0x257:                      | loop:
//0x257: 50a70000000000000000 | 	mrmovq (%rdi),%r10	# x = *start
    mem[599] = 8'h50;
    mem[600] = 8'ha7;
    mem[601] = 8'h00;
    mem[602] = 8'h00;
    mem[603] = 8'h00;
    mem[604] = 8'h00;
    mem[605] = 8'h00;
    mem[606] = 8'h00;
    mem[607] = 8'h00;
    mem[608] = 8'h00;
//0x261: 63bb                 | 	xorq %r11,%r11          # Constant 0
    mem[609] = 8'h63;
    mem[610] = 8'hbb;
//0x263: 61ab                 | 	subq %r10,%r11		# -x
    mem[611] = 8'h61;
    mem[612] = 8'hab;
//0x265: 717002000000000000   | 	jle pos			# Skip if -x <= 0
    mem[613] = 8'h71;
    mem[614] = 8'h70;
    mem[615] = 8'h02;
    mem[616] = 8'h00;
    mem[617] = 8'h00;
    mem[618] = 8'h00;
    mem[619] = 8'h00;
    mem[620] = 8'h00;
    mem[621] = 8'h00;
//0x26e: 20ba                 | 	rrmovq %r11,%r10	# x = -x
    mem[622] = 8'h20;
    mem[623] = 8'hba;
//0x270:                      | pos:
//0x270: 60a0                 | 	addq %r10,%rax          # Add to sum
    mem[624] = 8'h60;
    mem[625] = 8'ha0;
//0x272: 6087                 | 	addq %r8,%rdi           # start++
    mem[626] = 8'h60;
    mem[627] = 8'h87;
//0x274: 6196                 | 	subq %r9,%rsi           # count--
    mem[628] = 8'h61;
    mem[629] = 8'h96;
//0x276:                      | test:
//0x276: 745702000000000000   | 	jne    loop             # Stop when 0
    mem[630] = 8'h74;
    mem[631] = 8'h57;
    mem[632] = 8'h02;
    mem[633] = 8'h00;
    mem[634] = 8'h00;
    mem[635] = 8'h00;
    mem[636] = 8'h00;
    mem[637] = 8'h00;
    mem[638] = 8'h00;
//0x27f: 90                   | 	ret
    mem[639] = 8'h90;
//                            | /* $end abs-sum-jmp-ys */
//                            | 
//                            | # The stack starts here and grows to lower addresses
//0x300:                      | 	.pos 0x300	
//0x300:                      | stack:	 

end
endmodule