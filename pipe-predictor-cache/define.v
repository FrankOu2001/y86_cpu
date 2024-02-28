// Instruction Codes
`define IHALT     4'H0
`define INOP      4'H1
`define IRRMOVQ   4'H2 
`define IIRMOVQ   4'H3
`define IRMMOVQ   4'H4
`define IMRMOVQ   4'H5
`define IOPQ      4'H6
`define IJXX      4'H7
`define ICALL     4'H8
`define IRET      4'H9
`define IPUSHQ    4'HA
`define IPOPQ     4'HB

// RegisterFile Codes
`define RRSP      4'H4
`define RNONE     4'HF

// Instruction Functions
`define FNONE     4'H0
`define FADDL     4'H0
`define FSUBL     4'H1
`define FANDL     4'H2
`define FXORL     4'H3
// ALU Operations(belong to Instruction Function)
`define ALUADD    4'H0
`define ALUSUB    4'H1
`define ALUAND    4'H2
`define ALUXOR    4'H3


// Condition Marcos
`define C_YES     4'H0
`define C_LE      4'H1
`define C_L       4'H2
`define C_E       4'H3
`define C_NE      4'H4
`define C_GE      4'H5
`define C_G       4'H6

// State Code
`define SAOK      3'H1
`define SINS      3'H2
`define SADR      3'H3
`define SHLT      3'H4