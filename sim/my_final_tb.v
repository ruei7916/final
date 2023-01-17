`timescale 1ns/100ps


`define PAT_L 0
`define PAT_U 1
`define NUM_PAT (`PAT_U-`PAT_L+1)

`define PAT_NAME_LENGTH 3    // 3 digits
`define CYCLE 10
`define END_CYCLES 100000000 // you can enlarge the cycle count limit for longer simulation
`define FLAG_VERBOSE 0   
`define FLAG_SHOWNUM 0
`define FLAG_DUMPWV 0

module test_top;
localparam CH_NUM = 1;
localparam ACT_PER_ADDR = 4;
localparam BW_PER_ACT = 12;
localparam BW_PER_SRAM_GROUP_ADDR = CH_NUM*ACT_PER_ADDR*BW_PER_ACT; // 1 x 4 x 12 = 48
localparam WEIGHT_PER_ADDR = 72, BIAS_PER_ADDR = 8;
localparam BW_PER_PARAM = 8;
localparam Pattern_N = 226*226;


localparam INPUT = 4'd0, CONV3_POOL_1 = 4'd1, CONV3_2 = 4'd2, CONV3_POOL_3 = 4'd3, RES1_CONV3_4 = 4'd4, RES1_CONV3_5 = 4'd5, RES2_CONV3_6 = 4'd6;
localparam RES2_CONV3_7 = 4'd7, CONV3_POOL_8 = 4'd8, RES3_CONV3_9 = 4'd9,  RES3_CONV3_10 = 4'd10, CONV3_POOL_11 = 4'd11;
localparam GLOBAL_AVE = 4'd12, FC = 4'd13;

localparam A0=0, A1=1, A2=2, A3=3, B0=4, B1=5, B2=6, B3=7;

integer test_layer;

initial begin
    `ifdef TEST_INPUT
        test_layer = INPUT;
    `elsif TEST_CONV3_POOL_1
        test_layer = CONV3_POOL_1;
    `elsif TEST_CONV3_2
        test_layer = CONV3_2;
    `elsif TEST_CONV3_POOL_3
        test_layer = CONV3_POOL_3;
    `elsif TEST_RES1_CONV3_4
        test_layer = RES1_CONV3_4;
    `elsif TEST_RES1_CONV3_5
        test_layer = RES1_CONV3_5;
    `elsif TEST_RES2_CONV3_6
        test_layer = RES2_CONV3_6;
    `elsif TEST_RES2_CONV3_7
        test_layer = RES2_CONV3_7;
    `elsif TEST_CONV3_POOL_8
        test_layer = CONV3_POOL_8;
    `elsif TEST_RES3_CONV3_9
        test_layer = RES3_CONV3_9;
    `elsif TEST_RES3_CONV3_10
        test_layer = RES3_CONV3_10;
    `elsif TEST_CONV3_POOL_11
        test_layer = CONV3_POOL_11;
    `elsif TEST_GLOBAL_AVE
        test_layer = GLOBAL_AVE;
    `elsif TEST_FC
        test_layer = FC;
    `else
        test_layer = FC;
    `endif
end

integer i;
// ===== pattern files ===== // 

reg [23*8-1:0] input_a0_golden_file,         input_a1_golden_file,         input_a2_golden_file,         input_a3_golden_file;
reg [30*8-1:0] conv3_pool_1_b0_golden_file,  conv3_pool_1_b1_golden_file,  conv3_pool_1_b2_golden_file,  conv3_pool_1_b3_golden_file;
reg [25*8-1:0] conv3_2_a0_golden_file,       conv3_2_a1_golden_file,       conv3_2_a2_golden_file,       conv3_2_a3_golden_file;
reg [30*8-1:0] conv3_pool_3_b0_golden_file,  conv3_pool_3_b1_golden_file,  conv3_pool_3_b2_golden_file,  conv3_pool_3_b3_golden_file;
reg [30*8-1:0] res1_conv3_4_a0_golden_file,  res1_conv3_4_a1_golden_file,  res1_conv3_4_a2_golden_file,  res1_conv3_4_a3_golden_file;
reg [30*8-1:0] res1_conv3_5_b0_golden_file,  res1_conv3_5_b1_golden_file,  res1_conv3_5_b2_golden_file,  res1_conv3_5_b3_golden_file;
reg [30*8-1:0] res2_conv3_6_a0_golden_file,  res2_conv3_6_a1_golden_file,  res2_conv3_6_a2_golden_file,  res2_conv3_6_a3_golden_file;
reg [30*8-1:0] res2_conv3_7_b0_golden_file,  res2_conv3_7_b1_golden_file,  res2_conv3_7_b2_golden_file,  res2_conv3_7_b3_golden_file;
reg [30*8-1:0] conv3_pool_8_a0_golden_file,  conv3_pool_8_a1_golden_file,  conv3_pool_8_a2_golden_file,  conv3_pool_8_a3_golden_file;
reg [30*8-1:0] res3_conv3_9_b0_golden_file,  res3_conv3_9_b1_golden_file,  res3_conv3_9_b2_golden_file,  res3_conv3_9_b3_golden_file;
reg [31*8-1:0] res3_conv3_10_a0_golden_file, res3_conv3_10_a1_golden_file, res3_conv3_10_a2_golden_file, res3_conv3_10_a3_golden_file;
reg [31*8-1:0] conv3_pool_11_b0_golden_file, conv3_pool_11_b1_golden_file, conv3_pool_11_b2_golden_file, conv3_pool_11_b3_golden_file;

reg [25*8-1:0] global_ave_a0_golden_file;
reg [17*8-1:0] fc_golden_file;

// ===== module I/O ===== //
reg clk;
reg srst_n; // synchronous reset (active low)
reg enable; // enable signal for notifying that the unshuffled image is ready in SRAM A
wire valid; // output valid for testbench to check answers in corresponding SRAM groups

wire [WEIGHT_PER_ADDR*BW_PER_PARAM-1:0] sram_rdata_weight; // 72 x 8 = 576
wire [12-1:0] sram_raddr_weight; // celi(log2 (2636)) =  12 bits 

wire [BIAS_PER_ADDR*BW_PER_PARAM-1:0] sram_rdata_bias; // 8 x 8 = 64
wire [6-1:0] sram_raddr_bias; // celi(log2 (60)) = 6 bits

wire sram_wen_a0;
wire sram_wen_a1;
wire sram_wen_a2;
wire sram_wen_a3;
wire sram_wen_b0;
wire sram_wen_b1;
wire sram_wen_b2;
wire sram_wen_b3;

wire [CH_NUM*ACT_PER_ADDR*BW_PER_ACT-1:0] sram_rdata_a0; // CH_NUM*ACT_PER_ADDR*BW_PER_ACT = 1*4*12 = 48
wire [CH_NUM*ACT_PER_ADDR*BW_PER_ACT-1:0] sram_rdata_a1;
wire [CH_NUM*ACT_PER_ADDR*BW_PER_ACT-1:0] sram_rdata_a2;
wire [CH_NUM*ACT_PER_ADDR*BW_PER_ACT-1:0] sram_rdata_a3;
wire [CH_NUM*ACT_PER_ADDR*BW_PER_ACT-1:0] sram_rdata_b0;
wire [CH_NUM*ACT_PER_ADDR*BW_PER_ACT-1:0] sram_rdata_b1;
wire [CH_NUM*ACT_PER_ADDR*BW_PER_ACT-1:0] sram_rdata_b2;
wire [CH_NUM*ACT_PER_ADDR*BW_PER_ACT-1:0] sram_rdata_b3;

wire [18-1:0] sram_raddr_a0; // celi(log2 (57*57*64)) = 18
wire [18-1:0] sram_raddr_a1;
wire [18-1:0] sram_raddr_a2;
wire [18-1:0] sram_raddr_a3;
wire [16-1:0] sram_raddr_b0; // celi(log2 (28*28*64)) = 16
wire [16-1:0] sram_raddr_b1;
wire [16-1:0] sram_raddr_b2;
wire [16-1:0] sram_raddr_b3;

wire [CH_NUM*ACT_PER_ADDR-1:0] sram_wordmask_a; // 1*4
wire [CH_NUM*ACT_PER_ADDR-1:0] sram_wordmask_b;

wire [18-1:0] sram_waddr_a; // SRAM A addr (0~57*57*64-1)
wire [16-1:0] sram_waddr_b; // SRAM B addr (0~28*28*64-1)
wire sram_waddr_mode; // something cool~

wire [CH_NUM*ACT_PER_ADDR*BW_PER_ACT-1:0] sram_wdata_a; // 1*4*12 = 48  
wire [CH_NUM*ACT_PER_ADDR*BW_PER_ACT-1:0] sram_wdata_b;  

// ===== instantiation ===== //
Resnet_top #(
.CH_NUM(CH_NUM),                   //input channel number = 1
.ACT_PER_ADDR(ACT_PER_ADDR),       //how many pixel       = 4
.BW_PER_ACT(BW_PER_ACT),           //bit per pixel        = 12
.WEIGHT_PER_ADDR(WEIGHT_PER_ADDR), //9*8 weight           = 72
.BIAS_PER_ADDR(BIAS_PER_ADDR),     //8 bias               = 8
.BW_PER_PARAM(BW_PER_PARAM)
)
top(
.clk(clk),
.srst_n(srst_n),
.enable(enable),
.valid(valid),

.sram_rdata_a0(sram_rdata_a0),
.sram_rdata_a1(sram_rdata_a1),
.sram_rdata_a2(sram_rdata_a2),
.sram_rdata_a3(sram_rdata_a3),
.sram_rdata_b0(sram_rdata_b0),
.sram_rdata_b1(sram_rdata_b1),
.sram_rdata_b2(sram_rdata_b2),
.sram_rdata_b3(sram_rdata_b3),
.sram_rdata_weight(sram_rdata_weight),
.sram_rdata_bias(sram_rdata_bias),


.sram_raddr_a0(sram_raddr_a0),
.sram_raddr_a1(sram_raddr_a1),
.sram_raddr_a2(sram_raddr_a2),
.sram_raddr_a3(sram_raddr_a3),
.sram_raddr_b0(sram_raddr_b0),
.sram_raddr_b1(sram_raddr_b1),
.sram_raddr_b2(sram_raddr_b2),
.sram_raddr_b3(sram_raddr_b3),
.sram_raddr_weight(sram_raddr_weight),
.sram_raddr_bias(sram_raddr_bias),

.sram_wen_a0(sram_wen_a0),
.sram_wen_a1(sram_wen_a1),
.sram_wen_a2(sram_wen_a2),
.sram_wen_a3(sram_wen_a3),
.sram_wen_b0(sram_wen_b0),
.sram_wen_b1(sram_wen_b1),
.sram_wen_b2(sram_wen_b2),
.sram_wen_b3(sram_wen_b3),

.sram_wordmask_a(sram_wordmask_a),
.sram_wordmask_b(sram_wordmask_b),

.sram_waddr_a(sram_waddr_a),
.sram_wdata_a(sram_wdata_a),
.sram_waddr_b(sram_waddr_b),
.sram_wdata_b(sram_wdata_b)

);

// ===== sram connection ===== //
// SRAM for PARAM
sram_2636x576b sram_2636x576b_weight(
.clk(clk),
.csb(1'b0),
.wsb(1'b1),
.wdata(576'd0), 
.waddr(12'd0), 
.raddr(sram_raddr_weight), 
.rdata(sram_rdata_weight)
);
sram_45x64b sram_45x64b_bias(
.clk(clk),
.csb(1'b0),
.wsb(1'b1),
.wdata(64'd0), 
.waddr(6'd0), 
.raddr(sram_raddr_bias), 
.rdata(sram_rdata_bias)
);
// SRAM A
sram_207936x48b sram_207936x48b_a0(
.clk(clk),
.wordmask(sram_wordmask_a),
.csb(1'b0),
.wsb(sram_wen_a0),
.msb(sram_waddr_mode),
.wdata(sram_wdata_a), 
.waddr(sram_waddr_a), 
.raddr(sram_raddr_a0), 
.rdata(sram_rdata_a0)
);
sram_207936x48b sram_207936x48b_a1(
.clk(clk),
.wordmask(sram_wordmask_a),
.csb(1'b0),
.wsb(sram_wen_a1),
.msb(sram_waddr_mode),
.wdata(sram_wdata_a), 
.waddr(sram_waddr_a), 
.raddr(sram_raddr_a1), 
.rdata(sram_rdata_a1)
);
sram_207936x48b sram_207936x48b_a2(
.clk(clk),
.wordmask(sram_wordmask_a),
.csb(1'b0),
.wsb(sram_wen_a2),
.msb(sram_waddr_mode),
.wdata(sram_wdata_a), 
.waddr(sram_waddr_a), 
.raddr(sram_raddr_a2), 
.rdata(sram_rdata_a2)
);
sram_207936x48b sram_207936x48b_a3(
.clk(clk),
.wordmask(sram_wordmask_a),
.csb(1'b0),
.wsb(sram_wen_a3),
.msb(sram_waddr_mode),
.wdata(sram_wdata_a), 
.waddr(sram_waddr_a), 
.raddr(sram_raddr_a3), 
.rdata(sram_rdata_a3)
);

// SRAM B
sram_50176x48b sram_50176x48b_b0(
.clk(clk),
.wordmask(sram_wordmask_b),
.csb(1'b0),
.wsb(sram_wen_b0),
.msb(sram_waddr_mode),
.wdata(sram_wdata_b), 
.waddr(sram_waddr_b), 
.raddr(sram_raddr_b0), 
.rdata(sram_rdata_b0)
);
sram_50176x48b sram_50176x48b_b1(
.clk(clk),
.wordmask(sram_wordmask_b),
.csb(1'b0),
.wsb(sram_wen_b1),
.msb(sram_waddr_mode),
.wdata(sram_wdata_b), 
.waddr(sram_waddr_b), 
.raddr(sram_raddr_b1), 
.rdata(sram_rdata_b1)
);
sram_50176x48b sram_50176x48b_b2(
.clk(clk),
.wordmask(sram_wordmask_b),
.csb(1'b0),
.wsb(sram_wen_b2),
.msb(sram_waddr_mode),
.wdata(sram_wdata_b), 
.waddr(sram_waddr_b), 
.raddr(sram_raddr_b2), 
.rdata(sram_rdata_b2)
);
sram_50176x48b sram_50176x48b_b3(
.clk(clk),
.wordmask(sram_wordmask_b),
.csb(1'b0),
.wsb(sram_wen_b3),
.msb(sram_waddr_mode),
.wdata(sram_wdata_b), 
.waddr(sram_waddr_b), 
.raddr(sram_raddr_b3), 
.rdata(sram_rdata_b3)
);

// ===== waveform dumpping ===== //

initial begin
    if(`FLAG_DUMPWV)begin
        $fsdbDumpfile("final_projct.fsdb");
        $fsdbDumpvars("+mda");
    end
end

// ===== parameters & golden answers ===== //
// input
reg [BW_PER_SRAM_GROUP_ADDR-1:0] input_ans_a0 [0:9577-1]; // BW_PER_SRAM_GROUP_ADDR = 48
reg [BW_PER_SRAM_GROUP_ADDR-1:0] input_ans_a1 [0:9577-1]; // celi((226/2)*(226/2) /4 *3) = 9577 
reg [BW_PER_SRAM_GROUP_ADDR-1:0] input_ans_a2 [0:9577-1];  
reg [BW_PER_SRAM_GROUP_ADDR-1:0] input_ans_a3 [0:9577-1];  

// conv3_pool_1
reg [WEIGHT_PER_ADDR*BW_PER_PARAM-1:0] conv3_pool_1_w [0:12-1]; // 3*32/8 = 12 (# of kernel)
reg [BIAS_PER_ADDR*BW_PER_PARAM-1:0] conv3_pool_1_b [0:4-1];    // 32/8 = 4 (# of kernel)
reg [BW_PER_SRAM_GROUP_ADDR-1:0] conv3_pool_1_ans_b0[0:25088-1], conv3_pool_1_ans_b1[0:25088-1], conv3_pool_1_ans_b2[0:25088-1], conv3_pool_1_ans_b3[0:25088-1];
// conv3_2
reg [WEIGHT_PER_ADDR*BW_PER_PARAM-1:0] conv3_2_w [0:128-1]; // 32*32/8
reg [BIAS_PER_ADDR*BW_PER_PARAM-1:0] conv3_2_b [0:4-1];
reg [BW_PER_SRAM_GROUP_ADDR-1:0] conv3_2_ans_a0[0:24200-1], conv3_2_ans_a1[0:24200-1], conv3_2_ans_a2[0:24200-1], conv3_2_ans_a3[0:24200-1];
// conv3_pool_3
reg [WEIGHT_PER_ADDR*BW_PER_PARAM-1:0] conv3_pool_3_w [0:128-1];
reg [BIAS_PER_ADDR*BW_PER_PARAM-1:0] conv3_pool_3_b [0:4-1];
reg [BW_PER_SRAM_GROUP_ADDR-1:0] conv3_pool_3_ans_b0 [0:5832-1], conv3_pool_3_ans_b1 [0:5832-1], conv3_pool_3_ans_b2 [0:5832-1], conv3_pool_3_ans_b3 [0:5832-1];

// res1_conv3_4
reg [WEIGHT_PER_ADDR*BW_PER_PARAM-1:0] res1_conv3_4_w [0:128-1];
reg [BIAS_PER_ADDR*BW_PER_PARAM-1:0] res1_conv3_4_b [0:4-1];
reg [BW_PER_SRAM_GROUP_ADDR-1:0] res1_conv3_4_ans_a0 [0:5408-1], res1_conv3_4_ans_a1 [0:5408-1], res1_conv3_4_ans_a2 [0:5408-1], res1_conv3_4_ans_a3 [0:5408-1];
// res1_conv3_5
reg [WEIGHT_PER_ADDR*BW_PER_PARAM-1:0] res1_conv3_5_w [0:128-1];
reg [BIAS_PER_ADDR*BW_PER_PARAM-1:0] res1_conv3_5_b [0:4-1];
reg [BW_PER_SRAM_GROUP_ADDR-1:0] res1_conv3_5_ans_b0 [0:5000-1], res1_conv3_5_ans_b1 [0:5000-1], res1_conv3_5_ans_b2 [0:5000-1], res1_conv3_5_ans_b3 [0:5000-1];

// res2_conv3_6
reg [WEIGHT_PER_ADDR*BW_PER_PARAM-1:0] res2_conv3_6_w [0:128-1];
reg [BIAS_PER_ADDR*BW_PER_PARAM-1:0] res2_conv3_6_b [0:4-1];
reg [BW_PER_SRAM_GROUP_ADDR-1:0] res2_conv3_6_ans_a0 [0:4608-1], res2_conv3_6_ans_a1 [0:4608-1], res2_conv3_6_ans_a2 [0:4608-1], res2_conv3_6_ans_a3 [0:4608-1];
// res2_conv3_6
reg [WEIGHT_PER_ADDR*BW_PER_PARAM-1:0] res2_conv3_7_w [0:128-1];
reg [BIAS_PER_ADDR*BW_PER_PARAM-1:0] res2_conv3_7_b [0:4-1];
reg [BW_PER_SRAM_GROUP_ADDR-1:0] res2_conv3_7_ans_b0 [0:4232-1], res2_conv3_7_ans_b1 [0:4232-1], res2_conv3_7_ans_b2 [0:4232-1], res2_conv3_7_ans_b3 [0:4232-1];

// conv3_pool_8
reg [WEIGHT_PER_ADDR*BW_PER_PARAM-1:0] conv3_pool_8_w [0:256-1];
reg [BIAS_PER_ADDR*BW_PER_PARAM-1:0] conv3_pool_8_b [0:8-1];
reg [BW_PER_SRAM_GROUP_ADDR-1:0] conv3_pool_8_ans_a0 [0:1936-1], conv3_pool_8_ans_a1 [0:1936-1], conv3_pool_8_ans_a2 [0:1936-1], conv3_pool_8_ans_a3 [0:1936-1];

// res3_conv3_9
reg [WEIGHT_PER_ADDR*BW_PER_PARAM-1:0] res3_conv3_9_w [0:512-1];
reg [BIAS_PER_ADDR*BW_PER_PARAM-1:0] res3_conv3_9_b [0:8-1];
reg [BW_PER_SRAM_GROUP_ADDR-1:0] res3_conv3_9_ans_b0 [0:1600-1], res3_conv3_9_ans_b1 [0:1600-1], res3_conv3_9_ans_b2 [0:1600-1], res3_conv3_9_ans_b3 [0:1600-1];
// res3_conv3_10
reg [WEIGHT_PER_ADDR*BW_PER_PARAM-1:0] res3_conv3_10_w [0:512-1];
reg [BIAS_PER_ADDR*BW_PER_PARAM-1:0] res3_conv3_10_b [0:8-1];
reg [BW_PER_SRAM_GROUP_ADDR-1:0] res3_conv3_10_ans_a0 [0:1296-1], res3_conv3_10_ans_a1 [0:1296-1], res3_conv3_10_ans_a2 [0:1296-1], res3_conv3_10_ans_a3 [0:1296-1];

// conv3_pool_11
reg [WEIGHT_PER_ADDR*BW_PER_PARAM-1:0] conv3_pool_11_w [0:512-1];
reg [BIAS_PER_ADDR*BW_PER_PARAM-1:0] conv3_pool_11_b [0:8-1];
reg [BW_PER_SRAM_GROUP_ADDR-1:0] conv3_pool_11_ans_b0 [0:256-1], conv3_pool_11_ans_b1 [0:256-1], conv3_pool_11_ans_b2 [0:256-1], conv3_pool_11_ans_b3 [0:256-1];

// gobal ave
reg [BW_PER_SRAM_GROUP_ADDR-1:0] global_ave_ans_a0 [0:64-1];

// fc 
reg [WEIGHT_PER_ADDR*BW_PER_PARAM-1:0] fc_w [0:48-1];
reg [BIAS_PER_ADDR*BW_PER_PARAM-1:0] fc_b;
reg [BW_PER_SRAM_GROUP_ADDR-1:0] fc_ans [0:2-1];


// ===== system reset ===== //
initial begin
    clk = 0;
    load_param;
    while(1) #(`CYCLE/2) clk = ~clk;
end

initial begin
	#(`CYCLE * `END_CYCLES);
    $display("\n========================================================");
    $display("   Error!!! Simulation time is too long...            ");
    $display("   There might be something wrong in your code.       ");
	$display("   If your design really needs such a long time,      ");
	$display("   increase the END_CYCLES setting in the testbench.  ");
    $display("========================================================");
    $finish;
end

// ===== cycle counter ===== //
integer cycle_cnt;
integer aver_cycle_cnt;
initial begin
    cycle_cnt = 0;
    aver_cycle_cnt = 0;
    while(1) begin 
        cycle_cnt = cycle_cnt + 1;
        @(negedge clk);
    end
end

// ===== input feeding ===== //
reg [BW_PER_ACT-1:0] mem_img [0:Pattern_N-1];

// ===== output comparision ===== //
// integer m;

integer ch;
integer row;
integer col;
integer count;

integer error_bank0, error_bank1,error_bank2, error_bank3;
integer error_total;
integer pat_idx;
integer total_err_pat;

initial begin
	// check if PAT_L and PAT_U are both valid
	if((`PAT_L < 0) || (`PAT_L > `NUM_PAT-1) || (`PAT_U < 0) || (`PAT_U > `NUM_PAT-1)) begin
		$display("XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX");
		$display("X                                                                             X");
		$display("X   Error!!! PAT_L and PAT_U should be within the range [0, %3d]              X", `NUM_PAT-1);
		$display("X                                                                             X");
		$display("XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX");
		$finish;
	end
	else if(`PAT_L > `PAT_U) begin
		$display("XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX");
		$display("X                                                        X");
		$display("X   Error!!! PAT_L should be smaller or equal to PAT_U   X");
		$display("X                                                        X");
		$display("XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX");
		$finish;		
	end

    // show simulation configuration
    if     (test_layer==INPUT)          $display("\n%c[1;36mStart checking INPUT layer ...         %c[0m\n", 27, 27);           // 27,27 ??
    else if(test_layer==CONV3_POOL_1)   $display("\n%c[1;36mStart checking CONV3_POOL_1 layer ...  %c[0m\n", 27, 27);
    else if(test_layer==CONV3_2)        $display("\n%c[1;36mStart checking CONV3_2 layer ...       %c[0m\n", 27, 27);
    else if(test_layer==CONV3_POOL_3)   $display("\n%c[1;36mStart checking CONV3_POOL_3 layer ...  %c[0m\n", 27, 27);
    else if(test_layer==RES1_CONV3_4)   $display("\n%c[1;36mStart checking RES1_CONV3_4 layer ...  %c[0m\n", 27, 27);
    else if(test_layer==RES1_CONV3_5)   $display("\n%c[1;36mStart checking RES1_CONV3_5 layer ...  %c[0m\n", 27, 27);
    else if(test_layer==RES2_CONV3_6)   $display("\n%c[1;36mStart checking RES2_CONV3_6 layer ...  %c[0m\n", 27, 27);
    else if(test_layer==RES2_CONV3_7)   $display("\n%c[1;36mStart checking RES2_CONV3_7 layer ...  %c[0m\n", 27, 27);
    else if(test_layer==CONV3_POOL_8)   $display("\n%c[1;36mStart checking CONV3_POOL_8 layer ...  %c[0m\n", 27, 27);
    else if(test_layer==RES3_CONV3_9)   $display("\n%c[1;36mStart checking RES3_CONV3_9 layer ...  %c[0m\n", 27, 27);
    else if(test_layer==RES3_CONV3_10)  $display("\n%c[1;36mStart checking RES3_CONV3_10 layer ... %c[0m\n", 27, 27);
    else if(test_layer==CONV3_POOL_11)  $display("\n%c[1;36mStart checking CONV3_POOL_11 layer ... %c[0m\n", 27, 27);
    else if(test_layer==GLOBAL_AVE)     $display("\n%c[1;36mStart checking GLOBAL_AVE layer ...    %c[0m\n", 27, 27);
    else if(test_layer==FC)             $display("\n%c[1;36mStart checking FC layer ...            %c[0m\n", 27, 27);
    else                                $display("\n%c[1;36mStart checking ?? layer ...            %c[0m\n", 27, 27);

    total_err_pat = 0;

    for(pat_idx=`PAT_L; pat_idx<=`PAT_U;pat_idx=pat_idx+1)begin
        sram_207936x48b_a0.reset_sram;
        sram_207936x48b_a1.reset_sram;
        sram_207936x48b_a2.reset_sram;
        sram_207936x48b_a3.reset_sram;

        sram_50176x48b_b0.reset_sram;
        sram_50176x48b_b1.reset_sram;
        sram_50176x48b_b2.reset_sram;
        sram_50176x48b_b3.reset_sram;
        load_golden(pat_idx);

        error_bank0 = 0;
        error_bank1 = 0;
        error_bank2 = 0;
        error_bank3 = 0;


        $display("\n================================================================");
        $display("======================== Pattern No. %02d ========================", pat_idx);
        $display("================================================================");

        // if(`FLAG_SHOWNUM) bmp2reg(pat_idx);    //load bmp into mem
        // if(`FLAG_SHOWNUM) $display("Input image: ");
        // if(`FLAG_SHOWNUM) display_reg;
        $display();

        srst_n = 1;
        enable = 0;
        @(negedge clk); srst_n = 1'b0;
        @(negedge clk); srst_n = 1'b1; enable = 1'b1;
        @(negedge clk); enable = 1'b0;
    
        wait(valid);
        @(negedge clk);
        case(test_layer)
            INPUT: begin
                // for(m=0; m<9577; m=m+1) begin
                //     if(input_ans_a0[m] === sram_207936x48b_a0.mem[m]) begin
                //         if(`FLAG_VERBOSE) $display("Sram #A0 address %0d PASS!", m);
                //     end else begin
                //         if(`FLAG_VERBOSE) $display("Sram #A0 address %0d FAIL!", m);
                //         if(`FLAG_VERBOSE) display_error(A0, INPUT, m, 0);
                //         error_bank0 = error_bank0 + 1;
                //     end
                // end

                count = 0;
                for(ch0=0; ch<3; ch=+1) begin
                    for (row=0; row<57; row=row+1) begin
                        for (col=0; col<57; col=col+1) begin
                            if(input_ans_a0[count] === sram_207936x48b_a0.mem[row*57+col+ch*57*57]) begin
                                if(`FLAG_VERBOSE) $display("Sram #A0 address %0d PASS!", row*57+col+ch*57*57);
                            end else begin
                                if(`FLAG_VERBOSE) $display("Sram #A0 address %0d FAIL!", row*57+col+ch*57*57);
                                if(`FLAG_VERBOSE) display_error(A0, INPUT, row*57+col+ch*57*57, row*57+col+ch*57*57-count);
                                error_bank0 = error_bank0 + 1;
                            end
                            count=count+1;
                        end
                    end
                end

                if(`FLAG_VERBOSE) $display("========================================================");
                if(error_bank0 == 0) begin
                    if(`FLAG_VERBOSE) $display("Input results in sram #A0 are successfully passed!");
                end else begin
                    $display("Input results in sram #A0 have %0d errors!", error_bank0);
                end
                if(`FLAG_VERBOSE) $display("========================================================\n");

                // for(m=0; m<9577; m=m+1) begin
                //     if(input_ans_a1[m] === sram_207936x48b_a1.mem[m]) begin
                //         if(`FLAG_VERBOSE) $display("Sram #A1 address %0d PASS!", m);
                //     end else begin
                //         if(`FLAG_VERBOSE) $display("Sram #A1 address %0d FAIL!", m);
                //         if(`FLAG_VERBOSE) display_error(A1, INPUT, m, 0);
                //         error_bank1 = error_bank1 + 1;
                //     end
                // end

                count = 0;
                for(ch0=0; ch<3; ch=+1) begin
                    for (row=0; row<57; row=row+1) begin
                        for (col=0; col<56; col=col+1) begin
                            if(input_ans_a1[count] === sram_207936x48b_a1.mem[row*57+col+ch*57*57]) begin
                                if(`FLAG_VERBOSE) $display("Sram #A1 address %0d PASS!", row*57+col+ch*57*57);
                            end else begin
                                if(`FLAG_VERBOSE) $display("Sram #A1 address %0d FAIL!", row*57+col+ch*57*57);
                                if(`FLAG_VERBOSE) display_error(A1, INPUT, row*57+col+ch*57*57, row*57+col+ch*57*57-count);
                                error_bank1 = error_bank1 + 1;
                            end
                            count=count+1;
                        end
                    end
                end
                
                if(`FLAG_VERBOSE) $display("========================================================");
                if(error_bank1 == 0) begin
                    if(`FLAG_VERBOSE) $display("Input results in sram #A1 are successfully passed!");
                end else begin
                    $display("Input results in sram #A1 have %0d errors!", error_bank1);
                end
                if(`FLAG_VERBOSE) $display("========================================================\n");

                for(m=0; m<9577; m=m+1) begin
                    if(input_ans_a2[m] === sram_207936x48b_a2.mem[m]) begin
                        if(`FLAG_VERBOSE) $display("Sram #A2 address %0d PASS!", m);
                    end else begin
                        if(`FLAG_VERBOSE) $display("Sram #A2 address %0d FAIL!", m);
                        if(`FLAG_VERBOSE) display_error(A2, INPUT, m, 0);
                        error_bank2 = error_bank2 + 1;
                    end
                end

                count = 0;
                for(ch0=0; ch<3; ch=+1) begin
                    for (row=0; row<56; row=row+1) begin
                        for (col=0; col<57; col=col+1) begin
                            if(input_ans_a2[count] === sram_207936x48b_a2.mem[row*57+col+ch*57*57]) begin
                                if(`FLAG_VERBOSE) $display("Sram #A2 address %0d PASS!", row*57+col+ch*57*57);
                            end else begin
                                if(`FLAG_VERBOSE) $display("Sram #A2 address %0d FAIL!", row*57+col+ch*57*57);
                                if(`FLAG_VERBOSE) display_error(A2, INPUT, row*57+col+ch*57*57, row*57+col+ch*57*57-count);
                                error_bank2 = error_bank2 + 1;
                            end
                            count=count+1;
                        end
                    end
                end
                
                if(`FLAG_VERBOSE) $display("========================================================");
                if(error_bank2 == 0) begin
                    if(`FLAG_VERBOSE) $display("Input results in sram #A2 are successfully passed!");
                end else begin
                    $display("Input results in sram #A2 have %0d errors!", error_bank2);
                end
                if(`FLAG_VERBOSE) $display("========================================================\n");

                // for(m=0; m<9577; m=m+1) begin
                //     if(input_ans_a3[m] === sram_207936x48b_a3.mem[m]) begin
                //         if(`FLAG_VERBOSE) $display("Sram #A3 address %0d PASS!", m);
                //     end else begin
                //         if(`FLAG_VERBOSE) $display("Sram #A3 address %0d FAIL!", m);
                //         if(`FLAG_VERBOSE) display_error(A3, INPUT, m, 0);
                //         error_bank3 = error_bank3 + 1;
                //     end
                // end

                count = 0;
                for(ch0=0; ch<3; ch=+1) begin
                    for (row=0; row<56; row=row+1) begin
                        for (col=0; col<56; col=col+1) begin
                            if(input_ans_30[count] === sram_207936x48b_a3.mem[row*57+col+ch*57*57]) begin
                                if(`FLAG_VERBOSE) $display("Sram #A3 address %0d PASS!", row*57+col+ch*57*57);
                            end else begin
                                if(`FLAG_VERBOSE) $display("Sram #A3 address %0d FAIL!", row*57+col+ch*57*57);
                                if(`FLAG_VERBOSE) display_error(A3, INPUT, row*57+col+ch*57*57, row*57+col+ch*57*57-count);
                                error_bank3 = error_bank3 + 1;
                            end
                            count=count+1;
                        end
                    end
                end
                
                if(`FLAG_VERBOSE) $display("========================================================");
                if(error_bank3 == 0) begin
                    if(`FLAG_VERBOSE) $display("Input results in sram #A3 are successfully passed!");
                end else begin
                    $display("Input results in sram #A3 have %0d errors!", error_bank3);
                end
                if(`FLAG_VERBOSE) $display("========================================================");

                error_total = error_bank0 + error_bank1 + error_bank2 + error_bank3; 
                
                // summary of this pattern
                if(`FLAG_VERBOSE) $display("\n========================================================");
                if(error_total == 0) begin
                    if(`FLAG_VERBOSE) $display("Congratulations! Your INPUT layer is correct!");
                    if(`FLAG_VERBOSE) $display("Pattern No. %02d is successfully passed !", i);
                    else              $write("%c[1;32mPASS! %c[0m",27, 27);
                end else begin
                    if(`FLAG_VERBOSE) $display("There are total %0d errors in your INPUT layer.", error_total);
                    if(`FLAG_VERBOSE) $display("Pattern No. %02d is failed...", pat_idx);
                    else              $write("%c[1;31mFAIL! %c[0m",27, 27);
                    total_err_pat = total_err_pat + 1;
                end
                if(`FLAG_VERBOSE) $display("========================================================");
                // $finish;
            end
            
            CONV3_POOL_1:begin
                // for(m=0; m<25088; m=m+1) begin
                //     if(conv3_pool_1_ans_b0[m] === sram_50176x48b_b0.mem[m]) begin
                //         if(`FLAG_VERBOSE) $display("Sram #B0 address %0d PASS!", m);
                //     end else begin
                //         if(`FLAG_VERBOSE) $display("Sram #B0 address %0d FAIL!", m);
                //         if(`FLAG_VERBOSE) display_error(B0, CONV3_POOL_1, m, 0);
                //         error_bank0 = error_bank0 + 1;
                //     end
                // end

                count = 0;
                for(ch0=0; ch<32; ch=+1) begin
                    for (row=0; row<28; row=row+1) begin
                        for (col=0; col<28; col=col+1) begin
                            if(input_ans_b0[count] === sram_50176x48b_b0.mem[row*57+col+ch*57*57]) begin
                                if(`FLAG_VERBOSE) $display("Sram #B0 address %0d PASS!", row*57+col+ch*57*57);
                            end else begin
                                if(`FLAG_VERBOSE) $display("Sram #B0 address %0d FAIL!", row*57+col+ch*57*57);
                                if(`FLAG_VERBOSE) display_error(B0, CONV3_POOL_1, row*57+col+ch*57*57, row*57+col+ch*57*57-count);
                                error_bank0 = error_bank0 + 1;
                            end
                            count=count+1;
                        end
                    end
                end
                
                if(`FLAG_VERBOSE) $display("========================================================");
                if(error_bank0 == 0) begin
                    if(`FLAG_VERBOSE) $display("CONV3_POOL_1 results in sram #B0 are successfully passed!");
                end else begin
                    $display("CONV3_POOL_1 results in sram #B0 have %0d errors!", error_bank0);
                end
                if(`FLAG_VERBOSE) $display("========================================================\n");

                // for(m=0; m<25088; m=m+1) begin
                //     if(conv3_pool_1_ans_b1[m] === sram_50176x48b_b1.mem[m]) begin
                //         if(`FLAG_VERBOSE) $display("Sram #B1 address %0d PASS!", m);
                //     end else begin
                //         if(`FLAG_VERBOSE) $display("Sram #B1 address %0d FAIL!", m);
                //         if(`FLAG_VERBOSE) display_error(B1, CONV3_POOL_1, m, 0);
                //         error_bank1 = error_bank1 + 1;
                //     end
                // end

                count = 0;
                for(ch0=0; ch<32; ch=+1) begin
                    for (row=0; row<28; row=row+1) begin
                        for (col=0; col<28; col=col+1) begin
                            if(input_ans_b1[count] === sram_50176x48b_b1.mem[row*57+col+ch*57*57]) begin
                                if(`FLAG_VERBOSE) $display("Sram #B1 address %0d PASS!", row*57+col+ch*57*57);
                            end else begin
                                if(`FLAG_VERBOSE) $display("Sram #B1 address %0d FAIL!", row*57+col+ch*57*57);
                                if(`FLAG_VERBOSE) display_error(B1, CONV3_POOL_1, row*57+col+ch*57*57, row*57+col+ch*57*57-count);
                                error_bank1 = error_bank1 + 1;
                            end
                            count=count+1;
                        end
                    end
                end
                
                if(`FLAG_VERBOSE) $display("========================================================");
                if(error_bank1 == 0) begin
                    if(`FLAG_VERBOSE) $display("CONV3_POOL_1 results in sram #B1 are successfully passed!");
                end else begin
                    $display("CONV3_POOL_1 results in sram #B1 have %0d errors!", error_bank1);
                end
                if(`FLAG_VERBOSE) $display("========================================================\n");

                // for(m=0; m<25088; m=m+1) begin
                //     if(conv3_pool_1_ans_b2[m] === sram_50176x48b_b2.mem[m]) begin
                //         if(`FLAG_VERBOSE) $display("Sram #B2 address %0d PASS!", m);
                //     end else begin
                //         if(`FLAG_VERBOSE) $display("Sram #B2 address %0d FAIL!", m);
                //         if(`FLAG_VERBOSE) display_error(B2, CONV3_POOL_1, m, 0);
                //         error_bank2 = error_bank2 + 1;
                //     end
                // end

                count = 0;
                for(ch0=0; ch<32; ch=+1) begin
                    for (row=0; row<28; row=row+1) begin
                        for (col=0; col<28; col=col+1) begin
                            if(input_ans_b2[count] === sram_50176x48b_b2.mem[row*57+col+ch*57*57]) begin
                                if(`FLAG_VERBOSE) $display("Sram #B2 address %0d PASS!", row*57+col+ch*57*57);
                            end else begin
                                if(`FLAG_VERBOSE) $display("Sram #B2 address %0d FAIL!", row*57+col+ch*57*57);
                                if(`FLAG_VERBOSE) display_error(B2, CONV3_POOL_1, row*57+col+ch*57*57, row*57+col+ch*57*57-count);
                                error_bank2 = error_bank2 + 1;
                            end
                            count=count+1;
                        end
                    end
                end
                
                if(`FLAG_VERBOSE) $display("========================================================");
                if(error_bank2 == 0) begin
                    if(`FLAG_VERBOSE) $display("CONV3_POOL_1 results in sram #B2 are successfully passed!");
                end else begin
                    $display("CONV3_POOL_1 results in sram #B2 have %0d errors!", error_bank2);
                end
                if(`FLAG_VERBOSE) $display("========================================================\n");

                // for(m=0; m<25088; m=m+1) begin
                //     if(conv3_pool_1_ans_b3[m] === sram_50176x48b_b3.mem[m]) begin
                //         if(`FLAG_VERBOSE) $display("Sram #B3 address %0d PASS!", m);
                //     end else begin
                //         if(`FLAG_VERBOSE) $display("Sram #B3 address %0d FAIL!", m);
                //         if(`FLAG_VERBOSE) display_error(B3, CONV3_POOL_1, m, 0);
                //         error_bank3 = error_bank3 + 1;
                //     end
                // end

                count = 0;
                for(ch0=0; ch<32; ch=+1) begin
                    for (row=0; row<28; row=row+1) begin
                        for (col=0; col<28; col=col+1) begin
                            if(input_ans_b3[count] === sram_50176x48b_b3.mem[row*57+col+ch*57*57]) begin
                                if(`FLAG_VERBOSE) $display("Sram #B3 address %0d PASS!", row*57+col+ch*57*57);
                            end else begin
                                if(`FLAG_VERBOSE) $display("Sram #B3 address %0d FAIL!", row*57+col+ch*57*57);
                                if(`FLAG_VERBOSE) display_error(B3, CONV3_POOL_1, row*57+col+ch*57*57, row*57+col+ch*57*57-count);
                                error_bank3 = error_bank3 + 1;
                            end
                            count=count+1;
                        end
                    end
                end


                if(`FLAG_VERBOSE) $display("========================================================");
                if(error_bank3 == 0) begin
                    if(`FLAG_VERBOSE) $display("CONV3_POOL_1 results in sram #B3 are successfully passed!");
                end else begin
                    $display("CONV3_POOL_1 results in sram #B3 have %0d errors!", error_bank3);
                end
                if(`FLAG_VERBOSE) $display("========================================================");
                error_total = error_bank0 + error_bank1 + error_bank2 + error_bank3; 

                // summary of this pattern    
                if(`FLAG_VERBOSE) $display("\n========================================================");
                if(error_total == 0) begin
                    if(`FLAG_VERBOSE) $display("Congratulations! Your CONV3_POOL_1 layer is correct!");
                    if(`FLAG_VERBOSE) $display("Pattern No. %02d is successfully passed !", pat_idx);
                    else              $write("%c[1;32mPASS! %c[0m",27, 27);
                end else begin
                    if(`FLAG_VERBOSE) $display("There are total %0d errors in your CONV3_POOL_1 layer.", error_total);
                    if(`FLAG_VERBOSE) $display("Pattern No. %02d is failed...", pat_idx);
                    else              $write("%c[1;31mFAIL! %c[0m",27, 27);
                    total_err_pat = total_err_pat + 1;
                end
                if(`FLAG_VERBOSE) $display("========================================================");
            end

            CONV3_2: begin
                // for(m=0; m<24200; m=m+1) begin
                //     if(conv3_2_ans_a0[m] === sram_207936x48b_a0.mem[m]) begin
                //         if(`FLAG_VERBOSE) $display("Sram #A0 address %0d PASS!", m);
                //     end else begin
                //         if(`FLAG_VERBOSE) $display("Sram #A0 address %0d FAIL!", m);
                //         if(`FLAG_VERBOSE) display_error(A0, CONV3_2, m, 0);
                //         error_bank0 = error_bank0 + 1;
                //     end
                // end

                count = 0;
                for(ch0=0; ch<32; ch=+1) begin
                    for (row=0; row<28; row=row+1) begin
                        for (col=0; col<28; col=col+1) begin
                            if(conv3_2_ans_a0[count] === sram_207936x48b_a0.mem[row*57+col+ch*57*57]) begin
                                if(`FLAG_VERBOSE) $display("Sram #A0 address %0d PASS!", row*57+col+ch*57*57);
                            end else begin
                                if(`FLAG_VERBOSE) $display("Sram #A0 address %0d FAIL!", row*57+col+ch*57*57);
                                if(`FLAG_VERBOSE) display_error(A0, CONV3_2, row*57+col+ch*57*57, row*57+col+ch*57*57-count);
                                error_bank0 = error_bank0 + 1;
                            end
                            count=count+1;
                        end
                    end
                end


                if(`FLAG_VERBOSE) $display("========================================================");
                if(error_bank0 == 0) begin
                    if(`FLAG_VERBOSE) $display("CONV3_2 results in sram #A0 are successfully passed!");
                end else begin
                    $display("CONV3_2 results in sram #A0 have %0d errors!", error_bank0);
                end
                if(`FLAG_VERBOSE) $display("========================================================\n");

                // for(m=0; m<24200; m=m+1) begin
                //     if(conv3_2_ans_a1[m] === sram_207936x48b_a1.mem[m]) begin
                //         if(`FLAG_VERBOSE) $display("Sram #A1 address %0d PASS!", m);
                //     end else begin
                //         if(`FLAG_VERBOSE) $display("Sram #A1 address %0d FAIL!", m);
                //         if(`FLAG_VERBOSE) display_error(A1, CONV3_2, m, 0);
                //         error_bank1 = error_bank1 + 1;
                //     end
                // end

                count = 0;
                for(ch0=0; ch<32; ch=+1) begin
                    for (row=0; row<28; row=row+1) begin
                        for (col=0; col<27; col=col+1) begin
                            if(conv3_2_ans_a1[count] === sram_207936x48b_a1.mem[row*57+col+ch*57*57]) begin
                                if(`FLAG_VERBOSE) $display("Sram #A1 address %0d PASS!", row*57+col+ch*57*57);
                            end else begin
                                if(`FLAG_VERBOSE) $display("Sram #A1 address %0d FAIL!", row*57+col+ch*57*57);
                                if(`FLAG_VERBOSE) display_error(A1, CONV3_2, row*57+col+ch*57*57, row*57+col+ch*57*57-count);
                                error_bank1 = error_bank1 + 1;
                            end
                            count=count+1;
                        end
                    end
                end



                if(`FLAG_VERBOSE) $display("========================================================");
                if(error_bank1 == 0) begin
                    if(`FLAG_VERBOSE) $display("CONV3_2 results in sram #A1 are successfully passed!");
                end else begin
                    $display("CONV3_2 results in sram #A1 have %0d errors!", error_bank1);
                end
                if(`FLAG_VERBOSE) $display("========================================================\n");

                // for(m=0; m<24200; m=m+1) begin
                //     if(conv3_2_ans_a2[m] === sram_207936x48b_a2.mem[m]) begin
                //         if(`FLAG_VERBOSE) $display("Sram #A2 address %0d PASS!", m);
                //     end else begin
                //         if(`FLAG_VERBOSE) $display("Sram #A2 address %0d FAIL!", m);
                //         if(`FLAG_VERBOSE) display_error(A2, CONV3_2, m, 0);
                //         error_bank2 = error_bank2 + 1;
                //     end
                // end

                count = 0;
                for(ch0=0; ch<32; ch=+1) begin
                    for (row=0; row<27; row=row+1) begin
                        for (col=0; col<28; col=col+1) begin
                            if(conv3_2_ans_a2[count] === sram_207936x48b_a2.mem[row*57+col+ch*57*57]) begin
                                if(`FLAG_VERBOSE) $display("Sram #A2 address %0d PASS!", row*57+col+ch*57*57);
                            end else begin
                                if(`FLAG_VERBOSE) $display("Sram #A2 address %0d FAIL!", row*57+col+ch*57*57);
                                if(`FLAG_VERBOSE) display_error(A2, CONV3_2, row*57+col+ch*57*57, row*57+col+ch*57*57-count);
                                error_bank2 = error_bank2 + 1;
                            end
                            count=count+1;
                        end
                    end
                end


                if(`FLAG_VERBOSE) $display("========================================================");
                if(error_bank2 == 0) begin
                    if(`FLAG_VERBOSE) $display("CONV3_2 results in sram #A2 are successfully passed!");
                end else begin
                    $display("CONV3_2 results in sram #A2 have %0d errors!", error_bank2);
                end
                if(`FLAG_VERBOSE) $display("========================================================\n");

                // for(m=0; m<24200; m=m+1) begin
                //     if(conv3_2_ans_a3[m] === sram_207936x48b_a3.mem[m]) begin
                //         if(`FLAG_VERBOSE) $display("Sram #A3 address %0d PASS!", m);
                //     end else begin
                //         if(`FLAG_VERBOSE) $display("Sram #A3 address %0d FAIL!", m);
                //         if(`FLAG_VERBOSE) display_error(A3, CONV3_2, m, 0);
                //         error_bank3 = error_bank3 + 1;
                //     end
                // end

                count = 0;
                for(ch0=0; ch<32; ch=+1) begin
                    for (row=0; row<27; row=row+1) begin
                        for (col=0; col<27; col=col+1) begin
                            if(conv3_2_ans_a3[count] === sram_207936x48b_a3.mem[row*57+col+ch*57*57]) begin
                                if(`FLAG_VERBOSE) $display("Sram #A3 address %0d PASS!", row*57+col+ch*57*57);
                            end else begin
                                if(`FLAG_VERBOSE) $display("Sram #A3 address %0d FAIL!", row*57+col+ch*57*57);
                                if(`FLAG_VERBOSE) display_error(A3, CONV3_2, row*57+col+ch*57*57, row*57+col+ch*57*57-count);
                                error_bank3 = error_bank3 + 1;
                            end
                            count=count+1;
                        end
                    end
                end


                if(`FLAG_VERBOSE) $display("========================================================");
                if(error_bank3 == 0) begin
                    if(`FLAG_VERBOSE) $display("CONV3_2 results in sram #A3 are successfully passed!");
                end else begin
                    $display("CONV3_2 results in sram #A3 have %0d errors!", error_bank3);
                end
                if(`FLAG_VERBOSE) $display("========================================================");
                error_total = error_bank0 + error_bank1 + error_bank2 + error_bank3; 

                // summary of this pattern    
                if(`FLAG_VERBOSE) $display("\n========================================================");
                if(error_total == 0) begin
                    if(`FLAG_VERBOSE) $display("Congratulations! Your CONV3_2 layer is correct!");
                    if(`FLAG_VERBOSE) $display("Pattern No. %02d is successfully passed !", pat_idx);
                    else              $write("%c[1;32mPASS! %c[0m",27, 27);
                end else begin
                    if(`FLAG_VERBOSE) $display("There are total %0d errors in your CONV3_2 layer.", error_total);
                    if(`FLAG_VERBOSE) $display("Pattern No. %02d is failed...", pat_idx);
                    else              $write("%c[1;31mFAIL! %c[0m",27, 27);
                    total_err_pat = total_err_pat + 1;
                end
                if(`FLAG_VERBOSE) $display("========================================================");
            end

            CONV3_POOL_3: begin
                // for(m=0; m<5832; m=m+1) begin
                //     if(conv3_pool_3_ans_b0[m] === sram_50176x48b_b0.mem[m]) begin
                //         if(`FLAG_VERBOSE) $display("Sram #B0 address %0d PASS!", m);
                //     end else begin
                //         if(`FLAG_VERBOSE) $display("Sram #B0 address %0d FAIL!", m);
                //         if(`FLAG_VERBOSE) display_error(B0, CONV3_POOL_3, m, 0);
                //         error_bank0 = error_bank0 + 1;
                //     end
                // end

                count = 0;
                for(ch0=0; ch<32; ch=+1) begin
                    for (row=0; row<14; row=row+1) begin
                        for (col=0; col<14; col=col+1) begin
                            if(conv3_pool_3_ans_b0[count] === sram_50176x48b_b0.mem[row*57+col+ch*57*57]) begin
                                if(`FLAG_VERBOSE) $display("Sram #B0 address %0d PASS!", row*57+col+ch*57*57);
                            end else begin
                                if(`FLAG_VERBOSE) $display("Sram #B0 address %0d FAIL!", row*57+col+ch*57*57);
                                if(`FLAG_VERBOSE) display_error(B0, CONV3_POOL_3, row*57+col+ch*57*57, row*57+col+ch*57*57-count);
                                error_bank0 = error_bank0 + 1;
                            end
                            count=count+1;
                        end
                    end
                end


                if(`FLAG_VERBOSE) $display("========================================================");
                if(error_bank0 == 0) begin
                    if(`FLAG_VERBOSE) $display("CONV3_POOL_3 results in sram #B0 are successfully passed!");
                end else begin
                    $display("CONV3_POOL_3 results in sram #B0 have %0d errors!", error_bank0);
                end
                if(`FLAG_VERBOSE) $display("========================================================\n");

                // for(m=0; m<5832; m=m+1) begin
                //     if(conv3_pool_3_ans_b1[m] === sram_50176x48b_b1.mem[m]) begin
                //         if(`FLAG_VERBOSE) $display("Sram #B1 address %0d PASS!", m);
                //     end else begin
                //         if(`FLAG_VERBOSE) $display("Sram #B1 address %0d FAIL!", m);
                //         if(`FLAG_VERBOSE) display_error(B1, CONV3_POOL_3, m, 0);
                //         error_bank1 = error_bank1 + 1;
                //     end
                // end

                count = 0;
                for(ch0=0; ch<32; ch=+1) begin
                    for (row=0; row<14; row=row+1) begin
                        for (col=0; col<13; col=col+1) begin
                            if(conv3_pool_3_ans_b1[count] === sram_50176x48b_b1.mem[row*57+col+ch*57*57]) begin
                                if(`FLAG_VERBOSE) $display("Sram #B1 address %0d PASS!", row*57+col+ch*57*57);
                            end else begin
                                if(`FLAG_VERBOSE) $display("Sram #B1 address %0d FAIL!", row*57+col+ch*57*57);
                                if(`FLAG_VERBOSE) display_error(B1, CONV3_POOL_3, row*57+col+ch*57*57, row*57+col+ch*57*57-count);
                                error_bank1 = error_bank1 + 1;
                            end
                            count=count+1;
                        end
                    end
                end


                if(`FLAG_VERBOSE) $display("========================================================");
                if(error_bank1 == 0) begin
                    if(`FLAG_VERBOSE) $display("CONV3_POOL_3 results in sram #B1 are successfully passed!");
                end else begin
                    $display("CONV3_POOL_3 results in sram #B1 have %0d errors!", error_bank1);
                end
                if(`FLAG_VERBOSE) $display("========================================================\n");

                // for(m=0; m<5832; m=m+1) begin
                //     if(conv3_pool_3_ans_b2[m] === sram_50176x48b_b2.mem[m]) begin
                //         if(`FLAG_VERBOSE) $display("Sram #B2 address %0d PASS!", m);
                //     end else begin
                //         if(`FLAG_VERBOSE) $display("Sram #B2 address %0d FAIL!", m);
                //         if(`FLAG_VERBOSE) display_error(B2, CONV3_POOL_3, m, 0);
                //         error_bank2 = error_bank2 + 1;
                //     end
                // end

                count = 0;
                for(ch0=0; ch<32; ch=+1) begin
                    for (row=0; row<13; row=row+1) begin
                        for (col=0; col<14; col=col+1) begin
                            if(conv3_pool_3_ans_b2[count] === sram_50176x48b_b2.mem[row*57+col+ch*57*57]) begin
                                if(`FLAG_VERBOSE) $display("Sram #B2 address %0d PASS!", row*57+col+ch*57*57);
                            end else begin
                                if(`FLAG_VERBOSE) $display("Sram #B2 address %0d FAIL!", row*57+col+ch*57*57);
                                if(`FLAG_VERBOSE) display_error(B2, CONV3_POOL_3, row*57+col+ch*57*57, row*57+col+ch*57*57-count);
                                error_bank2 = error_bank2 + 1;
                            end
                            count=count+1;
                        end
                    end
                end


                if(`FLAG_VERBOSE) $display("========================================================");
                if(error_bank2 == 0) begin
                    if(`FLAG_VERBOSE) $display("CONV3_POOL_3 results in sram #B2 are successfully passed!");
                end else begin
                    $display("CONV3_POOL_3 results in sram #B2 have %0d errors!", error_bank2);
                end
                if(`FLAG_VERBOSE) $display("========================================================\n");

                // for(m=0; m<5832; m=m+1) begin
                //     if(conv3_pool_3_ans_b3[m] === sram_50176x48b_b3.mem[m]) begin
                //         if(`FLAG_VERBOSE) $display("Sram #B3 address %0d PASS!", m);
                //     end else begin
                //         if(`FLAG_VERBOSE) $display("Sram #B3 address %0d FAIL!", m);
                //         if(`FLAG_VERBOSE) display_error(B3, CONV3_POOL_3, m, 0);
                //         error_bank3 = error_bank3 + 1;
                //     end
                // end

                count = 0;
                for(ch0=0; ch<32; ch=+1) begin
                    for (row=0; row<13; row=row+1) begin
                        for (col=0; col<13; col=col+1) begin
                            if(conv3_pool_3_ans_b3[count] === sram_50176x48b_b3.mem[row*57+col+ch*57*57]) begin
                                if(`FLAG_VERBOSE) $display("Sram #B3 address %0d PASS!", row*57+col+ch*57*57);
                            end else begin
                                if(`FLAG_VERBOSE) $display("Sram #B3 address %0d FAIL!", row*57+col+ch*57*57);
                                if(`FLAG_VERBOSE) display_error(B3, CONV3_POOL_3, row*57+col+ch*57*57, row*57+col+ch*57*57-count);
                                error_bank3 = error_bank3 + 1;
                            end
                            count=count+1;
                        end
                    end
                end


                if(`FLAG_VERBOSE) $display("========================================================");
                if(error_bank3 == 0) begin
                    if(`FLAG_VERBOSE) $display("CONV3_POOL_3 results in sram #B3 are successfully passed!");
                end else begin
                    $display("CONV3_POOL_3 results in sram #B3 have %0d errors!", error_bank3);
                end
                if(`FLAG_VERBOSE) $display("========================================================");
                error_total = error_bank0 + error_bank1 + error_bank2 + error_bank3; 

                // summary of this pattern    
                if(`FLAG_VERBOSE) $display("\n========================================================");
                if(error_total == 0) begin
                    if(`FLAG_VERBOSE) $display("Congratulations! Your CONV3_POOL_3 layer is correct!");
                    if(`FLAG_VERBOSE) $display("Pattern No. %02d is successfully passed !", pat_idx);
                    else              $write("%c[1;32mPASS! %c[0m",27, 27);
                end else begin
                    if(`FLAG_VERBOSE) $display("There are total %0d errors in your CONV3_POOL_3 layer.", error_total);
                    if(`FLAG_VERBOSE) $display("Pattern No. %02d is failed...", pat_idx);
                    else              $write("%c[1;31mFAIL! %c[0m",27, 27);
                    total_err_pat = total_err_pat + 1;
                end
                if(`FLAG_VERBOSE) $display("========================================================");
            end

            RES1_CONV3_4: begin
                // for(m=0; m<5408; m=m+1) begin
                //     if(res1_conv3_4_ans_a0[m] === sram_207936x48b_a0.mem[m]) begin
                //         if(`FLAG_VERBOSE) $display("Sram #A0 address %0d PASS!", m);
                //     end else begin
                //         if(`FLAG_VERBOSE) $display("Sram #A0 address %0d FAIL!", m);
                //         if(`FLAG_VERBOSE) display_error(A0, RES1_CONV3_4, m, 0);
                //         error_bank0 = error_bank0 + 1;
                //     end
                // end

                count = 0;
                for(ch0=0; ch<32; ch=+1) begin
                    for (row=0; row<13; row=row+1) begin
                        for (col=0; col<13; col=col+1) begin
                            if(res1_conv3_4_ans_a0[count] === sram_207936x48b_a0.mem[row*57+col+ch*57*57]) begin
                                if(`FLAG_VERBOSE) $display("Sram #A0 address %0d PASS!", row*57+col+ch*57*57);
                            end else begin
                                if(`FLAG_VERBOSE) $display("Sram #A0 address %0d FAIL!", row*57+col+ch*57*57);
                                if(`FLAG_VERBOSE) display_error(A0, RES1_CONV3_4, row*57+col+ch*57*57, row*57+col+ch*57*57-count);
                                error_bank0 = error_bank0 + 1;
                            end
                            count=count+1;
                        end
                    end
                end

                if(`FLAG_VERBOSE) $display("========================================================");
                if(error_bank0 == 0) begin
                    if(`FLAG_VERBOSE) $display("RES1_CONV3_4 results in sram #A0 are successfully passed!");
                end else begin
                    $display("RES1_CONV3_4 results in sram #A0 have %0d errors!", error_bank0);
                end
                if(`FLAG_VERBOSE) $display("========================================================\n");

                // for(m=0; m<5408; m=m+1) begin
                //     if(res1_conv3_4_ans_a1[m] === sram_207936x48b_a1.mem[m]) begin
                //         if(`FLAG_VERBOSE) $display("Sram #A1 address %0d PASS!", m);
                //     end else begin
                //         if(`FLAG_VERBOSE) $display("Sram #A1 address %0d FAIL!", m);
                //         if(`FLAG_VERBOSE) display_error(A1, RES1_CONV3_4, m, 0);
                //         error_bank1 = error_bank1 + 1;
                //     end
                // end

                count = 0;
                for(ch0=0; ch<32; ch=+1) begin
                    for (row=0; row<13; row=row+1) begin
                        for (col=0; col<13; col=col+1) begin
                            if(res1_conv3_4_ans_a1[count] === sram_207936x48b_a1.mem[row*57+col+ch*57*57]) begin
                                if(`FLAG_VERBOSE) $display("Sram #A1 address %0d PASS!", row*57+col+ch*57*57);
                            end else begin
                                if(`FLAG_VERBOSE) $display("Sram #A1 address %0d FAIL!", row*57+col+ch*57*57);
                                if(`FLAG_VERBOSE) display_error(A1, RES1_CONV3_4, row*57+col+ch*57*57, row*57+col+ch*57*57-count);
                                error_bank1 = error_bank1 + 1;
                            end
                            count=count+1;
                        end
                    end
                end


                if(`FLAG_VERBOSE) $display("========================================================");
                if(error_bank1 == 0) begin
                    if(`FLAG_VERBOSE) $display("RES1_CONV3_4 results in sram #A1 are successfully passed!");
                end else begin
                    $display("RES1_CONV3_4 results in sram #A1 have %0d errors!", error_bank1);
                end
                if(`FLAG_VERBOSE) $display("========================================================\n");

                // for(m=0; m<5408; m=m+1) begin
                //     if(res1_conv3_4_ans_a2[m] === sram_207936x48b_a2.mem[m]) begin
                //         if(`FLAG_VERBOSE) $display("Sram #A2 address %0d PASS!", m);
                //     end else begin
                //         if(`FLAG_VERBOSE) $display("Sram #A2 address %0d FAIL!", m);
                //         if(`FLAG_VERBOSE) display_error(A2, RES1_CONV3_4, m, 0);
                //         error_bank2 = error_bank2 + 1;
                //     end
                // end

                count = 0;
                for(ch0=0; ch<32; ch=+1) begin
                    for (row=0; row<13; row=row+1) begin
                        for (col=0; col<13; col=col+1) begin
                            if(res1_conv3_4_ans_a2[count] === sram_207936x48b_a2.mem[row*57+col+ch*57*57]) begin
                                if(`FLAG_VERBOSE) $display("Sram #A2 address %0d PASS!", row*57+col+ch*57*57);
                            end else begin
                                if(`FLAG_VERBOSE) $display("Sram #A2 address %0d FAIL!", row*57+col+ch*57*57);
                                if(`FLAG_VERBOSE) display_error(A2, RES1_CONV3_4, row*57+col+ch*57*57, row*57+col+ch*57*57-count);
                                error_bank2 = error_bank2 + 1;
                            end
                            count=count+1;
                        end
                    end
                end


                if(`FLAG_VERBOSE) $display("========================================================");
                if(error_bank2 == 0) begin
                    if(`FLAG_VERBOSE) $display("RES1_CONV3_4 results in sram #A2 are successfully passed!");
                end else begin
                    $display("RES1_CONV3_4 results in sram #A2 have %0d errors!", error_bank2);
                end
                if(`FLAG_VERBOSE) $display("========================================================\n");

                // for(m=0; m<5408; m=m+1) begin
                //     if(res1_conv3_4_ans_a3[m] === sram_207936x48b_a3.mem[m]) begin
                //         if(`FLAG_VERBOSE) $display("Sram #A3 address %0d PASS!", m);
                //     end else begin
                //         if(`FLAG_VERBOSE) $display("Sram #A3 address %0d FAIL!", m);
                //         if(`FLAG_VERBOSE) display_error(A3, RES1_CONV3_4, m, 0);
                //         error_bank3 = error_bank3 + 1;
                //     end
                // end

                count = 0;
                for(ch0=0; ch<32; ch=+1) begin
                    for (row=0; row<13; row=row+1) begin
                        for (col=0; col<13; col=col+1) begin
                            if(res1_conv3_4_ans_a3[count] === sram_207936x48b_a3.mem[row*57+col+ch*57*57]) begin
                                if(`FLAG_VERBOSE) $display("Sram #A3 address %0d PASS!", row*57+col+ch*57*57);
                            end else begin
                                if(`FLAG_VERBOSE) $display("Sram #A3 address %0d FAIL!", row*57+col+ch*57*57);
                                if(`FLAG_VERBOSE) display_error(A3, RES1_CONV3_4, row*57+col+ch*57*57, row*57+col+ch*57*57-count);
                                error_bank3 = error_bank3 + 1;
                            end
                            count=count+1;
                        end
                    end
                end


                if(`FLAG_VERBOSE) $display("========================================================");
                if(error_bank3 == 0) begin
                    if(`FLAG_VERBOSE) $display("RES1_CONV3_4 results in sram #A3 are successfully passed!");
                end else begin
                    $display("RES1_CONV3_4 results in sram #A3 have %0d errors!", error_bank3);
                end
                if(`FLAG_VERBOSE) $display("========================================================");
                error_total = error_bank0 + error_bank1 + error_bank2 + error_bank3; 

                // summary of this pattern    
                if(`FLAG_VERBOSE) $display("\n========================================================");
                if(error_total == 0) begin
                    if(`FLAG_VERBOSE) $display("Congratulations! Your RES1_CONV3_4 layer is correct!");
                    if(`FLAG_VERBOSE) $display("Pattern No. %02d is successfully passed !", pat_idx);
                    else              $write("%c[1;32mPASS! %c[0m",27, 27);
                end else begin
                    if(`FLAG_VERBOSE) $display("There are total %0d errors in your RES1_CONV3_4 layer.", error_total);
                    if(`FLAG_VERBOSE) $display("Pattern No. %02d is failed...", pat_idx);
                    else              $write("%c[1;31mFAIL! %c[0m",27, 27);
                    total_err_pat = total_err_pat + 1;
                end
                if(`FLAG_VERBOSE) $display("========================================================");
            end

            RES1_CONV3_5: begin
                // for(m=0; m<5000; m=m+1) begin
                //     if(res1_conv3_5_ans_b0[m] === sram_50176x48b_b0.mem[m]) begin
                //         if(`FLAG_VERBOSE) $display("Sram #B0 address %0d PASS!", m);
                //     end else begin
                //         if(`FLAG_VERBOSE) $display("Sram #B0 address %0d FAIL!", m);
                //         if(`FLAG_VERBOSE) display_error(B0, RES1_CONV3_5, m, 0);
                //         error_bank0 = error_bank0 + 1;
                //     end
                // end

                count = 0;
                for(ch0=0; ch<32; ch=ch+1) begin
                    for (row=0; row<13; row=row+1) begin
                        for (col=0; col<13; col=col+1) begin
                            if(res1_conv3_5_ans_b0[count] === sram_50176x48b_b0.mem[row*57+col+ch*57*57]) begin
                                if(`FLAG_VERBOSE) $display("Sram #B0 address %0d PASS!", row*57+col+ch*57*57);
                            end else begin
                                if(`FLAG_VERBOSE) $display("Sram #B0 address %0d FAIL!", row*57+col+ch*57*57);
                                if(`FLAG_VERBOSE) display_error(B0, RES1_CONV3_5, row*57+col+ch*57*57, row*57+col+ch*57*57-count);
                                error_bank0 = error_bank0 + 1;
                            end
                            count=count+1;
                        end
                    end
                end


                if(`FLAG_VERBOSE) $display("========================================================");
                if(error_bank0 == 0) begin
                    if(`FLAG_VERBOSE) $display("RES1_CONV3_5 results in sram #B0 are successfully passed!");
                end else begin
                    $display("RES1_CONV3_5 results in sram #B0 have %0d errors!", error_bank0);
                end
                if(`FLAG_VERBOSE) $display("========================================================\n");

                // for(m=0; m<5000; m=m+1) begin
                //     if(res1_conv3_5_ans_b1[m] === sram_50176x48b_b1.mem[m]) begin
                //         if(`FLAG_VERBOSE) $display("Sram #B1 address %0d PASS!", m);
                //     end else begin
                //         if(`FLAG_VERBOSE) $display("Sram #B1 address %0d FAIL!", m);
                //         if(`FLAG_VERBOSE) display_error(B1, RES1_CONV3_5, m, 0);
                //         error_bank1 = error_bank1 + 1;
                //     end
                // end

                count = 0;
                for(ch0=0; ch<32; ch=ch+1) begin
                    for (row=0; row<13; row=row+1) begin
                        for (col=0; col<12; col=col+1) begin
                            if(res1_conv3_5_ans_b1[count] === sram_50176x48b_b1.mem[row*57+col+ch*57*57]) begin
                                if(`FLAG_VERBOSE) $display("Sram #B1 address %0d PASS!", row*57+col+ch*57*57);
                            end else begin
                                if(`FLAG_VERBOSE) $display("Sram #B1 address %0d FAIL!", row*57+col+ch*57*57);
                                if(`FLAG_VERBOSE) display_error(B1, RES1_CONV3_5, row*57+col+ch*57*57, row*57+col+ch*57*57-count);
                                error_bank1 = error_bank1 + 1;
                            end
                            count=count+1;
                        end
                    end
                end


                if(`FLAG_VERBOSE) $display("========================================================");
                if(error_bank1 == 0) begin
                    if(`FLAG_VERBOSE) $display("RES1_CONV3_5 results in sram #B1 are successfully passed!");
                end else begin
                    $display("RES1_CONV3_5 results in sram #B1 have %0d errors!", error_bank1);
                end
                if(`FLAG_VERBOSE) $display("========================================================\n");

                // for(m=0; m<5000; m=m+1) begin
                //     if(res1_conv3_5_ans_b2[m] === sram_50176x48b_b2.mem[m]) begin
                //         if(`FLAG_VERBOSE) $display("Sram #B2 address %0d PASS!", m);
                //     end else begin
                //         if(`FLAG_VERBOSE) $display("Sram #B2 address %0d FAIL!", m);
                //         if(`FLAG_VERBOSE) display_error(B2, RES1_CONV3_5, m, 0);
                //         error_bank2 = error_bank2 + 1;
                //     end
                // end

                count = 0;
                for(ch0=0; ch<32; ch=ch+1) begin
                    for (row=0; row<12; row=row+1) begin
                        for (col=0; col<13; col=col+1) begin
                            if(res1_conv3_5_ans_b2[count] === sram_50176x48b_b2.mem[row*57+col+ch*57*57]) begin
                                if(`FLAG_VERBOSE) $display("Sram #B2 address %0d PASS!", row*57+col+ch*57*57);
                            end else begin
                                if(`FLAG_VERBOSE) $display("Sram #B2 address %0d FAIL!", row*57+col+ch*57*57);
                                if(`FLAG_VERBOSE) display_error(B2, RES1_CONV3_5, row*57+col+ch*57*57, row*57+col+ch*57*57-count);
                                error_bank2 = error_bank2 + 1;
                            end
                            count=count+1;
                        end
                    end
                end


                if(`FLAG_VERBOSE) $display("========================================================");
                if(error_bank2 == 0) begin
                    if(`FLAG_VERBOSE) $display("RES1_CONV3_5 results in sram #B2 are successfully passed!");
                end else begin
                    $display("RES1_CONV3_5 results in sram #B2 have %0d errors!", error_bank2);
                end
                if(`FLAG_VERBOSE) $display("========================================================\n");

                // for(m=0; m<5000; m=m+1) begin
                //     if(res1_conv3_5_ans_b3[m] === sram_50176x48b_b3.mem[m]) begin
                //         if(`FLAG_VERBOSE) $display("Sram #B3 address %0d PASS!", m);
                //     end else begin
                //         if(`FLAG_VERBOSE) $display("Sram #B3 address %0d FAIL!", m);
                //         if(`FLAG_VERBOSE) display_error(B3, RES1_CONV3_5, m, 0);
                //         error_bank3 = error_bank3 + 1;
                //     end
                // end

                count = 0;
                for(ch0=0; ch<32; ch=ch+1) begin
                    for (row=0; row<12; row=row+1) begin
                        for (col=0; col<12; col=col+1) begin
                            if(res1_conv3_5_ans_b3[count] === sram_50176x48b_b3.mem[row*57+col+ch*57*57]) begin
                                if(`FLAG_VERBOSE) $display("Sram #B3 address %0d PASS!", row*57+col+ch*57*57);
                            end else begin
                                if(`FLAG_VERBOSE) $display("Sram #B3 address %0d FAIL!", row*57+col+ch*57*57);
                                if(`FLAG_VERBOSE) display_error(B3, RES1_CONV3_5, row*57+col+ch*57*57, row*57+col+ch*57*57-count);
                                error_bank3 = error_bank3 + 1;
                            end
                            count=count+1;
                        end
                    end
                end


                if(`FLAG_VERBOSE) $display("========================================================");
                if(error_bank3 == 0) begin
                    if(`FLAG_VERBOSE) $display("RES1_CONV3_5 results in sram #B3 are successfully passed!");
                end else begin
                    $display("RES1_CONV3_5 results in sram #B3 have %0d errors!", error_bank3);
                end
                if(`FLAG_VERBOSE) $display("========================================================");
                error_total = error_bank0 + error_bank1 + error_bank2 + error_bank3; 

                // summary of this pattern    
                if(`FLAG_VERBOSE) $display("\n========================================================");
                if(error_total == 0) begin
                    if(`FLAG_VERBOSE) $display("Congratulations! Your RES1_CONV3_5 layer is correct!");
                    if(`FLAG_VERBOSE) $display("Pattern No. %02d is successfully passed !", pat_idx);
                    else              $write("%c[1;32mPASS! %c[0m",27, 27);
                end else begin
                    if(`FLAG_VERBOSE) $display("There are total %0d errors in your RES1_CONV3_5 layer.", error_total);
                    if(`FLAG_VERBOSE) $display("Pattern No. %02d is failed...", pat_idx);
                    else              $write("%c[1;31mFAIL! %c[0m",27, 27);
                    total_err_pat = total_err_pat + 1;
                end
                if(`FLAG_VERBOSE) $display("========================================================");
            end

            RES2_CONV3_6: begin
                // for(m=0; m<4608; m=m+1) begin
                //     if(res2_conv3_6_ans_a0[m] === sram_207936x48b_a0.mem[m]) begin
                //         if(`FLAG_VERBOSE) $display("Sram #A0 address %0d PASS!", m);
                //     end else begin
                //         if(`FLAG_VERBOSE) $display("Sram #A0 address %0d FAIL!", m);
                //         if(`FLAG_VERBOSE) display_error(A0, RES2_CONV3_6, m, 0);
                //         error_bank0 = error_bank0 + 1;
                //     end
                // end

                count = 0;
                for(ch0=0; ch<32; ch=ch+1) begin
                    for (row=0; row<12; row=row+1) begin
                        for (col=0; col<12; col=col+1) begin
                            if(res2_conv3_6_ans_a0[count] === sram_207936x48b_a0.mem[row*57+col+ch*57*57]) begin
                                if(`FLAG_VERBOSE) $display("Sram #A0 address %0d PASS!", row*57+col+ch*57*57);
                            end else begin
                                if(`FLAG_VERBOSE) $display("Sram #A0 address %0d FAIL!", row*57+col+ch*57*57);
                                if(`FLAG_VERBOSE) display_error(A0, RES2_CONV3_6, row*57+col+ch*57*57, row*57+col+ch*57*57-count);
                                error_bank0 = error_bank0 + 1;
                            end
                            count=count+1;
                        end
                    end
                end

                if(`FLAG_VERBOSE) $display("========================================================");
                if(error_bank0 == 0) begin
                    if(`FLAG_VERBOSE) $display("RES2_CONV3_6 results in sram #A0 are successfully passed!");
                end else begin
                    $display("RES2_CONV3_6 results in sram #A0 have %0d errors!", error_bank0);
                end
                if(`FLAG_VERBOSE) $display("========================================================\n");

                // for(m=0; m<4608; m=m+1) begin
                //     if(res2_conv3_6_ans_a1[m] === sram_207936x48b_a1.mem[m]) begin
                //         if(`FLAG_VERBOSE) $display("Sram #A1 address %0d PASS!", m);
                //     end else begin
                //         if(`FLAG_VERBOSE) $display("Sram #A1 address %0d FAIL!", m);
                //         if(`FLAG_VERBOSE) display_error(A1, RES2_CONV3_6, m, 0);
                //         error_bank1 = error_bank1 + 1;
                //     end
                // end

                count = 0;
                for(ch0=0; ch<32; ch=ch+1) begin
                    for (row=0; row<12; row=row+1) begin
                        for (col=0; col<12; col=col+1) begin
                            if(res2_conv3_6_ans_a1[count] === sram_207936x48b_a1.mem[row*57+col+ch*57*57]) begin
                                if(`FLAG_VERBOSE) $display("Sram #A1 address %0d PASS!", row*57+col+ch*57*57);
                            end else begin
                                if(`FLAG_VERBOSE) $display("Sram #A1 address %0d FAIL!", row*57+col+ch*57*57);
                                if(`FLAG_VERBOSE) display_error(A1, RES2_CONV3_6, row*57+col+ch*57*57, row*57+col+ch*57*57-count);
                                error_bank1 = error_bank1 + 1;
                            end
                            count=count+1;
                        end
                    end
                end


                if(`FLAG_VERBOSE) $display("========================================================");
                if(error_bank1 == 0) begin
                    if(`FLAG_VERBOSE) $display("RES2_CONV3_6 results in sram #A1 are successfully passed!");
                end else begin
                    $display("RES2_CONV3_6 results in sram #A1 have %0d errors!", error_bank1);
                end
                if(`FLAG_VERBOSE) $display("========================================================\n");

                // for(m=0; m<4608; m=m+1) begin
                //     if(res2_conv3_6_ans_a2[m] === sram_207936x48b_a2.mem[m]) begin
                //         if(`FLAG_VERBOSE) $display("Sram #A2 address %0d PASS!", m);
                //     end else begin
                //         if(`FLAG_VERBOSE) $display("Sram #A2 address %0d FAIL!", m);
                //         if(`FLAG_VERBOSE) display_error(A2, RES2_CONV3_6, m, 0);
                //         error_bank2 = error_bank2 + 1;
                //     end
                // end

                count = 0;
                for(ch0=0; ch<32; ch=ch+1) begin
                    for (row=0; row<12; row=row+1) begin
                        for (col=0; col<12; col=col+1) begin
                            if(res2_conv3_6_ans_a2[count] === sram_207936x48b_a2.mem[row*57+col+ch*57*57]) begin
                                if(`FLAG_VERBOSE) $display("Sram #A2 address %0d PASS!", row*57+col+ch*57*57);
                            end else begin
                                if(`FLAG_VERBOSE) $display("Sram #A2 address %0d FAIL!", row*57+col+ch*57*57);
                                if(`FLAG_VERBOSE) display_error(A2, RES2_CONV3_6, row*57+col+ch*57*57, row*57+col+ch*57*57-count);
                                error_bank2 = error_bank2 + 1;
                            end
                            count=count+1;
                        end
                    end
                end


                if(`FLAG_VERBOSE) $display("========================================================");
                if(error_bank2 == 0) begin
                    if(`FLAG_VERBOSE) $display("RES2_CONV3_6 results in sram #A2 are successfully passed!");
                end else begin
                    $display("RES2_CONV3_6 results in sram #A2 have %0d errors!", error_bank2);
                end
                if(`FLAG_VERBOSE) $display("========================================================\n");

                for(m=0; m<4608; m=m+1) begin
                    if(res2_conv3_6_ans_a3[m] === sram_207936x48b_a3.mem[m]) begin
                        if(`FLAG_VERBOSE) $display("Sram #A3 address %0d PASS!", m);
                    end else begin
                        if(`FLAG_VERBOSE) $display("Sram #A3 address %0d FAIL!", m);
                        if(`FLAG_VERBOSE) display_error(A3, RES2_CONV3_6, m, 0);
                        error_bank3 = error_bank3 + 1;
                    end
                end

                count = 0;
                for(ch0=0; ch<32; ch=ch+1) begin
                    for (row=0; row<12; row=row+1) begin
                        for (col=0; col<12; col=col+1) begin
                            if(res2_conv3_6_ans_a3[count] === sram_207936x48b_a3.mem[row*57+col+ch*57*57]) begin
                                if(`FLAG_VERBOSE) $display("Sram #A3 address %0d PASS!", row*57+col+ch*57*57);
                            end else begin
                                if(`FLAG_VERBOSE) $display("Sram #A3 address %0d FAIL!", row*57+col+ch*57*57);
                                if(`FLAG_VERBOSE) display_error(A3, RES2_CONV3_6, row*57+col+ch*57*57, row*57+col+ch*57*57-count);
                                error_bank3 = error_bank3 + 1;
                            end
                            count=count+1;
                        end
                    end
                end


                if(`FLAG_VERBOSE) $display("========================================================");
                if(error_bank3 == 0) begin
                    if(`FLAG_VERBOSE) $display("RES2_CONV3_6 results in sram #A3 are successfully passed!");
                end else begin
                    $display("RES2_CONV3_6 results in sram #A3 have %0d errors!", error_bank3);
                end
                if(`FLAG_VERBOSE) $display("========================================================");
                error_total = error_bank0 + error_bank1 + error_bank2 + error_bank3; 

                // summary of this pattern    
                if(`FLAG_VERBOSE) $display("\n========================================================");
                if(error_total == 0) begin
                    if(`FLAG_VERBOSE) $display("Congratulations! Your RES2_CONV3_6 layer is correct!");
                    if(`FLAG_VERBOSE) $display("Pattern No. %02d is successfully passed !", pat_idx);
                    else              $write("%c[1;32mPASS! %c[0m",27, 27);
                end else begin
                    if(`FLAG_VERBOSE) $display("There are total %0d errors in your RES2_CONV3_6 layer.", error_total);
                    if(`FLAG_VERBOSE) $display("Pattern No. %02d is failed...", pat_idx);
                    else              $write("%c[1;31mFAIL! %c[0m",27, 27);
                    total_err_pat = total_err_pat + 1;
                end
                if(`FLAG_VERBOSE) $display("========================================================");
            end

            RES2_CONV3_7: begin
                // for(m=0; m<4232; m=m+1) begin
                //     if(res2_conv3_7_ans_b0[m] === sram_50176x48b_b0.mem[m]) begin
                //         if(`FLAG_VERBOSE) $display("Sram #B0 address %0d PASS!", m);
                //     end else begin
                //         if(`FLAG_VERBOSE) $display("Sram #B0 address %0d FAIL!", m);
                //         if(`FLAG_VERBOSE) display_error(B0, RES2_CONV3_7, m, 0);
                //         error_bank0 = error_bank0 + 1;
                //     end
                // end

                count = 0;
                for(ch0=0; ch<32; ch=ch+1) begin
                    for (row=0; row<12; row=row+1) begin
                        for (col=0; col<12; col=col+1) begin
                            if(res2_conv3_7_ans_b0[count] === sram_50176x48b_b0.mem[row*57+col+ch*57*57]) begin
                                if(`FLAG_VERBOSE) $display("Sram #B0 address %0d PASS!", row*57+col+ch*57*57);
                            end else begin
                                if(`FLAG_VERBOSE) $display("Sram #B0 address %0d FAIL!", row*57+col+ch*57*57);
                                if(`FLAG_VERBOSE) display_error(B0, RES2_CONV3_7, row*57+col+ch*57*57, row*57+col+ch*57*57-count);
                                error_bank0 = error_bank0 + 1;
                            end
                            count=count+1;
                        end
                    end
                end

                if(`FLAG_VERBOSE) $display("========================================================");
                if(error_bank0 == 0) begin
                    if(`FLAG_VERBOSE) $display("RES2_CONV3_7 results in sram #B0 are successfully passed!");
                end else begin
                    $display("RES2_CONV3_7 results in sram #B0 have %0d errors!", error_bank0);
                end
                if(`FLAG_VERBOSE) $display("========================================================\n");

                // for(m=0; m<4232; m=m+1) begin
                //     if(res2_conv3_7_ans_b1[m] === sram_50176x48b_b1.mem[m]) begin
                //         if(`FLAG_VERBOSE) $display("Sram #B1 address %0d PASS!", m);
                //     end else begin
                //         if(`FLAG_VERBOSE) $display("Sram #B1 address %0d FAIL!", m);
                //         if(`FLAG_VERBOSE) display_error(B1, RES2_CONV3_7, m, 0);
                //         error_bank1 = error_bank1 + 1;
                //     end
                // end

                count = 0;
                for(ch0=0; ch<32; ch=ch+1) begin
                    for (row=0; row<12; row=row+1) begin
                        for (col=0; col<11; col=col+1) begin
                            if(res2_conv3_7_ans_b1[count] === sram_50176x48b_b1.mem[row*57+col+ch*57*57]) begin
                                if(`FLAG_VERBOSE) $display("Sram #B1 address %0d PASS!", row*57+col+ch*57*57);
                            end else begin
                                if(`FLAG_VERBOSE) $display("Sram #B1 address %0d FAIL!", row*57+col+ch*57*57);
                                if(`FLAG_VERBOSE) display_error(B1, RES2_CONV3_7, row*57+col+ch*57*57, row*57+col+ch*57*57-count);
                                error_bank1 = error_bank1 + 1;
                            end
                            count=count+1;
                        end
                    end
                end


                if(`FLAG_VERBOSE) $display("========================================================");
                if(error_bank1 == 0) begin
                    if(`FLAG_VERBOSE) $display("RES2_CONV3_7 results in sram #B1 are successfully passed!");
                end else begin
                    $display("RES2_CONV3_7 results in sram #B1 have %0d errors!", error_bank1);
                end
                if(`FLAG_VERBOSE) $display("========================================================\n");

                // for(m=0; m<4232; m=m+1) begin
                //     if(res2_conv3_7_ans_b2[m] === sram_50176x48b_b2.mem[m]) begin
                //         if(`FLAG_VERBOSE) $display("Sram #B2 address %0d PASS!", m);
                //     end else begin
                //         if(`FLAG_VERBOSE) $display("Sram #B2 address %0d FAIL!", m);
                //         if(`FLAG_VERBOSE) display_error(B2, RES2_CONV3_7, m, 0);
                //         error_bank2 = error_bank2 + 1;
                //     end
                // end

                count = 0;
                for(ch0=0; ch<32; ch=ch+1) begin
                    for (row=0; row<11; row=row+1) begin
                        for (col=0; col<12; col=col+1) begin
                            if(res2_conv3_7_ans_b2[count] === sram_50176x48b_b2.mem[row*57+col+ch*57*57]) begin
                                if(`FLAG_VERBOSE) $display("Sram #B2 address %0d PASS!", row*57+col+ch*57*57);
                            end else begin
                                if(`FLAG_VERBOSE) $display("Sram #B2 address %0d FAIL!", row*57+col+ch*57*57);
                                if(`FLAG_VERBOSE) display_error(B2, RES2_CONV3_7, row*57+col+ch*57*57, row*57+col+ch*57*57-count);
                                error_bank2 = error_bank2 + 1;
                            end
                            count=count+1;
                        end
                    end
                end


                if(`FLAG_VERBOSE) $display("========================================================");
                if(error_bank2 == 0) begin
                    if(`FLAG_VERBOSE) $display("RES2_CONV3_7 results in sram #B2 are successfully passed!");
                end else begin
                    $display("RES2_CONV3_7 results in sram #B2 have %0d errors!", error_bank2);
                end
                if(`FLAG_VERBOSE) $display("========================================================\n");

                // for(m=0; m<4232; m=m+1) begin
                //     if(res2_conv3_7_ans_b3[m] === sram_50176x48b_b3.mem[m]) begin
                //         if(`FLAG_VERBOSE) $display("Sram #B3 address %0d PASS!", m);
                //     end else begin
                //         if(`FLAG_VERBOSE) $display("Sram #B3 address %0d FAIL!", m);
                //         if(`FLAG_VERBOSE) display_error(B3, RES2_CONV3_7, m, 0);
                //         error_bank3 = error_bank3 + 1;
                //     end
                // end

                count = 0;
                for(ch0=0; ch<32; ch=ch+1) begin
                    for (row=0; row<11; row=row+1) begin
                        for (col=0; col<11; col=col+1) begin
                            if(res2_conv3_7_ans_b3[count] === sram_50176x48b_b3.mem[row*57+col+ch*57*57]) begin
                                if(`FLAG_VERBOSE) $display("Sram #B3 address %0d PASS!", row*57+col+ch*57*57);
                            end else begin
                                if(`FLAG_VERBOSE) $display("Sram #B3 address %0d FAIL!", row*57+col+ch*57*57);
                                if(`FLAG_VERBOSE) display_error(B3, RES2_CONV3_7, row*57+col+ch*57*57, row*57+col+ch*57*57-count);
                                error_bank3 = error_bank3 + 1;
                            end
                            count=count+1;
                        end
                    end
                end


                if(`FLAG_VERBOSE) $display("========================================================");
                if(error_bank3 == 0) begin
                    if(`FLAG_VERBOSE) $display("RES2_CONV3_7 results in sram #B3 are successfully passed!");
                end else begin
                    $display("RES2_CONV3_7 results in sram #B3 have %0d errors!", error_bank3);
                end
                if(`FLAG_VERBOSE) $display("========================================================");
                error_total = error_bank0 + error_bank1 + error_bank2 + error_bank3; 

                // summary of this pattern    
                if(`FLAG_VERBOSE) $display("\n========================================================");
                if(error_total == 0) begin
                    if(`FLAG_VERBOSE) $display("Congratulations! Your RES2_CONV3_7 layer is correct!");
                    if(`FLAG_VERBOSE) $display("Pattern No. %02d is successfully passed !", pat_idx);
                    else              $write("%c[1;32mPASS! %c[0m",27, 27);
                end else begin
                    if(`FLAG_VERBOSE) $display("There are total %0d errors in your RES2_CONV3_7 layer.", error_total);
                    if(`FLAG_VERBOSE) $display("Pattern No. %02d is failed...", pat_idx);
                    else              $write("%c[1;31mFAIL! %c[0m",27, 27);
                    total_err_pat = total_err_pat + 1;
                end
                if(`FLAG_VERBOSE) $display("========================================================");
            end

            CONV3_POOL_8: begin
                // for(m=0; m<1936; m=m+1) begin
                //     if(conv3_pool_8_ans_a0[m] === sram_207936x48b_a0.mem[m]) begin
                //         if(`FLAG_VERBOSE) $display("Sram #A0 address %0d PASS!", m);
                //     end else begin
                //         if(`FLAG_VERBOSE) $display("Sram #A0 address %0d FAIL!", m);
                //         if(`FLAG_VERBOSE) display_error(A0, CONV3_POOL_8, m, 0);
                //         error_bank0 = error_bank0 + 1;
                //     end
                // end

                count = 0;
                for(ch0=0; ch<64; ch=ch+1) begin
                    for (row=0; row<6; row=row+1) begin
                        for (col=0; col<6; col=col+1) begin
                            if(conv3_pool_8_ans_a0[count] === sram_207936x48b_a0.mem[row*57+col+ch*57*57]) begin
                                if(`FLAG_VERBOSE) $display("Sram #A0 address %0d PASS!", row*57+col+ch*57*57);
                            end else begin
                                if(`FLAG_VERBOSE) $display("Sram #A0 address %0d FAIL!", row*57+col+ch*57*57);
                                if(`FLAG_VERBOSE) display_error(A0, CONV3_POOL_8, row*57+col+ch*57*57, row*57+col+ch*57*57-count);
                                error_bank0 = error_bank0 + 1;
                            end
                            count=count+1;
                        end
                    end
                end

                if(`FLAG_VERBOSE) $display("========================================================");
                if(error_bank0 == 0) begin
                    if(`FLAG_VERBOSE) $display("CONV3_POOL_8 results in sram #A0 are successfully passed!");
                end else begin
                    $display("CONV3_POOL_8 results in sram #A0 have %0d errors!", error_bank0);
                end
                if(`FLAG_VERBOSE) $display("========================================================\n");

                // for(m=0; m<1936; m=m+1) begin
                //     if(conv3_pool_8_ans_a1[m] === sram_207936x48b_a1.mem[m]) begin
                //         if(`FLAG_VERBOSE) $display("Sram #A1 address %0d PASS!", m);
                //     end else begin
                //         if(`FLAG_VERBOSE) $display("Sram #A1 address %0d FAIL!", m);
                //         if(`FLAG_VERBOSE) display_error(A1, CONV3_POOL_8, m, 0);
                //         error_bank1 = error_bank1 + 1;
                //     end
                // end

                count = 0;
                for(ch0=0; ch<64; ch=ch+1) begin
                    for (row=0; row<6; row=row+1) begin
                        for (col=0; col<5; col=col+1) begin
                            if(conv3_pool_8_ans_a1[count] === sram_207936x48b_a1.mem[row*57+col+ch*57*57]) begin
                                if(`FLAG_VERBOSE) $display("Sram #A1 address %0d PASS!", row*57+col+ch*57*57);
                            end else begin
                                if(`FLAG_VERBOSE) $display("Sram #A1 address %0d FAIL!", row*57+col+ch*57*57);
                                if(`FLAG_VERBOSE) display_error(A1, CONV3_POOL_8, row*57+col+ch*57*57, row*57+col+ch*57*57-count);
                                error_bank1 = error_bank1 + 1;
                            end
                            count=count+1;
                        end
                    end
                end

                if(`FLAG_VERBOSE) $display("========================================================");
                if(error_bank1 == 0) begin
                    if(`FLAG_VERBOSE) $display("CONV3_POOL_8 results in sram #A1 are successfully passed!");
                end else begin
                    $display("CONV3_POOL_8 results in sram #A1 have %0d errors!", error_bank1);
                end
                if(`FLAG_VERBOSE) $display("========================================================\n");

                // for(m=0; m<1936; m=m+1) begin
                //     if(conv3_pool_8_ans_a2[m] === sram_207936x48b_a2.mem[m]) begin
                //         if(`FLAG_VERBOSE) $display("Sram #A2 address %0d PASS!", m);
                //     end else begin
                //         if(`FLAG_VERBOSE) $display("Sram #A2 address %0d FAIL!", m);
                //         if(`FLAG_VERBOSE) display_error(A2, CONV3_POOL_8, m, 0);
                //         error_bank2 = error_bank2 + 1;
                //     end
                // end

                count = 0;
                for(ch0=0; ch<64; ch=ch+1) begin
                    for (row=0; row<5; row=row+1) begin
                        for (col=0; col<6; col=col+1) begin
                            if(conv3_pool_8_ans_a2[count] === sram_207936x48b_a2.mem[row*57+col+ch*57*57]) begin
                                if(`FLAG_VERBOSE) $display("Sram #A2 address %0d PASS!", row*57+col+ch*57*57);
                            end else begin
                                if(`FLAG_VERBOSE) $display("Sram #A2 address %0d FAIL!", row*57+col+ch*57*57);
                                if(`FLAG_VERBOSE) display_error(A2, CONV3_POOL_8, row*57+col+ch*57*57, row*57+col+ch*57*57-count);
                                error_bank2 = error_bank2 + 1;
                            end
                            count=count+1;
                        end
                    end
                end

                if(`FLAG_VERBOSE) $display("========================================================");
                if(error_bank2 == 0) begin
                    if(`FLAG_VERBOSE) $display("CONV3_POOL_8 results in sram #A2 are successfully passed!");
                end else begin
                    $display("CONV3_POOL_8 results in sram #A2 have %0d errors!", error_bank2);
                end
                if(`FLAG_VERBOSE) $display("========================================================\n");

                // for(m=0; m<1936; m=m+1) begin
                //     if(conv3_pool_8_ans_a3[m] === sram_207936x48b_a3.mem[m]) begin
                //         if(`FLAG_VERBOSE) $display("Sram #A3 address %0d PASS!", m);
                //     end else begin
                //         if(`FLAG_VERBOSE) $display("Sram #A3 address %0d FAIL!", m);
                //         if(`FLAG_VERBOSE) display_error(A3, CONV3_POOL_8, m, 0);
                //         error_bank3 = error_bank3 + 1;
                //     end
                // end

                count = 0;
                for(ch0=0; ch<64; ch=ch+1) begin
                    for (row=0; row<5; row=row+1) begin
                        for (col=0; col<5; col=col+1) begin
                            if(conv3_pool_8_ans_a3[count] === sram_207936x48b_a3.mem[row*57+col+ch*57*57]) begin
                                if(`FLAG_VERBOSE) $display("Sram #A3 address %0d PASS!", row*57+col+ch*57*57);
                            end else begin
                                if(`FLAG_VERBOSE) $display("Sram #A3 address %0d FAIL!", row*57+col+ch*57*57);
                                if(`FLAG_VERBOSE) display_error(A3, CONV3_POOL_8, row*57+col+ch*57*57, row*57+col+ch*57*57-count);
                                error_bank3 = error_bank3 + 1;
                            end
                            count=count+1;
                        end
                    end
                end

                if(`FLAG_VERBOSE) $display("========================================================");
                if(error_bank3 == 0) begin
                    if(`FLAG_VERBOSE) $display("CONV3_POOL_8 results in sram #A3 are successfully passed!");
                end else begin
                    $display("CONV3_POOL_8 results in sram #A3 have %0d errors!", error_bank3);
                end
                if(`FLAG_VERBOSE) $display("========================================================");
                error_total = error_bank0 + error_bank1 + error_bank2 + error_bank3; 

                // summary of this pattern    
                if(`FLAG_VERBOSE) $display("\n========================================================");
                if(error_total == 0) begin
                    if(`FLAG_VERBOSE) $display("Congratulations! Your CONV3_POOL_8 layer is correct!");
                    if(`FLAG_VERBOSE) $display("Pattern No. %02d is successfully passed !", pat_idx);
                    else              $write("%c[1;32mPASS! %c[0m",27, 27);
                end else begin
                    if(`FLAG_VERBOSE) $display("There are total %0d errors in your CONV3_POOL_8 layer.", error_total);
                    if(`FLAG_VERBOSE) $display("Pattern No. %02d is failed...", pat_idx);
                    else              $write("%c[1;31mFAIL! %c[0m",27, 27);
                    total_err_pat = total_err_pat + 1;
                end
                if(`FLAG_VERBOSE) $display("========================================================");
            end

            RES3_CONV3_9: begin
                // for(m=0; m<1600; m=m+1) begin
                //     if(res3_conv3_9_ans_b0[m] === sram_50176x48b_b0.mem[m]) begin
                //         if(`FLAG_VERBOSE) $display("Sram #B0 address %0d PASS!", m);
                //     end else begin
                //         if(`FLAG_VERBOSE) $display("Sram #B0 address %0d FAIL!", m);
                //         if(`FLAG_VERBOSE) display_error(B0, RES3_CONV3_9, m, 0);
                //         error_bank0 = error_bank0 + 1;
                //     end
                // end

                count = 0;
                for(ch0=0; ch<64; ch=ch+1) begin
                    for (row=0; row<5; row=row+1) begin
                        for (col=0; col<5; col=col+1) begin
                            if(res3_conv3_9_ans_b0[count] === sram_50176x48b_b0.mem[row*57+col+ch*57*57]) begin
                                if(`FLAG_VERBOSE) $display("Sram #B0 address %0d PASS!", row*57+col+ch*57*57);
                            end else begin
                                if(`FLAG_VERBOSE) $display("Sram #B0 address %0d FAIL!", row*57+col+ch*57*57);
                                if(`FLAG_VERBOSE) display_error(B0, RES3_CONV3_9, row*57+col+ch*57*57, row*57+col+ch*57*57-count);
                                error_bank0 = error_bank0 + 1;
                            end
                            count=count+1;
                        end
                    end
                end

                if(`FLAG_VERBOSE) $display("========================================================");
                if(error_bank0 == 0) begin
                    if(`FLAG_VERBOSE) $display("RES3_CONV3_9 results in sram #B0 are successfully passed!");
                end else begin
                    $display("RES3_CONV3_9 results in sram #B0 have %0d errors!", error_bank0);
                end
                if(`FLAG_VERBOSE) $display("========================================================\n");

                // for(m=0; m<1600; m=m+1) begin
                //     if(res3_conv3_9_ans_b1[m] === sram_50176x48b_b1.mem[m]) begin
                //         if(`FLAG_VERBOSE) $display("Sram #B1 address %0d PASS!", m);
                //     end else begin
                //         if(`FLAG_VERBOSE) $display("Sram #B1 address %0d FAIL!", m);
                //         if(`FLAG_VERBOSE) display_error(B1, RES3_CONV3_9, m, 0);
                //         error_bank1 = error_bank1 + 1;
                //     end
                // end

                count = 0;
                for(ch0=0; ch<64; ch=ch+1) begin
                    for (row=0; row<5; row=row+1) begin
                        for (col=0; col<5; col=col+1) begin
                            if(res3_conv3_9_ans_b1[count] === sram_50176x48b_b1.mem[row*57+col+ch*57*57]) begin
                                if(`FLAG_VERBOSE) $display("Sram #B1 address %0d PASS!", row*57+col+ch*57*57);
                            end else begin
                                if(`FLAG_VERBOSE) $display("Sram #B1 address %0d FAIL!", row*57+col+ch*57*57);
                                if(`FLAG_VERBOSE) display_error(B1, RES3_CONV3_9, row*57+col+ch*57*57, row*57+col+ch*57*57-count);
                                error_bank1 = error_bank1 + 1;
                            end
                            count=count+1;
                        end
                    end
                end

                if(`FLAG_VERBOSE) $display("========================================================");
                if(error_bank1 == 0) begin
                    if(`FLAG_VERBOSE) $display("RES3_CONV3_9 results in sram #B1 are successfully passed!");
                end else begin
                    $display("RES3_CONV3_9 results in sram #B1 have %0d errors!", error_bank1);
                end
                if(`FLAG_VERBOSE) $display("========================================================\n");

                // for(m=0; m<1600; m=m+1) begin
                //     if(res3_conv3_9_ans_b2[m] === sram_50176x48b_b2.mem[m]) begin
                //         if(`FLAG_VERBOSE) $display("Sram #B2 address %0d PASS!", m);
                //     end else begin
                //         if(`FLAG_VERBOSE) $display("Sram #B2 address %0d FAIL!", m);
                //         if(`FLAG_VERBOSE) display_error(B2, RES3_CONV3_9, m, 0);
                //         error_bank2 = error_bank2 + 1;
                //     end
                // end

                count = 0;
                for(ch0=0; ch<64; ch=ch+1) begin
                    for (row=0; row<5; row=row+1) begin
                        for (col=0; col<5; col=col+1) begin
                            if(res3_conv3_9_ans_b2[count] === sram_50176x48b_b2.mem[row*57+col+ch*57*57]) begin
                                if(`FLAG_VERBOSE) $display("Sram #B2 address %0d PASS!", row*57+col+ch*57*57);
                            end else begin
                                if(`FLAG_VERBOSE) $display("Sram #B2 address %0d FAIL!", row*57+col+ch*57*57);
                                if(`FLAG_VERBOSE) display_error(B2, RES3_CONV3_9, row*57+col+ch*57*57, row*57+col+ch*57*57-count);
                                error_bank2 = error_bank2 + 1;
                            end
                            count=count+1;
                        end
                    end
                end

                if(`FLAG_VERBOSE) $display("========================================================");
                if(error_bank2 == 0) begin
                    if(`FLAG_VERBOSE) $display("RES3_CONV3_9 results in sram #B2 are successfully passed!");
                end else begin
                    $display("RES3_CONV3_9 results in sram #B2 have %0d errors!", error_bank2);
                end
                if(`FLAG_VERBOSE) $display("========================================================\n");

                // for(m=0; m<1600; m=m+1) begin
                //     if(res3_conv3_9_ans_b3[m] === sram_50176x48b_b3.mem[m]) begin
                //         if(`FLAG_VERBOSE) $display("Sram #B3 address %0d PASS!", m);
                //     end else begin
                //         if(`FLAG_VERBOSE) $display("Sram #B3 address %0d FAIL!", m);
                //         if(`FLAG_VERBOSE) display_error(B3, RES3_CONV3_9, m, 0);
                //         error_bank3 = error_bank3 + 1;
                //     end
                // end

                count = 0;
                for(ch0=0; ch<64; ch=ch+1) begin
                    for (row=0; row<5; row=row+1) begin
                        for (col=0; col<5; col=col+1) begin
                            if(res3_conv3_9_ans_b3[count] === sram_50176x48b_b3.mem[row*57+col+ch*57*57]) begin
                                if(`FLAG_VERBOSE) $display("Sram #B3 address %0d PASS!", row*57+col+ch*57*57);
                            end else begin
                                if(`FLAG_VERBOSE) $display("Sram #B3 address %0d FAIL!", row*57+col+ch*57*57);
                                if(`FLAG_VERBOSE) display_error(B3, RES3_CONV3_9, row*57+col+ch*57*57, row*57+col+ch*57*57-count);
                                error_bank3 = error_bank3 + 1;
                            end
                            count=count+1;
                        end
                    end
                end

                if(`FLAG_VERBOSE) $display("========================================================");
                if(error_bank3 == 0) begin
                    if(`FLAG_VERBOSE) $display("RES3_CONV3_9 results in sram #B3 are successfully passed!");
                end else begin
                    $display("RES3_CONV3_9 results in sram #B3 have %0d errors!", error_bank3);
                end
                if(`FLAG_VERBOSE) $display("========================================================");
                error_total = error_bank0 + error_bank1 + error_bank2 + error_bank3; 

                // summary of this pattern    
                if(`FLAG_VERBOSE) $display("\n========================================================");
                if(error_total == 0) begin
                    if(`FLAG_VERBOSE) $display("Congratulations! Your RES3_CONV3_9 layer is correct!");
                    if(`FLAG_VERBOSE) $display("Pattern No. %02d is successfully passed !", pat_idx);
                    else              $write("%c[1;32mPASS! %c[0m",27, 27);
                end else begin
                    if(`FLAG_VERBOSE) $display("There are total %0d errors in your RES3_CONV3_9 layer.", error_total);
                    if(`FLAG_VERBOSE) $display("Pattern No. %02d is failed...", pat_idx);
                    else              $write("%c[1;31mFAIL! %c[0m",27, 27);
                    total_err_pat = total_err_pat + 1;
                end
                if(`FLAG_VERBOSE) $display("========================================================");
            end

            RES3_CONV3_10: begin
                // for(m=0; m<1296; m=m+1) begin
                //     if(res3_conv3_10_ans_a0[m] === sram_207936x48b_a0.mem[m]) begin
                //         if(`FLAG_VERBOSE) $display("Sram #A0 address %0d PASS!", m);
                //     end else begin
                //         if(`FLAG_VERBOSE) $display("Sram #A0 address %0d FAIL!", m);
                //         if(`FLAG_VERBOSE) display_error(A0, RES3_CONV3_10, m, 0);
                //         error_bank0 = error_bank0 + 1;
                //     end
                // end

                count = 0;
                for(ch0=0; ch<64; ch=ch+1) begin
                    for (row=0; row<5; row=row+1) begin
                        for (col=0; col<5; col=col+1) begin
                            if(res3_conv3_10_ans_a0[count] === sram_207936x48b_a0.mem[row*57+col+ch*57*57]) begin
                                if(`FLAG_VERBOSE) $display("Sram #A0 address %0d PASS!", row*57+col+ch*57*57);
                            end else begin
                                if(`FLAG_VERBOSE) $display("Sram #A0 address %0d FAIL!", row*57+col+ch*57*57);
                                if(`FLAG_VERBOSE) display_error(A0, RES3_CONV3_10, row*57+col+ch*57*57, row*57+col+ch*57*57-count);
                                error_bank0 = error_bank0 + 1;
                            end
                            count=count+1;
                        end
                    end
                end

                if(`FLAG_VERBOSE) $display("========================================================");
                if(error_bank0 == 0) begin
                    if(`FLAG_VERBOSE) $display("RES3_CONV3_10 results in sram #A0 are successfully passed!");
                end else begin
                    $display("RES3_CONV3_10 results in sram #A0 have %0d errors!", error_bank0);
                end
                if(`FLAG_VERBOSE) $display("========================================================\n");

                // for(m=0; m<1296; m=m+1) begin
                //     if(res3_conv3_10_ans_a1[m] === sram_207936x48b_a1.mem[m]) begin
                //         if(`FLAG_VERBOSE) $display("Sram #A1 address %0d PASS!", m);
                //     end else begin
                //         if(`FLAG_VERBOSE) $display("Sram #A1 address %0d FAIL!", m);
                //         if(`FLAG_VERBOSE) display_error(A1, RES3_CONV3_10, m, 0);
                //         error_bank1 = error_bank1 + 1;
                //     end
                // end

                count = 0;
                for(ch0=0; ch<64; ch=ch+1) begin
                    for (row=0; row<5; row=row+1) begin
                        for (col=0; col<4; col=col+1) begin
                            if(res3_conv3_10_ans_a1[count] === sram_207936x48b_a1.mem[row*57+col+ch*57*57]) begin
                                if(`FLAG_VERBOSE) $display("Sram #A1 address %0d PASS!", row*57+col+ch*57*57);
                            end else begin
                                if(`FLAG_VERBOSE) $display("Sram #A1 address %0d FAIL!", row*57+col+ch*57*57);
                                if(`FLAG_VERBOSE) display_error(A1, RES3_CONV3_10, row*57+col+ch*57*57, row*57+col+ch*57*57-count);
                                error_bank1 = error_bank1 + 1;
                            end
                            count=count+1;
                        end
                    end
                end

                if(`FLAG_VERBOSE) $display("========================================================");
                if(error_bank1 == 0) begin
                    if(`FLAG_VERBOSE) $display("RES3_CONV3_10 results in sram #A1 are successfully passed!");
                end else begin
                    $display("RES3_CONV3_10 results in sram #A1 have %0d errors!", error_bank1);
                end
                if(`FLAG_VERBOSE) $display("========================================================\n");

                // for(m=0; m<1296; m=m+1) begin
                //     if(res3_conv3_10_ans_a2[m] === sram_207936x48b_a2.mem[m]) begin
                //         if(`FLAG_VERBOSE) $display("Sram #A2 address %0d PASS!", m);
                //     end else begin
                //         if(`FLAG_VERBOSE) $display("Sram #A2 address %0d FAIL!", m);
                //         if(`FLAG_VERBOSE) display_error(A2, RES3_CONV3_10, m, 0);
                //         error_bank2 = error_bank2 + 1;
                //     end
                // end

                count = 0;
                for(ch0=0; ch<64; ch=ch+1) begin
                    for (row=0; row<4; row=row+1) begin
                        for (col=0; col<5; col=col+1) begin
                            if(res3_conv3_10_ans_a2[count] === sram_207936x48b_a2.mem[row*57+col+ch*57*57]) begin
                                if(`FLAG_VERBOSE) $display("Sram #A2 address %0d PASS!", row*57+col+ch*57*57);
                            end else begin
                                if(`FLAG_VERBOSE) $display("Sram #A2 address %0d FAIL!", row*57+col+ch*57*57);
                                if(`FLAG_VERBOSE) display_error(A2, RES3_CONV3_10, row*57+col+ch*57*57, row*57+col+ch*57*57-count);
                                error_bank2 = error_bank2 + 1;
                            end
                            count=count+1;
                        end
                    end
                end

                if(`FLAG_VERBOSE) $display("========================================================");
                if(error_bank2 == 0) begin
                    if(`FLAG_VERBOSE) $display("RES3_CONV3_10 results in sram #A2 are successfully passed!");
                end else begin
                    $display("RES3_CONV3_10 results in sram #A2 have %0d errors!", error_bank2);
                end
                if(`FLAG_VERBOSE) $display("========================================================\n");

                // for(m=0; m<1296; m=m+1) begin
                //     if(res3_conv3_10_ans_a3[m] === sram_207936x48b_a3.mem[m]) begin
                //         if(`FLAG_VERBOSE) $display("Sram #A3 address %0d PASS!", m);
                //     end else begin
                //         if(`FLAG_VERBOSE) $display("Sram #A3 address %0d FAIL!", m);
                //         if(`FLAG_VERBOSE) display_error(A3, RES3_CONV3_10, m, 0);
                //         error_bank3 = error_bank3 + 1;
                //     end
                // end
    
                count = 0;
                for(ch0=0; ch<64; ch=ch+1) begin
                    for (row=0; row<4; row=row+1) begin
                        for (col=0; col<4; col=col+1) begin
                            if(res3_conv3_10_ans_a3[count] === sram_207936x48b_a3.mem[row*57+col+ch*57*57]) begin
                                if(`FLAG_VERBOSE) $display("Sram #A3 address %0d PASS!", row*57+col+ch*57*57);
                            end else begin
                                if(`FLAG_VERBOSE) $display("Sram #A3 address %0d FAIL!", row*57+col+ch*57*57);
                                if(`FLAG_VERBOSE) display_error(A3, RES3_CONV3_10, row*57+col+ch*57*57, row*57+col+ch*57*57-count);
                                error_bank3 = error_bank3 + 1;
                            end
                            count=count+1;
                        end
                    end
                end

                if(`FLAG_VERBOSE) $display("========================================================");
                if(error_bank3 == 0) begin
                    if(`FLAG_VERBOSE) $display("RES3_CONV3_10 results in sram #A3 are successfully passed!");
                end else begin
                    $display("RES3_CONV3_10 results in sram #A3 have %0d errors!", error_bank3);
                end
                if(`FLAG_VERBOSE) $display("========================================================");
                error_total = error_bank0 + error_bank1 + error_bank2 + error_bank3; 

                // summary of this pattern    
                if(`FLAG_VERBOSE) $display("\n========================================================");
                if(error_total == 0) begin
                    if(`FLAG_VERBOSE) $display("Congratulations! Your RES3_CONV3_10 layer is correct!");
                    if(`FLAG_VERBOSE) $display("Pattern No. %02d is successfully passed !", pat_idx);
                    else              $write("%c[1;32mPASS! %c[0m",27, 27);
                end else begin
                    if(`FLAG_VERBOSE) $display("There are total %0d errors in your RES3_CONV3_10 layer.", error_total);
                    if(`FLAG_VERBOSE) $display("Pattern No. %02d is failed...", pat_idx);
                    else              $write("%c[1;31mFAIL! %c[0m",27, 27);
                    total_err_pat = total_err_pat + 1;
                end
                if(`FLAG_VERBOSE) $display("========================================================");
            end

            CONV3_POOL_11: begin
                // for(m=0; m<256; m=m+1) begin
                //     if(conv3_pool_11_ans_b0[m] === sram_50176x48b_b0.mem[m]) begin
                //         if(`FLAG_VERBOSE) $display("Sram #B0 address %0d PASS!", m);
                //     end else begin
                //         if(`FLAG_VERBOSE) $display("Sram #B0 address %0d FAIL!", m);
                //         if(`FLAG_VERBOSE) display_error(B0, CONV3_POOL_11, m, 0);
                //         error_bank0 = error_bank0 + 1;
                //     end
                // end

                count = 0;
                for(ch0=0; ch<64; ch=ch+1) begin
                    for (row=0; row<2; row=row+1) begin
                        for (col=0; col<2; col=col+1) begin
                            if(conv3_pool_11_ans_b0[count] === sram_50176x48b_b0.mem[row*57+col+ch*57*57]) begin
                                if(`FLAG_VERBOSE) $display("Sram #B0 address %0d PASS!", row*57+col+ch*57*57);
                            end else begin
                                if(`FLAG_VERBOSE) $display("Sram #B0 address %0d FAIL!", row*57+col+ch*57*57);
                                if(`FLAG_VERBOSE) display_error(B0, CONV3_POOL_11, row*57+col+ch*57*57, row*57+col+ch*57*57-count);
                                error_bank0 = error_bank0 + 1;
                            end
                            count=count+1;
                        end
                    end
                end
    
                if(`FLAG_VERBOSE) $display("========================================================");
                if(error_bank0 == 0) begin
                    if(`FLAG_VERBOSE) $display("CONV3_POOL_11 results in sram #B0 are successfully passed!");
                end else begin
                    $display("CONV3_POOL_11 results in sram #B0 have %0d errors!", error_bank0);
                end
                if(`FLAG_VERBOSE) $display("========================================================\n");

                // for(m=0; m<256; m=m+1) begin
                //     if(conv3_pool_11_ans_b1[m] === sram_50176x48b_b1.mem[m]) begin
                //         if(`FLAG_VERBOSE) $display("Sram #B1 address %0d PASS!", m);
                //     end else begin
                //         if(`FLAG_VERBOSE) $display("Sram #B1 address %0d FAIL!", m);
                //         if(`FLAG_VERBOSE) display_error(B1, CONV3_POOL_11, m, 0);
                //         error_bank1 = error_bank1 + 1;
                //     end
                // end

                count = 0;
                for(ch0=0; ch<64; ch=ch+1) begin
                    for (row=0; row<2; row=row+1) begin
                        for (col=0; col<2; col=col+1) begin
                            if(conv3_pool_11_ans_b1[count] === sram_50176x48b_b1.mem[row*57+col+ch*57*57]) begin
                                if(`FLAG_VERBOSE) $display("Sram #B1 address %0d PASS!", row*57+col+ch*57*57);
                            end else begin
                                if(`FLAG_VERBOSE) $display("Sram #B1 address %0d FAIL!", row*57+col+ch*57*57);
                                if(`FLAG_VERBOSE) display_error(B1, CONV3_POOL_11, row*57+col+ch*57*57, row*57+col+ch*57*57-count);
                                error_bank1 = error_bank1 + 1;
                            end
                            count=count+1;
                        end
                    end
                end

                if(`FLAG_VERBOSE) $display("========================================================");
                if(error_bank1 == 0) begin
                    if(`FLAG_VERBOSE) $display("CONV3_POOL_11 results in sram #B1 are successfully passed!");
                end else begin
                    $display("CONV3_POOL_11 results in sram #B1 have %0d errors!", error_bank1);
                end
                if(`FLAG_VERBOSE) $display("========================================================\n");

                // for(m=0; m<256; m=m+1) begin
                //     if(conv3_pool_11_ans_b2[m] === sram_50176x48b_b2.mem[m]) begin
                //         if(`FLAG_VERBOSE) $display("Sram #B2 address %0d PASS!", m);
                //     end else begin
                //         if(`FLAG_VERBOSE) $display("Sram #B2 address %0d FAIL!", m);
                //         if(`FLAG_VERBOSE) display_error(B2, CONV3_POOL_11, m, 0);
                //         error_bank2 = error_bank2 + 1;
                //     end
                // end

                count = 0;
                for(ch0=0; ch<64; ch=ch+1) begin
                    for (row=0; row<2; row=row+1) begin
                        for (col=0; col<2; col=col+1) begin
                            if(conv3_pool_11_ans_b2[count] === sram_50176x48b_b2.mem[row*57+col+ch*57*57]) begin
                                if(`FLAG_VERBOSE) $display("Sram #B2 address %0d PASS!", row*57+col+ch*57*57);
                            end else begin
                                if(`FLAG_VERBOSE) $display("Sram #B2 address %0d FAIL!", row*57+col+ch*57*57);
                                if(`FLAG_VERBOSE) display_error(B2, CONV3_POOL_11, row*57+col+ch*57*57, row*57+col+ch*57*57-count);
                                error_bank2 = error_bank2 + 1;
                            end
                            count=count+1;
                        end
                    end
                end

                if(`FLAG_VERBOSE) $display("========================================================");
                if(error_bank2 == 0) begin
                    if(`FLAG_VERBOSE) $display("CONV3_POOL_11 results in sram #B2 are successfully passed!");
                end else begin
                    $display("CONV3_POOL_11 results in sram #B2 have %0d errors!", error_bank2);
                end
                if(`FLAG_VERBOSE) $display("========================================================\n");

                // for(m=0; m<256; m=m+1) begin
                //     if(conv3_pool_11_ans_b3[m] === sram_50176x48b_b3.mem[m]) begin
                //         if(`FLAG_VERBOSE) $display("Sram #B3 address %0d PASS!", m);
                //     end else begin
                //         if(`FLAG_VERBOSE) $display("Sram #B3 address %0d FAIL!", m);
                //         if(`FLAG_VERBOSE) display_error(B3, CONV3_POOL_11, m, 0);
                //         error_bank3 = error_bank3 + 1;
                //     end
                // end

                count = 0;
                for(ch0=0; ch<64; ch=ch+1) begin
                    for (row=0; row<2; row=row+1) begin
                        for (col=0; col<2; col=col+1) begin
                            if(conv3_pool_11_ans_b3[count] === sram_50176x48b_b3.mem[row*57+col+ch*57*57]) begin
                                if(`FLAG_VERBOSE) $display("Sram #B3 address %0d PASS!", row*57+col+ch*57*57);
                            end else begin
                                if(`FLAG_VERBOSE) $display("Sram #B3 address %0d FAIL!", row*57+col+ch*57*57);
                                if(`FLAG_VERBOSE) display_error(B3, CONV3_POOL_11, row*57+col+ch*57*57, row*57+col+ch*57*57-count);
                                error_bank3 = error_bank3 + 1;
                            end
                            count=count+1;
                        end
                    end
                end

                if(`FLAG_VERBOSE) $display("========================================================");
                if(error_bank3 == 0) begin
                    if(`FLAG_VERBOSE) $display("CONV3_POOL_11 results in sram #B3 are successfully passed!");
                end else begin
                    $display("CONV3_POOL_11 results in sram #B3 have %0d errors!", error_bank3);
                end
                if(`FLAG_VERBOSE) $display("========================================================");
                error_total = error_bank0 + error_bank1 + error_bank2 + error_bank3; 

                // summary of this pattern    
                if(`FLAG_VERBOSE) $display("\n========================================================");
                if(error_total == 0) begin
                    if(`FLAG_VERBOSE) $display("Congratulations! Your CONV3_POOL_11 layer is correct!");
                    if(`FLAG_VERBOSE) $display("Pattern No. %02d is successfully passed !", pat_idx);
                    else              $write("%c[1;32mPASS! %c[0m",27, 27);
                end else begin
                    if(`FLAG_VERBOSE) $display("There are total %0d errors in your CONV3_POOL_11 layer.", error_total);
                    if(`FLAG_VERBOSE) $display("Pattern No. %02d is failed...", pat_idx);
                    else              $write("%c[1;31mFAIL! %c[0m",27, 27);
                    total_err_pat = total_err_pat + 1;
                end
                if(`FLAG_VERBOSE) $display("========================================================");
            end

            GLOBAL_AVE: begin
                for(m=0; m<64; m=m+1) begin
                    if(global_ave_ans_a0[m] === sram_207936x48b_a0.mem[m*57*57]) begin
                        if(`FLAG_VERBOSE) $display("Sram #A0 address %0d PASS!", m);
                    end else begin
                        if(`FLAG_VERBOSE) $display("Sram #A0 address %0d FAIL!", m);
                        if(`FLAG_VERBOSE) display_error(A0, GLOBAL_AVE, m, 0);
                        error_bank0 = error_bank0 + 1;
                    end
                end
                if(`FLAG_VERBOSE) $display("========================================================");
                if(error_bank0 == 0) begin
                    if(`FLAG_VERBOSE) $display("GLOBAL_AVE results in sram #A0 are successfully passed!");
                end else begin
                    $display("GLOBAL_AVE results in sram #A0 have %0d errors!", error_bank0);
                end
                if(`FLAG_VERBOSE) $display("========================================================\n");
            end

            FC: begin
                if(fc_ans[0] === sram_50176x48b_b0.mem[0]) begin
                    if(`FLAG_VERBOSE) $display("Sram #B0 address %0d PASS!", m);
                end else begin
                    if(`FLAG_VERBOSE) $display("Sram #B0 address %0d FAIL!", m);
                    if(`FLAG_VERBOSE) display_error(B0, FC, 0, 0);
                    error_bank0 = error_bank0 + 1;
                end
                if(`FLAG_VERBOSE) $display("========================================================");
                if(error_bank0 == 0) begin
                    if(`FLAG_VERBOSE) $display("FC results in sram #B0 are successfully passed!");
                end else begin
                    $display("FC results in sram #B0 have %0d errors!", error_bank0);
                end
                if(`FLAG_VERBOSE) $display("========================================================\n");

                if(fc_ans[1] === sram_50176x48b_b1.mem[1]) begin
                    if(`FLAG_VERBOSE) $display("Sram #B1 address %0d PASS!", m);
                end else begin
                    if(`FLAG_VERBOSE) $display("Sram #B1 address %0d FAIL!", m);
                    if(`FLAG_VERBOSE) display_error(B1, FC, 1, 0);
                    error_bank1 = error_bank1 + 1;
                end
                if(`FLAG_VERBOSE) $display("========================================================");
                if(error_bank1 == 0) begin
                    if(`FLAG_VERBOSE) $display("FC results in sram #B1 are successfully passed!");
                end else begin
                    $display("FC results in sram #B1 have %0d errors!", error_bank1);
                end
                if(`FLAG_VERBOSE) $display("========================================================\n");
            end
        endcase
    end

    aver_cycle_cnt = cycle_cnt/`NUM_PAT;
    // summary of all pattern
    $display("\n\n\n             Summary of all pattern: ");
    if(total_err_pat == 0) begin 
        $display("-----------------------------------------------------\n");
        $write("%c[1;32mCongratulations! %c[0m",27, 27);
        case(test_layer)
            INPUT:          $display("Your INPUT layer is correct!");
            CONV3_POOL_1:   $display("Your CONV3_POOL_1 layer is correct!");
            CONV3_2:        $display("Your CONV3_2 layer is correct!");
            CONV3_POOL_3:   $display("Your CONV3_POOL_3 layer is correct!");
            RES1_CONV3_4:   $display("Your RES1_CONV3_4 layer is correct!");
            RES1_CONV3_5:   $display("Your RES1_CONV3_5 layer is correct!");  
            RES2_CONV3_6:   $display("Your RES2_CONV3_6 layer is correct!");
            RES2_CONV3_7:   $display("Your RES2_CONV3_7 layer is correct!");              
            CONV3_POOL_8:   $display("Your CONV3_POOL_8 layer is correct!");
            RES3_CONV3_9:   $display("Your RES3_CONV3_9 layer is correct!");  
            RES3_CONV3_10:  $display("Your RES3_CONV3_10 layer is correct!");
            CONV3_POOL_11:  $display("Your CONV3_POOL_11 layer is correct!");
            GLOBAL_AVE:     $display("Your GLOBAL_AVE layer is correct!");
            FC:             $display("Your FC layer is correct!");
        endcase
        // $write("",27);
        $display("Total cycle count = %0d", cycle_cnt);
        $display("Average cycle count per pattern = %0d", aver_cycle_cnt);
        $display("-------------------------PASS------------------------\n");
    end else begin
		$display("XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX");
		$display("X                                                 X");

        case(test_layer)
            INPUT:          $display("X   Error!!! Your Your INPUT         layer is wrong! X");
            CONV3_POOL_1:   $display("X   Error!!! Your Your CONV3_POOL_1  layer is wrong! X");
            CONV3_2:        $display("X   Error!!! Your Your CONV3_2       layer is wrong! X");
            CONV3_POOL_3:   $display("X   Error!!! Your Your CONV3_POOL_3  layer is wrong! X");
            RES1_CONV3_4:   $display("X   Error!!! Your Your RES1_CONV3_4  layer is wrong! X");
            RES1_CONV3_5:   $display("X   Error!!! Your Your RES1_CONV3_5  layer is wrong! X");  
            RES2_CONV3_6:   $display("X   Error!!! Your Your RES2_CONV3_6  layer is wrong! X");
            RES2_CONV3_7:   $display("X   Error!!! Your Your RES2_CONV3_7  layer is wrong! X");
            CONV3_POOL_8:   $display("X   Error!!! Your Your CONV3_POOL_8  layer is wrong! X");
            RES3_CONV3_9:   $display("X   Error!!! Your Your RES3_CONV3_9  layer is wrong! X");
            RES3_CONV3_10:  $display("X   Error!!! Your Your RES3_CONV3_10 layer is wrong! X");
            CONV3_POOL_11:  $display("X   Error!!! Your Your CONV3_POOL_11 layer is wrong! X");
            GLOBAL_AVE:     $display("X   Error!!! Your Your GLOBAL_AVE    layer is wrong! X");
            FC:             $display("X   Error!!! Your Your FC            layer is wrong! X");

        endcase

        $display("X         %3d patterns are failed... (T ~ T)      X", total_err_pat);
		$display("X                                                 X");
		$display("XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX");
        $display("Total cycle count = %0d", cycle_cnt);
        $display("Average cycle count per pattern = %0d", aver_cycle_cnt);          
    end

	// check if all patterns are simulated
	if((`PAT_L != 0) || (`PAT_U != `NUM_PAT-1)) begin
		$display("XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX");
		$display("X                                                                                                           X");
		$display("X   Warning!!! You only simulate Pattern No. %3d to No. %3d                                                 X", `PAT_L, `PAT_U);
		$display("X   There are total %3d patterns.                                                                           X", `NUM_PAT);
		$display("X   Remember to simulate all patterns and check if all are passed.                                          X");
		$display("X   The average cycle count C per pattern in the PI should be the result when all patterns are simulated.   X");
		$display("X                                                                                                           X");
		$display("XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX");
		$write("\n");
	end

    $finish;
end


task load_param;
    begin
        // conv3_pool_1
        $readmemb("param/conv1_weight.dat", conv3_pool_1_w);
        $readmemb("param/conv1_bias.dat", conv3_pool_1_b);
        // conv3_2
        $readmemb("param/conv2_weight.dat", conv3_2_w);
        $readmemb("param/conv2_bias.dat", conv3_2_b);
        // conv3_pool_3
        $readmemb("param/conv3_weight.dat", conv3_pool_3_w);
        $readmemb("param/conv3_bias.dat", conv3_pool_3_b);
        // res1_conv3_4
        $readmemb("param/res1a_branch2a_weight.dat", res1_conv3_4_w);
        $readmemb("param/res1a_branch2a_bias.dat", res1_conv3_4_b);
        // res1_conv3_5
        $readmemb("param/res1a_branch2b_weight.dat", res1_conv3_5_w);
        $readmemb("param/res1a_branch2b_bias.dat", res1_conv3_5_b);
        // res2_conv3_6 
        $readmemb("param/res2b_branch2a_weight.dat", res2_conv3_6_w);
        $readmemb("param/res2b_branch2a_bias.dat", res2_conv3_6_b);
        // res2_conv3_7
        $readmemb("param/res2b_branch2b_weight.dat", res2_conv3_7_w);
        $readmemb("param/res2b_branch2b_bias.dat", res2_conv3_7_b);
        // conv3_pool_8
        $readmemb("param/conv4_weight.dat", conv3_pool_8_w);
        $readmemb("param/conv4_bias.dat", conv3_pool_8_b);
        // res3_conv3_9
        $readmemb("param/res3b_branch2a_weight.dat", res3_conv3_9_w);
        $readmemb("param/res3b_branch2a_bias.dat", res3_conv3_9_b);
        // res3_conv3_10
        $readmemb("param/res3b_branch2b_weight.dat", res3_conv3_10_w);
        $readmemb("param/res3b_branch2b_bias.dat", res3_conv3_10_b);
        // conv3_pool_11
        $readmemb("param/conv5_weight.dat", conv3_pool_11_w);
        $readmemb("param/conv5_bias.dat", conv3_pool_11_b);
        // FC
        $readmemb("param/output_fc_weight.dat", fc_w);
        $readmemb("param/output_fc_bias.dat", fc_b);


        // store weights into sram ( use sram_2636x576b_weight )
        for(i=0; i<12 ;i=i+1) begin
            sram_2636x576b_weight.load_param(i, {conv3_pool_1_w[(i%3)*32+(i/3)*8],conv3_pool_1_w[1+(i%3)*32+(i/3)*8],conv3_pool_1_w[2+(i%3)*32+(i/3)*8],conv3_pool_1_w[3+(i%3)*32+(i/3)*8],conv3_pool_1_w[4+(i%3)*32+(i/3)*8],conv3_pool_1_w[5+(i%3)*32+(i/3)*8],conv3_pool_1_w[(6+i%3)*32+(i/3)*8],conv3_pool_1_w[7+(i%3)*32+(i/3)*8]});
        end


        for(i=0; i<128 ;i=i+1) begin
            sram_2636x576b_weight.load_param(i+12, {conv3_2_w[(i%32)*32+(i/32)*8],conv3_2_w[1+(i%32)*32+(i/32)*8],conv3_2_w[2+(i%32)*32+(i/32)*8],conv3_2_w[3+(i%32)*32+(i/32)*8],conv3_2_w[4+(i%32)*32+(i/32)*8],conv3_2_w[5+(i%32)*32+(i/32)*8],conv3_2_w[(6+i%32)*32+(i/32)*8],conv3_2_w[7+(i%32)*32+(i/32)*8]});
        end
        for(i=0; i<128 ;i=i+1) begin
            sram_2636x576b_weight.load_param(i+140, {conv3_pool_3_w[(i%32)*32+(i/32)*8],conv3_pool_3_w[1+(i%32)*32+(i/32)*8],conv3_pool_3_w[2+(i%32)*32+(i/32)*8],conv3_pool_3_w[3+(i%32)*32+(i/32)*8],conv3_pool_3_w[4+(i%32)*32+(i/32)*8],conv3_pool_3_w[5+(i%32)*32+(i/32)*8],conv3_pool_3_w[(6+i%32)*32+(i/32)*8],conv3_pool_3_w[7+(i%32)*32+(i/32)*8]});
        end
        for(i=0; i<128 ;i=i+1) begin
            sram_2636x576b_weight.load_param(i+268, {res1_conv3_4_w[(i%32)*32+(i/32)*8],res1_conv3_4_w[1+(i%32)*32+(i/32)*8],res1_conv3_4_w[2+(i%32)*32+(i/32)*8],res1_conv3_4_w[3+(i%32)*32+(i/32)*8],res1_conv3_4_w[4+(i%32)*32+(i/32)*8],res1_conv3_4_w[5+(i%32)*32+(i/32)*8],res1_conv3_4_w[(6+i%32)*32+(i/32)*8],res1_conv3_4_w[7+(i%32)*32+(i/32)*8]});
        end
        for(i=0; i<128 ;i=i+1) begin
            sram_2636x576b_weight.load_param(i+396, {res1_conv3_5_w[(i%32)*32+(i/32)*8],res1_conv3_5_w[1+(i%32)*32+(i/32)*8],res1_conv3_5_w[2+(i%32)*32+(i/32)*8],res1_conv3_5_w[3+(i%32)*32+(i/32)*8],res1_conv3_5_w[4+(i%32)*32+(i/32)*8],res1_conv3_5_w[5+(i%32)*32+(i/32)*8],res1_conv3_5_w[(6+i%32)*32+(i/32)*8],res1_conv3_5_w[7+(i%32)*32+(i/32)*8]});
        end
        for(i=0; i<128 ;i=i+1) begin
            sram_2636x576b_weight.load_param(i+524, {res2_conv3_6_w[(i%32)*32+(i/32)*8],res2_conv3_6_w[1+(i%32)*32+(i/32)*8],res2_conv3_6_w[2+(i%32)*32+(i/32)*8],res2_conv3_6_w[3+(i%32)*32+(i/32)*8],res2_conv3_6_w[4+(i%32)*32+(i/32)*8],res2_conv3_6_w[5+(i%32)*32+(i/32)*8],res2_conv3_6_w[(6+i%32)*32+(i/32)*8],res2_conv3_6_w[7+(i%32)*32+(i/32)*8]});
        end
        for(i=0; i<128 ;i=i+1) begin
            sram_2636x576b_weight.load_param(i+652, {res2_conv3_7_w[(i%32)*32+(i/32)*8],res2_conv3_7_w[1+(i%32)*32+(i/32)*8],res2_conv3_7_w[2+(i%32)*32+(i/32)*8],res2_conv3_7_w[3+(i%32)*32+(i/32)*8],res2_conv3_7_w[4+(i%32)*32+(i/32)*8],res2_conv3_7_w[5+(i%32)*32+(i/32)*8],res2_conv3_7_w[(6+i%32)*32+(i/32)*8],res2_conv3_7_w[7+(i%32)*32+(i/32)*8]});
        end

        for(i=0; i<256 ;i=i+1) begin
            sram_2636x576b_weight.load_param(i+780, {conv3_pool_8_w[(i%32)*64+(i/32)*8],conv3_pool_8_w[1+(i%32)*64+(i/32)*8],conv3_pool_8_w[2+(i%32)*64+(i/32)*8],conv3_pool_8_w[3+(i%32)*64+(i/32)*8],conv3_pool_8_w[4+(i%32)*64+(i/32)*8],conv3_pool_8_w[5+(i%32)*64+(i/32)*8],conv3_pool_8_w[(6+i%32)*64+(i/32)*8],conv3_pool_8_w[7+(i%32)*64+(i/32)*8]});
        end

        for(i=0; i<512 ;i=i+1) begin
            sram_2636x576b_weight.load_param(i+1036, {res3_conv3_9_w[(i%32)*32+(i/32)*8],res3_conv3_9_w[1+(i%32)*32+(i/32)*8],res3_conv3_9_w[2+(i%32)*32+(i/32)*8],res3_conv3_9_w[3+(i%32)*32+(i/32)*8],res3_conv3_9_w[4+(i%32)*32+(i/32)*8],res3_conv3_9_w[5+(i%32)*32+(i/32)*8],res3_conv3_9_w[(6+i%32)*32+(i/32)*8],res3_conv3_9_w[7+(i%32)*32+(i/32)*8]});
        end
        for(i=0; i<512 ;i=i+1) begin
            sram_2636x576b_weight.load_param(i+1548, {res3_conv3_10_w[(i%32)*32+(i/32)*8],res3_conv3_10_w[1+(i%32)*32+(i/32)*8],res3_conv3_10_w[2+(i%32)*32+(i/32)*8],res3_conv3_10_w[3+(i%32)*32+(i/32)*8],res3_conv3_10_w[4+(i%32)*32+(i/32)*8],res3_conv3_10_w[5+(i%32)*32+(i/32)*8],res3_conv3_10_w[(6+i%32)*32+(i/32)*8],res3_conv3_10_w[7+(i%32)*32+(i/32)*8]});
        end

        for(i=0; i<512 ;i=i+1) begin
            sram_2636x576b_weight.load_param(i+2060, {conv3_pool_11_w[(i%64)*64+(i/64)*8],conv3_pool_11_w[1+(i%64)*64+(i/64)*8],conv3_pool_11_w[2+(i%64)*64+(i/64)*8],conv3_pool_11_w[3+(i%64)*64+(i/64)*8],conv3_pool_11_w[4+(i%64)*64+(i/64)*8],conv3_pool_11_w[5+(i%64)*64+(i/64)*8],conv3_pool_11_w[(6+i%64)*64+(i/64)*8],conv3_pool_11_w[7+(i%64)*64+(i/64)*8]});
        end

        for(i=0; i<64 ;i=i+1) begin
            sram_2636x576b_weight.load_param(i+2572, fc_w[i]);
        end

        // store biases into sram
        for(i=0; i<4; i=i+1) begin
            sram_45x64b_bias.load_param(i, {conv3_pool_1_b[0+i*8],conv3_pool_1_b[1+i*8],conv3_pool_1_b[2+i*8],conv3_pool_1_b[3+i*8],conv3_pool_1_b[4+i*8],conv3_pool_1_b[5+i*8],conv3_pool_1_b[6+i*8],conv3_pool_1_b[7+i*8]});
        end

        for(i=0; i<4; i=i+1) begin
            sram_45x64b_bias.load_param(i+4, {conv3_2_b[0+i*8],conv3_2_b[1+i*8],conv3_2_b[2+i*8],conv3_2_b[3+i*8],conv3_2_b[4+i*8],conv3_2_b[5+i*8],conv3_2_b[6+i*8],conv3_2_b[7+i*8]});
        end
        for(i=0; i<4; i=i+1) begin
            sram_45x64b_bias.load_param(i+8, {conv3_pool_3_b[0+i*8],conv3_pool_3_b[1+i*8],conv3_pool_3_b[2+i*8],conv3_pool_3_b[3+i*8],conv3_pool_3_b[4+i*8],conv3_pool_3_b[5+i*8],conv3_pool_3_b[6+i*8],conv3_pool_3_b[7+i*8]});
        end
        for(i=0; i<4; i=i+1) begin
            sram_45x64b_bias.load_param(i+12, {res1_conv3_4_b[0+i*8],res1_conv3_4_b[1+i*8],res1_conv3_4_b[2+i*8],res1_conv3_4_b[3+i*8],res1_conv3_4_b[4+i*8],res1_conv3_4_b[5+i*8],res1_conv3_4_b[6+i*8],res1_conv3_4_b[7+i*8]});
        end
        for(i=0; i<4; i=i+1) begin
            sram_45x64b_bias.load_param(i+16, {res1_conv3_5_b[0+i*8],res1_conv3_5_b[1+i*8],res1_conv3_5_b[2+i*8],res1_conv3_5_b[3+i*8],res1_conv3_5_b[4+i*8],res1_conv3_5_b[5+i*8],res1_conv3_5_b[6+i*8],res1_conv3_5_b[7+i*8]});
        end
        for(i=0; i<4; i=i+1) begin
            sram_45x64b_bias.load_param(i+20, {res2_conv3_6_b[0+i*8],res2_conv3_6_b[1+i*8],res2_conv3_6_b[2+i*8],res2_conv3_6_b[3+i*8],res2_conv3_6_b[4+i*8],res2_conv3_6_b[5+i*8],res2_conv3_6_b[6+i*8],res2_conv3_6_b[7+i*8]});
        end
        for(i=0; i<4; i=i+1) begin
            sram_45x64b_bias.load_param(i+24, {res2_conv3_7_b[0+i*8],res2_conv3_7_b[1+i*8],res2_conv3_7_b[2+i*8],res2_conv3_7_b[3+i*8],res2_conv3_7_b[4+i*8],res2_conv3_7_b[5+i*8],res2_conv3_7_b[6+i*8],res2_conv3_7_b[7+i*8]});
        end

        for(i=0; i<8; i=i+1) begin
            sram_45x64b_bias.load_param(i+28, {conv3_pool_8_b[0+i*8],conv3_pool_8_b[1+i*8],conv3_pool_8_b[2+i*8],conv3_pool_8_b[3+i*8],conv3_pool_8_b[4+i*8],conv3_pool_8_b[5+i*8],conv3_pool_8_b[6+i*8],conv3_pool_8_b[7+i*8]});
        end

        for(i=0; i<8; i=i+1) begin
            sram_45x64b_bias.load_param(i+36, {res3_conv3_9_b[0+i*8],res3_conv3_9_b[1+i*8],res3_conv3_9_b[2+i*8],res3_conv3_9_b[3+i*8],res3_conv3_9_b[4+i*8],res3_conv3_9_b[5+i*8],res3_conv3_9_b[6+i*8],res3_conv3_9_b[7+i*8]});
        end
        for(i=0; i<8; i=i+1) begin
            sram_45x64b_bias.load_param(i+44, {res3_conv3_10_b[0+i*8],res3_conv3_10_b[1+i*8],res3_conv3_10_b[2+i*8],res3_conv3_10_b[3+i*8],res3_conv3_10_b[4+i*8],res3_conv3_10_b[5+i*8],res3_conv3_10_b[6+i*8],res3_conv3_10_b[7+i*8]});
        end

        for(i=0; i<8; i=i+1) begin
            sram_45x64b_bias.load_param(i+52, {conv3_pool_11_b[0+i*8],conv3_pool_11_b[1+i*8],conv3_pool_11_b[2+i*8],conv3_pool_11_b[3+i*8],conv3_pool_11_b[4+i*8],conv3_pool_11_b[5+i*8],conv3_pool_11_b[6+i*8],conv3_pool_11_b[7+i*8]});
        end

        sram_45x64b_bias.load_param(i+60, fc_b);

    end
endtask


task load_golden(
    input integer index
);
    reg [8-1:0] index_digit_2, index_digit_1, index_digit_0;
    begin
        input_a0_golden_file = "golden/000_input_a0.dat";
        input_a1_golden_file = "golden/000_input_a1.dat";
        input_a2_golden_file = "golden/000_input_a2.dat";
        input_a3_golden_file = "golden/000_input_a3.dat";
        conv3_pool_1_b0_golden_file = "golden/000_conv3_pool_1_b0.dat";
        conv3_pool_1_b1_golden_file = "golden/000_conv3_pool_1_b1.dat";
        conv3_pool_1_b2_golden_file = "golden/000_conv3_pool_1_b2.dat";
        conv3_pool_1_b3_golden_file = "golden/000_conv3_pool_1_b3.dat";
        conv3_2_a0_golden_file = "golden/000_conv3_2_a0.dat";
        conv3_2_a1_golden_file = "golden/000_conv3_2_a1.dat";
        conv3_2_a2_golden_file = "golden/000_conv3_2_a2.dat";
        conv3_2_a3_golden_file = "golden/000_conv3_2_a3.dat";
        conv3_pool_3_b0_golden_file = "golden/000_conv3_pool_3_b0.dat";
        conv3_pool_3_b1_golden_file = "golden/000_conv3_pool_3_b1.dat";
        conv3_pool_3_b2_golden_file = "golden/000_conv3_pool_3_b2.dat";
        conv3_pool_3_b3_golden_file = "golden/000_conv3_pool_3_b3.dat";

        res1_conv3_4_a0_golden_file = "golden/000_res1_conv3_4_a0.dat";
        res1_conv3_4_a1_golden_file = "golden/000_res1_conv3_4_a1.dat";
        res1_conv3_4_a2_golden_file = "golden/000_res1_conv3_4_a2.dat";
        res1_conv3_4_a3_golden_file = "golden/000_res1_conv3_4_a3.dat";
        res1_conv3_5_b0_golden_file = "golden/000_res1_conv3_5_b0.dat";
        res1_conv3_5_b1_golden_file = "golden/000_res1_conv3_5_b1.dat";
        res1_conv3_5_b2_golden_file = "golden/000_res1_conv3_5_b2.dat";
        res1_conv3_5_b3_golden_file = "golden/000_res1_conv3_5_b3.dat";
        res2_conv3_6_a0_golden_file = "golden/000_res2_conv3_6_a0.dat";
        res2_conv3_6_a1_golden_file = "golden/000_res2_conv3_6_a1.dat";
        res2_conv3_6_a2_golden_file = "golden/000_res2_conv3_6_a2.dat";
        res2_conv3_6_a3_golden_file = "golden/000_res2_conv3_6_a3.dat";
        res2_conv3_7_b0_golden_file = "golden/000_res2_conv3_7_b0.dat";
        res2_conv3_7_b1_golden_file = "golden/000_res2_conv3_7_b1.dat";
        res2_conv3_7_b2_golden_file = "golden/000_res2_conv3_7_b2.dat";
        res2_conv3_7_b3_golden_file = "golden/000_res2_conv3_7_b3.dat";

        conv3_pool_8_a0_golden_file = "golden/000_conv3_pool_8_a0.dat";
        conv3_pool_8_a1_golden_file = "golden/000_conv3_pool_8_a1.dat";
        conv3_pool_8_a2_golden_file = "golden/000_conv3_pool_8_a2.dat";
        conv3_pool_8_a3_golden_file = "golden/000_conv3_pool_8_a3.dat";

        res3_conv3_9_b0_golden_file = "golden/000_res3_conv3_9_b0.dat";
        res3_conv3_9_b1_golden_file = "golden/000_res3_conv3_9_b1.dat";
        res3_conv3_9_b2_golden_file = "golden/000_res3_conv3_9_b2.dat";
        res3_conv3_9_b3_golden_file = "golden/000_res3_conv3_9_b3.dat";
        res3_conv3_10_a0_golden_file = "golden/000_res3_conv3_10_a0.dat";
        res3_conv3_10_a1_golden_file = "golden/000_res3_conv3_10_a1.dat";
        res3_conv3_10_a2_golden_file = "golden/000_res3_conv3_10_a2.dat";
        res3_conv3_10_a3_golden_file = "golden/000_res3_conv3_10_a3.dat";

        conv3_pool_11_b0_golden_file = "golden/000_conv3_pool_11_b0.dat";
        conv3_pool_11_b1_golden_file = "golden/000_conv3_pool_11_b1.dat";
        conv3_pool_11_b2_golden_file = "golden/000_conv3_pool_11_b2.dat";
        conv3_pool_11_b3_golden_file = "golden/000_conv3_pool_11_b3.dat";

        // GLOBAL_AVE
        global_ave_a0_golden_file = "golden/000_global_ave.dat";
        // FC
        fc_golden_file = "golden/000_fc.dat";

        index_digit_2 = (index/100);
        index_digit_1 = (index%100)/10;
        index_digit_0 = (index%10);

        input_a0_golden_file[13*8+:`PAT_NAME_LENGTH*8] = {index_digit_2, index_digit_1, index_digit_0};
        input_a1_golden_file[13*8+:`PAT_NAME_LENGTH*8] = {index_digit_2, index_digit_1, index_digit_0};
        input_a2_golden_file[13*8+:`PAT_NAME_LENGTH*8] = {index_digit_2, index_digit_1, index_digit_0};
        input_a3_golden_file[13*8+:`PAT_NAME_LENGTH*8] = {index_digit_2, index_digit_1, index_digit_0};
        conv3_pool_1_b0_golden_file[20*8+:`PAT_NAME_LENGTH*8] = {index_digit_2, index_digit_1, index_digit_0};
        conv3_pool_1_b1_golden_file[20*8+:`PAT_NAME_LENGTH*8] = {index_digit_2, index_digit_1, index_digit_0};
        conv3_pool_1_b2_golden_file[20*8+:`PAT_NAME_LENGTH*8] = {index_digit_2, index_digit_1, index_digit_0};
        conv3_pool_1_b3_golden_file[20*8+:`PAT_NAME_LENGTH*8] = {index_digit_2, index_digit_1, index_digit_0};
        conv3_2_a0_golden_file[15*8+:`PAT_NAME_LENGTH*8] = {index_digit_2, index_digit_1, index_digit_0};
        conv3_2_a1_golden_file[15*8+:`PAT_NAME_LENGTH*8] = {index_digit_2, index_digit_1, index_digit_0};
        conv3_2_a2_golden_file[15*8+:`PAT_NAME_LENGTH*8] = {index_digit_2, index_digit_1, index_digit_0};
        conv3_2_a3_golden_file[15*8+:`PAT_NAME_LENGTH*8] = {index_digit_2, index_digit_1, index_digit_0};
        conv3_pool_3_b0_golden_file[20*8+:`PAT_NAME_LENGTH*8] = {index_digit_2, index_digit_1, index_digit_0};
        conv3_pool_3_b1_golden_file[20*8+:`PAT_NAME_LENGTH*8] = {index_digit_2, index_digit_1, index_digit_0};
        conv3_pool_3_b2_golden_file[20*8+:`PAT_NAME_LENGTH*8] = {index_digit_2, index_digit_1, index_digit_0};
        conv3_pool_3_b3_golden_file[20*8+:`PAT_NAME_LENGTH*8] = {index_digit_2, index_digit_1, index_digit_0};

        res1_conv3_4_a0_golden_file[20*8+:`PAT_NAME_LENGTH*8] = {index_digit_2, index_digit_1, index_digit_0};
        res1_conv3_4_a1_golden_file[20*8+:`PAT_NAME_LENGTH*8] = {index_digit_2, index_digit_1, index_digit_0};
        res1_conv3_4_a2_golden_file[20*8+:`PAT_NAME_LENGTH*8] = {index_digit_2, index_digit_1, index_digit_0};
        res1_conv3_4_a3_golden_file[20*8+:`PAT_NAME_LENGTH*8] = {index_digit_2, index_digit_1, index_digit_0};
        res1_conv3_5_b0_golden_file[20*8+:`PAT_NAME_LENGTH*8] = {index_digit_2, index_digit_1, index_digit_0};
        res1_conv3_5_b1_golden_file[20*8+:`PAT_NAME_LENGTH*8] = {index_digit_2, index_digit_1, index_digit_0};
        res1_conv3_5_b2_golden_file[20*8+:`PAT_NAME_LENGTH*8] = {index_digit_2, index_digit_1, index_digit_0};
        res1_conv3_5_b3_golden_file[20*8+:`PAT_NAME_LENGTH*8] = {index_digit_2, index_digit_1, index_digit_0};
        res2_conv3_6_a0_golden_file[20*8+:`PAT_NAME_LENGTH*8] = {index_digit_2, index_digit_1, index_digit_0};
        res2_conv3_6_a1_golden_file[20*8+:`PAT_NAME_LENGTH*8] = {index_digit_2, index_digit_1, index_digit_0};
        res2_conv3_6_a2_golden_file[20*8+:`PAT_NAME_LENGTH*8] = {index_digit_2, index_digit_1, index_digit_0};
        res2_conv3_6_a3_golden_file[20*8+:`PAT_NAME_LENGTH*8] = {index_digit_2, index_digit_1, index_digit_0};
        res2_conv3_7_b0_golden_file[20*8+:`PAT_NAME_LENGTH*8] = {index_digit_2, index_digit_1, index_digit_0};
        res2_conv3_7_b1_golden_file[20*8+:`PAT_NAME_LENGTH*8] = {index_digit_2, index_digit_1, index_digit_0};
        res2_conv3_7_b2_golden_file[20*8+:`PAT_NAME_LENGTH*8] = {index_digit_2, index_digit_1, index_digit_0};
        res2_conv3_7_b3_golden_file[20*8+:`PAT_NAME_LENGTH*8] = {index_digit_2, index_digit_1, index_digit_0};

        conv3_pool_8_a0_golden_file[20*8+:`PAT_NAME_LENGTH*8] = {index_digit_2, index_digit_1, index_digit_0};
        conv3_pool_8_a1_golden_file[20*8+:`PAT_NAME_LENGTH*8] = {index_digit_2, index_digit_1, index_digit_0};
        conv3_pool_8_a2_golden_file[20*8+:`PAT_NAME_LENGTH*8] = {index_digit_2, index_digit_1, index_digit_0};
        conv3_pool_8_a3_golden_file[20*8+:`PAT_NAME_LENGTH*8] = {index_digit_2, index_digit_1, index_digit_0};

        res3_conv3_9_b0_golden_file[20*8+:`PAT_NAME_LENGTH*8] = {index_digit_2, index_digit_1, index_digit_0};
        res3_conv3_9_b1_golden_file[20*8+:`PAT_NAME_LENGTH*8] = {index_digit_2, index_digit_1, index_digit_0};
        res3_conv3_9_b2_golden_file[20*8+:`PAT_NAME_LENGTH*8] = {index_digit_2, index_digit_1, index_digit_0};
        res3_conv3_9_b3_golden_file[20*8+:`PAT_NAME_LENGTH*8] = {index_digit_2, index_digit_1, index_digit_0};
        res3_conv3_10_a0_golden_file[21*8+:`PAT_NAME_LENGTH*8] = {index_digit_2, index_digit_1, index_digit_0};
        res3_conv3_10_a1_golden_file[21*8+:`PAT_NAME_LENGTH*8] = {index_digit_2, index_digit_1, index_digit_0};
        res3_conv3_10_a2_golden_file[21*8+:`PAT_NAME_LENGTH*8] = {index_digit_2, index_digit_1, index_digit_0};
        res3_conv3_10_a3_golden_file[21*8+:`PAT_NAME_LENGTH*8] = {index_digit_2, index_digit_1, index_digit_0};

        conv3_pool_11_b0_golden_file[21*8+:`PAT_NAME_LENGTH*8] = {index_digit_2, index_digit_1, index_digit_0};
        conv3_pool_11_b1_golden_file[21*8+:`PAT_NAME_LENGTH*8] = {index_digit_2, index_digit_1, index_digit_0};
        conv3_pool_11_b2_golden_file[21*8+:`PAT_NAME_LENGTH*8] = {index_digit_2, index_digit_1, index_digit_0};
        conv3_pool_11_b3_golden_file[21*8+:`PAT_NAME_LENGTH*8] = {index_digit_2, index_digit_1, index_digit_0};

        // GLOBAL_AVE
        global_ave_a0_golden_file[15*8+:`PAT_NAME_LENGTH*8] = {index_digit_2, index_digit_1, index_digit_0};
        // FC
        fc_golden_file[7*8+:`PAT_NAME_LENGTH*8] = {index_digit_2, index_digit_1, index_digit_0};


        $readmemb(input_a0_golden_file, input_ans_a0);
        $readmemb(input_a1_golden_file, input_ans_a1);
        $readmemb(input_a2_golden_file, input_ans_a2);
        $readmemb(input_a3_golden_file, input_ans_a3);
        $readmemb(conv3_pool_1_b0_golden_file, conv3_pool_1_ans_b0);
        $readmemb(conv3_pool_1_b1_golden_file, conv3_pool_1_ans_b1);
        $readmemb(conv3_pool_1_b2_golden_file, conv3_pool_1_ans_b2);
        $readmemb(conv3_pool_1_b3_golden_file, conv3_pool_1_ans_b3);
        $readmemb(conv3_2_a0_golden_file, conv3_2_ans_a0);
        $readmemb(conv3_2_a1_golden_file, conv3_2_ans_a1);
        $readmemb(conv3_2_a2_golden_file, conv3_2_ans_a2);
        $readmemb(conv3_2_a3_golden_file, conv3_2_ans_a3);
        $readmemb(conv3_pool_3_b0_golden_file, conv3_pool_3_ans_b0);
        $readmemb(conv3_pool_3_b1_golden_file, conv3_pool_3_ans_b1);
        $readmemb(conv3_pool_3_b2_golden_file, conv3_pool_3_ans_b2);
        $readmemb(conv3_pool_3_b3_golden_file, conv3_pool_3_ans_b3);

        $readmemb(res1_conv3_4_a0_golden_file, res1_conv3_4_ans_a0);
        $readmemb(res1_conv3_4_a1_golden_file, res1_conv3_4_ans_a1);
        $readmemb(res1_conv3_4_a2_golden_file, res1_conv3_4_ans_a2);
        $readmemb(res1_conv3_4_a3_golden_file, res1_conv3_4_ans_a3);
        $readmemb(res1_conv3_5_b0_golden_file, res1_conv3_5_ans_b0);
        $readmemb(res1_conv3_5_b1_golden_file, res1_conv3_5_ans_b1);
        $readmemb(res1_conv3_5_b2_golden_file, res1_conv3_5_ans_b2);
        $readmemb(res1_conv3_5_b3_golden_file, res1_conv3_5_ans_b3);
        $readmemb(res2_conv3_6_a0_golden_file, res2_conv3_6_ans_a0);
        $readmemb(res2_conv3_6_a1_golden_file, res2_conv3_6_ans_a1);
        $readmemb(res2_conv3_6_a2_golden_file, res2_conv3_6_ans_a2);
        $readmemb(res2_conv3_6_a3_golden_file, res2_conv3_6_ans_a3);
        $readmemb(res2_conv3_7_b0_golden_file, res2_conv3_7_ans_b0);
        $readmemb(res2_conv3_7_b1_golden_file, res2_conv3_7_ans_b1);
        $readmemb(res2_conv3_7_b2_golden_file, res2_conv3_7_ans_b2);
        $readmemb(res2_conv3_7_b3_golden_file, res2_conv3_7_ans_b3);

        $readmemb(conv3_pool_8_a0_golden_file, conv3_pool_8_ans_a0);
        $readmemb(conv3_pool_8_a1_golden_file, conv3_pool_8_ans_a1);
        $readmemb(conv3_pool_8_a2_golden_file, conv3_pool_8_ans_a2);
        $readmemb(conv3_pool_8_a3_golden_file, conv3_pool_8_ans_a3);

        $readmemb(res3_conv3_9_b0_golden_file, res3_conv3_9_ans_b0);
        $readmemb(res3_conv3_9_b1_golden_file, res3_conv3_9_ans_b1);
        $readmemb(res3_conv3_9_b2_golden_file, res3_conv3_9_ans_b2);
        $readmemb(res3_conv3_9_b3_golden_file, res3_conv3_9_ans_b3);
        $readmemb(res3_conv3_10_a0_golden_file, res3_conv3_10_ans_a0);
        $readmemb(res3_conv3_10_a1_golden_file, res3_conv3_10_ans_a1);
        $readmemb(res3_conv3_10_a2_golden_file, res3_conv3_10_ans_a2);
        $readmemb(res3_conv3_10_a3_golden_file, res3_conv3_10_ans_a3);

        $readmemb(conv3_pool_11_b0_golden_file, conv3_pool_11_ans_b0);
        $readmemb(conv3_pool_11_b1_golden_file, conv3_pool_11_ans_b1);
        $readmemb(conv3_pool_11_b2_golden_file, conv3_pool_11_ans_b2);
        $readmemb(conv3_pool_11_b3_golden_file, conv3_pool_11_ans_b3);

        // GLOBAL_AVE
        $readmemb(global_ave_a0_golden_file, global_ave_ans_a0);
        // FC
        $readmemb(fc_golden_file, fc_ans);

        // store unshuffled image into sram A
        // a0
        for(i=0; i<9577 ;i=i+1)begin
            sram_207936x48b_a0.load_act(i, input_ans_a0[i]);
        end
        // a1
        for(i=0; i<9577 ;i=i+1)begin
            sram_207936x48b_a1.load_act(i, input_ans_a1[i]);
        end
        // a2
        for(i=0; i<9577 ;i=i+1)begin
            sram_207936x48b_a2.load_act(i, input_ans_a2[i]);
        end
        // a3
        for(i=0; i<9577 ;i=i+1)begin
            sram_207936x48b_a3.load_act(i, input_ans_a3[i]);
        end
    end
endtask

task display_error(
input [2:0] which_sram, // A0 ~ B3 --> 0 ~ 7 
input [4-1:0] layer,    // we hawe 14 layers
input integer addr,
input integer ans_offset
);
    begin
        case(which_sram)
            A0: begin
                $write("Your answer is \n%d (ch0)\n%d (ch1)\n%d (ch2)\n%d (ch3)\n", 
                    $signed(sram_207936x48b_a0.mem[addr][47:36]),   $signed(sram_207936x48b_a0.mem[addr][35:24]),
                    $signed(sram_207936x48b_a0.mem[addr][23:12]),   $signed(sram_207936x48b_a0.mem[addr][11:0]));
                if(layer == INPUT) begin
                    $write("But the golden answer is \n%d (ch0)\n%d (ch1)\n%d (ch2)\n%d (ch3)\n\n", 
                        $signed(input_ans_a0[addr-ans_offset][47:36]),   $signed(input_ans_a0[addr-ans_offset][35:24]),
                        $signed(input_ans_a0[addr-ans_offset][23:12]),   $signed(input_ans_a0[addr-ans_offset][11:0]));
                end else if(layer == CONV3_2) begin
                    $write("But the golden answer is \n%d  (ch0)\n%d  (ch1)\n%d  (ch2)\n%d  (ch3)\n\n", 
                        $signed(conv3_2_ans_a0[addr-ans_offset][47:36]),   $signed(conv3_2_ans_a0[addr-ans_offset][35:24]),
                        $signed(conv3_2_ans_a0[addr-ans_offset][23:12]),   $signed(conv3_2_ans_a0[addr-ans_offset][11:0]));
                end else if(layer == RES1_CONV3_4)begin
                    $write("But the golden answer is \n%d (ch0)\n%d (ch1)\n%d (ch2)\n%d (ch3)\n\n", 
                        $signed(res1_conv3_4_ans_a0[addr-ans_offset][47:36]),   $signed(res1_conv3_4_ans_a0[addr-ans_offset][35:24]),
                        $signed(res1_conv3_4_ans_a0[addr-ans_offset][23:12]),   $signed(res1_conv3_4_ans_a0[addr-ans_offset][11:0]));
                end else if(layer == RES2_CONV3_6)begin
                    $write("But the golden answer is \n%d (ch0)\n%d (ch1)\n%d (ch2)\n%d (ch3)\n\n", 
                        $signed(res2_conv3_6_ans_a0[addr-ans_offset][47:36]),   $signed(res2_conv3_6_ans_a0[addr-ans_offset][35:24]),
                        $signed(res2_conv3_6_ans_a0[addr-ans_offset][23:12]),   $signed(res2_conv3_6_ans_a0[addr-ans_offset][11:0]));
                end else if(layer == CONV3_POOL_8)begin
                    $write("But the golden answer is \n%d (ch0)\n%d (ch1)\n%d (ch2)\n%d (ch3)\n\n", 
                        $signed(conv3_pool_8_ans_a0[addr-ans_offset][47:36]),   $signed(conv3_pool_8_ans_a0[addr-ans_offset][35:24]),
                        $signed(conv3_pool_8_ans_a0[addr-ans_offset][23:12]),   $signed(conv3_pool_8_ans_a0[addr-ans_offset][11:0]));
                end else if(layer == RES3_CONV3_10)begin
                    $write("But the golden answer is \n%d (ch0)\n%d (ch1)\n%d (ch2)\n%d (ch3)\n\n", 
                        $signed(res3_conv3_10_ans_a0[addr-ans_offset][47:36]),   $signed(res3_conv3_10_ans_a0[addr-ans_offset][35:24]),
                        $signed(res3_conv3_10_ans_a0[addr-ans_offset][23:12]),   $signed(res3_conv3_10_ans_a0[addr-ans_offset][11:0]));
                end else if(layer == GLOBAL_AVE)begin
                    $write("But the golden answer is \n%d (ch0)\n%d (ch1)\n%d (ch2)\n%d (ch3)\n\n", 
                        $signed(global_ave_ans_a0[addr-ans_offset][47:36]),   $signed(global_ave_ans_a0[addr-ans_offset][35:24]),
                        $signed(global_ave_ans_a0[addr-ans_offset][23:12]),   $signed(global_ave_ans_a0[addr-ans_offset][11:0]));
                end
            end
            A1: begin
                $write("Your answer is \n%d (ch0)\n%d (ch1)\n%d (ch2)\n%d (ch3)\n", 
                    $signed(sram_207936x48b_a1.mem[addr][47:36]),   $signed(sram_207936x48b_a1.mem[addr][35:24]),
                    $signed(sram_207936x48b_a1.mem[addr][23:12]),   $signed(sram_207936x48b_a1.mem[addr][11:0]));
                if(layer == INPUT) begin
                    $write("But the golden answer is \n%d (ch0)\n%d (ch1)\n%d (ch2)\n%d (ch3)\n\n", 
                        $signed(input_ans_a1[addr-ans_offset][47:36]),   $signed(input_ans_a1[addr-ans_offset][35:24]),
                        $signed(input_ans_a1[addr-ans_offset][23:12]),   $signed(input_ans_a1[addr-ans_offset][11:0]));
                end else if(layer == CONV3_2) begin
                    $write("But the golden answer is \n%d  (ch0)\n%d  (ch1)\n%d  (ch2)\n%d  (ch3)\n\n", 
                        $signed(conv3_2_ans_a1[addr-ans_offset][47:36]),   $signed(conv3_2_ans_a1[addr-ans_offset][35:24]),
                        $signed(conv3_2_ans_a1[addr-ans_offset][23:12]),   $signed(conv3_2_ans_a1[addr-ans_offset][11:0]));
                end else if(layer == RES1_CONV3_4)begin
                    $write("But the golden answer is \n%d (ch0)\n%d (ch1)\n%d (ch2)\n%d (ch3)\n\n", 
                        $signed(res1_conv3_4_ans_a1[addr-ans_offset][47:36]),   $signed(res1_conv3_4_ans_a1[addr-ans_offset][35:24]),
                        $signed(res1_conv3_4_ans_a1[addr-ans_offset][23:12]),   $signed(res1_conv3_4_ans_a1[addr-ans_offset][11:0]));
                end else if(layer == RES2_CONV3_6)begin
                    $write("But the golden answer is \n%d (ch0)\n%d (ch1)\n%d (ch2)\n%d (ch3)\n\n", 
                        $signed(res2_conv3_6_ans_a1[addr-ans_offset][47:36]),   $signed(res2_conv3_6_ans_a1[addr-ans_offset][35:24]),
                        $signed(res2_conv3_6_ans_a1[addr-ans_offset][23:12]),   $signed(res2_conv3_6_ans_a1[addr-ans_offset][11:0]));
                end else if(layer == CONV3_POOL_8)begin
                    $write("But the golden answer is \n%d (ch0)\n%d (ch1)\n%d (ch2)\n%d (ch3)\n\n", 
                        $signed(conv3_pool_8_ans_a1[addr-ans_offset][47:36]),   $signed(conv3_pool_8_ans_a1[addr-ans_offset][35:24]),
                        $signed(conv3_pool_8_ans_a1[addr-ans_offset][23:12]),   $signed(conv3_pool_8_ans_a1[addr-ans_offset][11:0]));
                end else if(layer == RES3_CONV3_10)begin
                    $write("But the golden answer is \n%d (ch0)\n%d (ch1)\n%d (ch2)\n%d (ch3)\n\n", 
                        $signed(res3_conv3_10_ans_a1[addr-ans_offset][47:36]),   $signed(res3_conv3_10_ans_a1[addr-ans_offset][35:24]),
                        $signed(res3_conv3_10_ans_a1[addr-ans_offset][23:12]),   $signed(res3_conv3_10_ans_a1[addr-ans_offset][11:0]));
                end
            end
            A2: begin
                $write("Your answer is \n%d (ch0)\n%d (ch1)\n%d (ch2)\n%d (ch3)\n", 
                    $signed(sram_207936x48b_a2.mem[addr][47:36]),   $signed(sram_207936x48b_a2.mem[addr][35:24]),
                    $signed(sram_207936x48b_a2.mem[addr][23:12]),   $signed(sram_207936x48b_a2.mem[addr][11:0]));
                if(layer == INPUT) begin
                    $write("But the golden answer is \n%d (ch0)\n%d (ch1)\n%d (ch2)\n%d (ch3)\n\n", 
                        $signed(input_ans_a1[addr-ans_offset][47:36]),   $signed(input_ans_a2[addr-ans_offset][35:24]),
                        $signed(input_ans_a1[addr-ans_offset][23:12]),   $signed(input_ans_a2[addr-ans_offset][11:0]));
                end else if(layer == CONV3_2) begin
                    $write("But the golden answer is \n%d  (ch0)\n%d  (ch1)\n%d  (ch2)\n%d  (ch3)\n\n", 
                        $signed(conv3_2_ans_a2[addr-ans_offset][47:36]),   $signed(conv3_2_ans_a2[addr-ans_offset][35:24]),
                        $signed(conv3_2_ans_a2[addr-ans_offset][23:12]),   $signed(conv3_2_ans_a2[addr-ans_offset][11:0]));
                end else if(layer == RES1_CONV3_4)begin
                    $write("But the golden answer is \n%d (ch0)\n%d (ch1)\n%d (ch2)\n%d (ch3)\n\n", 
                        $signed(res1_conv3_4_ans_a2[addr-ans_offset][47:36]),   $signed(res1_conv3_4_ans_a2[addr-ans_offset][35:24]),
                        $signed(res1_conv3_4_ans_a2[addr-ans_offset][23:12]),   $signed(res1_conv3_4_ans_a2[addr-ans_offset][11:0]));
                end else if(layer == RES2_CONV3_6)begin
                    $write("But the golden answer is \n%d (ch0)\n%d (ch1)\n%d (ch2)\n%d (ch3)\n\n", 
                        $signed(res2_conv3_6_ans_a2[addr-ans_offset][47:36]),   $signed(res2_conv3_6_ans_a2[addr-ans_offset][35:24]),
                        $signed(res2_conv3_6_ans_a2[addr-ans_offset][23:12]),   $signed(res2_conv3_6_ans_a2[addr-ans_offset][11:0]));
                end else if(layer == CONV3_POOL_8)begin
                    $write("But the golden answer is \n%d (ch0)\n%d (ch1)\n%d (ch2)\n%d (ch3)\n\n", 
                        $signed(conv3_pool_8_ans_a2[addr-ans_offset][47:36]),   $signed(conv3_pool_8_ans_a2[addr-ans_offset][35:24]),
                        $signed(conv3_pool_8_ans_a2[addr-ans_offset][23:12]),   $signed(conv3_pool_8_ans_a2[addr-ans_offset][11:0]));
                end else if(layer == RES3_CONV3_10)begin
                    $write("But the golden answer is \n%d (ch0)\n%d (ch1)\n%d (ch2)\n%d (ch3)\n\n", 
                        $signed(res3_conv3_10_ans_a2[addr-ans_offset][47:36]),   $signed(res3_conv3_10_ans_a2[addr-ans_offset][35:24]),
                        $signed(res3_conv3_10_ans_a2[addr-ans_offset][23:12]),   $signed(res3_conv3_10_ans_a2[addr-ans_offset][11:0]));
                end
            end
            A3: begin
                $write("Your answer is \n%d (ch0)\n%d (ch1)\n%d (ch2)\n%d (ch3)\n", 
                    $signed(sram_207936x48b_a3.mem[addr][47:36]),   $signed(sram_207936x48b_a3.mem[addr][35:24]),
                    $signed(sram_207936x48b_a3.mem[addr][23:12]),   $signed(sram_207936x48b_a3.mem[addr][11:0]));
                if(layer == INPUT) begin
                    $write("But the golden answer is \n%d (ch0)\n%d (ch1)\n%d (ch2)\n%d (ch3)\n\n", 
                        $signed(input_ans_a3[addr-ans_offset][47:36]),   $signed(input_ans_a3[addr-ans_offset][35:24]),
                        $signed(input_ans_a3[addr-ans_offset][23:12]),   $signed(input_ans_a3[addr-ans_offset][11:0]));
                end else if(layer == CONV3_2) begin
                    $write("But the golden answer is \n%d  (ch0)\n%d  (ch1)\n%d  (ch2)\n%d  (ch3)\n\n", 
                        $signed(conv3_2_ans_a3[addr-ans_offset][47:36]),   $signed(conv3_2_ans_a3[addr-ans_offset][35:24]),
                        $signed(conv3_2_ans_a3[addr-ans_offset][23:12]),   $signed(conv3_2_ans_a3[addr-ans_offset][11:0]));
                end else if(layer == RES1_CONV3_4)begin
                    $write("But the golden answer is \n%d (ch0)\n%d (ch1)\n%d (ch2)\n%d (ch3)\n\n", 
                        $signed(res1_conv3_4_ans_a3[addr-ans_offset][47:36]),   $signed(res1_conv3_4_ans_a3[addr-ans_offset][35:24]),
                        $signed(res1_conv3_4_ans_a3[addr-ans_offset][23:12]),   $signed(res1_conv3_4_ans_a3[addr-ans_offset][11:0]));
                end else if(layer == RES2_CONV3_6)begin
                    $write("But the golden answer is \n%d (ch0)\n%d (ch1)\n%d (ch2)\n%d (ch3)\n\n", 
                        $signed(res2_conv3_6_ans_a3[addr-ans_offset][47:36]),   $signed(res2_conv3_6_ans_a3[addr-ans_offset][35:24]),
                        $signed(res2_conv3_6_ans_a3[addr-ans_offset][23:12]),   $signed(res2_conv3_6_ans_a3[addr-ans_offset][11:0]));
                end else if(layer == CONV3_POOL_8)begin
                    $write("But the golden answer is \n%d (ch0)\n%d (ch1)\n%d (ch2)\n%d (ch3)\n\n", 
                        $signed(conv3_pool_8_ans_a3[addr-ans_offset][47:36]),   $signed(conv3_pool_8_ans_a3[addr-ans_offset][35:24]),
                        $signed(conv3_pool_8_ans_a3[addr-ans_offset][23:12]),   $signed(conv3_pool_8_ans_a3[addr-ans_offset][11:0]));
                end else if(layer == RES3_CONV3_10)begin
                    $write("But the golden answer is \n%d (ch0)\n%d (ch1)\n%d (ch2)\n%d (ch3)\n\n", 
                        $signed(res3_conv3_10_ans_a3[addr-ans_offset][47:36]),   $signed(res3_conv3_10_ans_a3[addr-ans_offset][35:24]),
                        $signed(res3_conv3_10_ans_a3[addr-ans_offset][23:12]),   $signed(res3_conv3_10_ans_a3[addr-ans_offset][11:0]));
                end
            end
            B0: begin
                $write("Your answer is \n%d (ch0)\n%d (ch1)\n%d (ch2)\n%d (ch3)\n", 
                    $signed(sram_50176x48b_b0.mem[addr][47:36]),   $signed(sram_50176x48b_b0.mem[addr][35:24]),
                    $signed(sram_50176x48b_b0.mem[addr][23:12]),   $signed(sram_50176x48b_b0.mem[addr][11:0]));
                if(layer == CONV3_POOL_1) begin
                    $write("But the golden answer is \n%d (ch0)\n%d (ch1)\n%d (ch2)\n%d (ch3)\n\n", 
                        $signed(conv3_pool_1_ans_b0[addr-ans_offset][47:36]),   $signed(conv3_pool_1_ans_b0[addr-ans_offset][35:24]),
                        $signed(conv3_pool_1_ans_b0[addr-ans_offset][23:12]),   $signed(conv3_pool_1_ans_b0[addr-ans_offset][11:0]));
                end else if(layer == CONV3_POOL_3) begin
                    $write("But the golden answer is \n%d  (ch0)\n%d  (ch1)\n%d  (ch2)\n%d  (ch3)\n\n", 
                        $signed(conv3_pool_3_ans_b0[addr-ans_offset][47:36]),   $signed(conv3_pool_3_ans_b0[addr-ans_offset][35:24]),
                        $signed(conv3_pool_3_ans_b0[addr-ans_offset][23:12]),   $signed(conv3_pool_3_ans_b0[addr-ans_offset][11:0]));
                end else if(layer == RES1_CONV3_5)begin
                    $write("But the golden answer is \n%d (ch0)\n%d (ch1)\n%d (ch2)\n%d (ch3)\n\n", 
                        $signed(res1_conv3_5_ans_b0[addr-ans_offset][47:36]),   $signed(res1_conv3_5_ans_b0[addr-ans_offset][35:24]),
                        $signed(res1_conv3_5_ans_b0[addr-ans_offset][23:12]),   $signed(res1_conv3_5_ans_b0[addr-ans_offset][11:0]));
                end else if(layer == RES2_CONV3_7)begin
                    $write("But the golden answer is \n%d (ch0)\n%d (ch1)\n%d (ch2)\n%d (ch3)\n\n", 
                        $signed(res2_conv3_7_ans_b0[addr-ans_offset][47:36]),   $signed(res2_conv3_7_ans_b0[addr-ans_offset][35:24]),
                        $signed(res2_conv3_7_ans_b0[addr-ans_offset][23:12]),   $signed(res2_conv3_7_ans_b0[addr-ans_offset][11:0]));
                end else if(layer == RES3_CONV3_9)begin
                    $write("But the golden answer is \n%d (ch0)\n%d (ch1)\n%d (ch2)\n%d (ch3)\n\n", 
                        $signed(res3_conv3_9_ans_b0[addr-ans_offset][47:36]),   $signed(res3_conv3_9_ans_b0[addr-ans_offset][35:24]),
                        $signed(res3_conv3_9_ans_b0[addr-ans_offset][23:12]),   $signed(res3_conv3_9_ans_b0[addr-ans_offset][11:0]));
                end else if(layer == CONV3_POOL_11)begin
                    $write("But the golden answer is \n%d (ch0)\n%d (ch1)\n%d (ch2)\n%d (ch3)\n\n", 
                        $signed(conv3_pool_11_ans_b0[addr-ans_offset][47:36]),   $signed(conv3_pool_11_ans_b0[addr-ans_offset][35:24]),
                        $signed(conv3_pool_11_ans_b0[addr-ans_offset][23:12]),   $signed(conv3_pool_11_ans_b0[addr-ans_offset][11:0]));
                end else if(layer == FC)begin
                    $write("But the golden answer is \n%d (ch0)\n%d (ch1)\n%d (ch2)\n%d (ch3)\n\n", 
                        $signed(fc_ans[addr-ans_offset][47:36]),   $signed(fc_ans[addr-ans_offset][35:24]),
                        $signed(fc_ans[addr-ans_offset][23:12]),   $signed(fc_ans[addr-ans_offset][11:0]));
                end
            end
            B1: begin
                $write("Your answer is \n%d (ch0)\n%d (ch1)\n%d (ch2)\n%d (ch3)\n", 
                    $signed(sram_50176x48b_b1.mem[addr][47:36]),   $signed(sram_50176x48b_b1.mem[addr][35:24]),
                    $signed(sram_50176x48b_b1.mem[addr][23:12]),   $signed(sram_50176x48b_b1.mem[addr][11:0]));
                if(layer == CONV3_POOL_1) begin
                    $write("But the golden answer is \n%d (ch0)\n%d (ch1)\n%d (ch2)\n%d (ch3)\n\n", 
                        $signed(conv3_pool_1_ans_b1[addr-ans_offset][47:36]),   $signed(conv3_pool_1_ans_b1[addr-ans_offset][35:24]),
                        $signed(conv3_pool_1_ans_b1[addr-ans_offset][23:12]),   $signed(conv3_pool_1_ans_b1[addr-ans_offset][11:0]));
                end else if(layer == CONV3_POOL_3) begin
                    $write("But the golden answer is \n%d  (ch0)\n%d  (ch1)\n%d  (ch2)\n%d  (ch3)\n\n", 
                        $signed(conv3_pool_3_ans_b1[addr-ans_offset][47:36]),   $signed(conv3_pool_3_ans_b1[addr-ans_offset][35:24]),
                        $signed(conv3_pool_3_ans_b1[addr-ans_offset][23:12]),   $signed(conv3_pool_3_ans_b1[addr-ans_offset][11:0]));
                end else if(layer == RES1_CONV3_5)begin
                    $write("But the golden answer is \n%d (ch0)\n%d (ch1)\n%d (ch2)\n%d (ch3)\n\n", 
                        $signed(res1_conv3_5_ans_b1[addr-ans_offset][47:36]),   $signed(res1_conv3_5_ans_b1[addr-ans_offset][35:24]),
                        $signed(res1_conv3_5_ans_b1[addr-ans_offset][23:12]),   $signed(res1_conv3_5_ans_b1[addr-ans_offset][11:0]));
                end else if(layer == RES2_CONV3_7)begin
                    $write("But the golden answer is \n%d (ch0)\n%d (ch1)\n%d (ch2)\n%d (ch3)\n\n", 
                        $signed(res2_conv3_7_ans_b1[addr-ans_offset][47:36]),   $signed(res2_conv3_7_ans_b1[addr-ans_offset][35:24]),
                        $signed(res2_conv3_7_ans_b1[addr-ans_offset][23:12]),   $signed(res2_conv3_7_ans_b1[addr-ans_offset][11:0]));
                end else if(layer == RES3_CONV3_9)begin
                    $write("But the golden answer is \n%d (ch0)\n%d (ch1)\n%d (ch2)\n%d (ch3)\n\n", 
                        $signed(res3_conv3_9_ans_b1[addr-ans_offset][47:36]),   $signed(res3_conv3_9_ans_b1[addr-ans_offset][35:24]),
                        $signed(res3_conv3_9_ans_b1[addr-ans_offset][23:12]),   $signed(res3_conv3_9_ans_b1[addr-ans_offset][11:0]));
                end else if(layer == CONV3_POOL_11)begin
                    $write("But the golden answer is \n%d (ch0)\n%d (ch1)\n%d (ch2)\n%d (ch3)\n\n", 
                        $signed(conv3_pool_11_ans_b1[addr-ans_offset][47:36]),   $signed(conv3_pool_11_ans_b1[addr-ans_offset][35:24]),
                        $signed(conv3_pool_11_ans_b1[addr-ans_offset][23:12]),   $signed(conv3_pool_11_ans_b1[addr-ans_offset][11:0]));
                end else if(layer == FC)begin
                    $write("But the golden answer is \n%d (ch0)\n%d (ch1)\n%d (ch2)\n%d (ch3)\n\n", 
                        $signed(fc_ans[addr-ans_offset][47:36]),   $signed(fc_ans[addr-ans_offset][35:24]),
                        $signed(fc_ans[addr-ans_offset][23:12]),   $signed(fc_ans[addr-ans_offset][11:0]));
                end
            end
            B2: begin
                $write("Your answer is \n%d (ch0)\n%d (ch1)\n%d (ch2)\n%d (ch3)\n", 
                    $signed(sram_50176x48b_b2.mem[addr][47:36]),   $signed(sram_50176x48b_b2.mem[addr][35:24]),
                    $signed(sram_50176x48b_b2.mem[addr][23:12]),   $signed(sram_50176x48b_b2.mem[addr][11:0]));
                if(layer == CONV3_POOL_1) begin
                    $write("But the golden answer is \n%d (ch0)\n%d (ch1)\n%d (ch2)\n%d (ch3)\n\n", 
                        $signed(conv3_pool_1_ans_b2[addr-ans_offset][47:36]),   $signed(conv3_pool_1_ans_b2[addr-ans_offset][35:24]),
                        $signed(conv3_pool_1_ans_b2[addr-ans_offset][23:12]),   $signed(conv3_pool_1_ans_b2[addr-ans_offset][11:0]));
                end else if(layer == CONV3_POOL_3) begin
                    $write("But the golden answer is \n%d  (ch0)\n%d  (ch1)\n%d  (ch2)\n%d  (ch3)\n\n", 
                        $signed(conv3_pool_3_ans_b2[addr-ans_offset][47:36]),   $signed(conv3_pool_3_ans_b2[addr-ans_offset][35:24]),
                        $signed(conv3_pool_3_ans_b2[addr-ans_offset][23:12]),   $signed(conv3_pool_3_ans_b2[addr-ans_offset][11:0]));
                end else if(layer == RES1_CONV3_5)begin
                    $write("But the golden answer is \n%d (ch0)\n%d (ch1)\n%d (ch2)\n%d (ch3)\n\n", 
                        $signed(res1_conv3_5_ans_b2[addr-ans_offset][47:36]),   $signed(res1_conv3_5_ans_b2[addr-ans_offset][35:24]),
                        $signed(res1_conv3_5_ans_b2[addr-ans_offset][23:12]),   $signed(res1_conv3_5_ans_b2[addr-ans_offset][11:0]));
                end else if(layer == RES2_CONV3_7)begin
                    $write("But the golden answer is \n%d (ch0)\n%d (ch1)\n%d (ch2)\n%d (ch3)\n\n", 
                        $signed(res2_conv3_7_ans_b2[addr-ans_offset][47:36]),   $signed(res2_conv3_7_ans_b2[addr-ans_offset][35:24]),
                        $signed(res2_conv3_7_ans_b2[addr-ans_offset][23:12]),   $signed(res2_conv3_7_ans_b2[addr-ans_offset][11:0]));
                end else if(layer == RES3_CONV3_9)begin
                    $write("But the golden answer is \n%d (ch0)\n%d (ch1)\n%d (ch2)\n%d (ch3)\n\n", 
                        $signed(res3_conv3_9_ans_b2[addr-ans_offset][47:36]),   $signed(res3_conv3_9_ans_b2[addr-ans_offset][35:24]),
                        $signed(res3_conv3_9_ans_b2[addr-ans_offset][23:12]),   $signed(res3_conv3_9_ans_b2[addr-ans_offset][11:0]));
                end else if(layer == CONV3_POOL_11)begin
                    $write("But the golden answer is \n%d (ch0)\n%d (ch1)\n%d (ch2)\n%d (ch3)\n\n", 
                        $signed(conv3_pool_11_ans_b2[addr-ans_offset][47:36]),   $signed(conv3_pool_11_ans_b2[addr-ans_offset][35:24]),
                        $signed(conv3_pool_11_ans_b2[addr-ans_offset][23:12]),   $signed(conv3_pool_11_ans_b2[addr-ans_offset][11:0]));
                end
            end
            B3: begin
                $write("Your answer is \n%d (ch0)\n%d (ch1)\n%d (ch2)\n%d (ch3)\n", 
                    $signed(sram_50176x48b_b3.mem[addr][47:36]),   $signed(sram_50176x48b_b3.mem[addr][35:24]),
                    $signed(sram_50176x48b_b3.mem[addr][23:12]),   $signed(sram_50176x48b_b3.mem[addr][11:0]));
                if(layer == CONV3_POOL_1) begin
                    $write("But the golden answer is \n%d (ch0)\n%d (ch1)\n%d (ch2)\n%d (ch3)\n\n", 
                        $signed(conv3_pool_1_ans_b3[addr-ans_offset][47:36]),   $signed(conv3_pool_1_ans_b3[addr-ans_offset][35:24]),
                        $signed(conv3_pool_1_ans_b3[addr-ans_offset][23:12]),   $signed(conv3_pool_1_ans_b3[addr-ans_offset][11:0]));
                end else if(layer == CONV3_POOL_3) begin
                    $write("But the golden answer is \n%d  (ch0)\n%d  (ch1)\n%d  (ch2)\n%d  (ch3)\n\n", 
                        $signed(conv3_pool_3_ans_b3[addr-ans_offset][47:36]),   $signed(conv3_pool_3_ans_b3[addr-ans_offset][35:24]),
                        $signed(conv3_pool_3_ans_b3[addr-ans_offset][23:12]),   $signed(conv3_pool_3_ans_b3[addr-ans_offset][11:0]));
                end else if(layer == RES1_CONV3_5)begin
                    $write("But the golden answer is \n%d (ch0)\n%d (ch1)\n%d (ch2)\n%d (ch3)\n\n", 
                        $signed(res1_conv3_5_ans_b3[addr-ans_offset][47:36]),   $signed(res1_conv3_5_ans_b3[addr-ans_offset][35:24]),
                        $signed(res1_conv3_5_ans_b3[addr-ans_offset][23:12]),   $signed(res1_conv3_5_ans_b3[addr-ans_offset][11:0]));
                end else if(layer == RES2_CONV3_7)begin
                    $write("But the golden answer is \n%d (ch0)\n%d (ch1)\n%d (ch2)\n%d (ch3)\n\n", 
                        $signed(res2_conv3_7_ans_b3[addr-ans_offset][47:36]),   $signed(res2_conv3_7_ans_b3[addr-ans_offset][35:24]),
                        $signed(res2_conv3_7_ans_b3[addr-ans_offset][23:12]),   $signed(res2_conv3_7_ans_b3[addr-ans_offset][11:0]));
                end else if(layer == RES3_CONV3_9)begin
                    $write("But the golden answer is \n%d (ch0)\n%d (ch1)\n%d (ch2)\n%d (ch3)\n\n", 
                        $signed(res3_conv3_9_ans_b3[addr-ans_offset][47:36]),   $signed(res3_conv3_9_ans_b3[addr-ans_offset][35:24]),
                        $signed(res3_conv3_9_ans_b3[addr-ans_offset][23:12]),   $signed(res3_conv3_9_ans_b3[addr-ans_offset][11:0]));
                end else if(layer == CONV3_POOL_11)begin
                    $write("But the golden answer is \n%d (ch0)\n%d (ch1)\n%d (ch2)\n%d (ch3)\n\n", 
                        $signed(conv3_pool_11_ans_b3[addr-ans_offset][47:36]),   $signed(conv3_pool_11_ans_b3[addr-ans_offset][35:24]),
                        $signed(conv3_pool_11_ans_b3[addr-ans_offset][23:12]),   $signed(conv3_pool_11_ans_b3[addr-ans_offset][11:0]));
                end
            end
        endcase
    end
endtask
endmodule