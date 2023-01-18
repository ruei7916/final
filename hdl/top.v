`include "resblock.v"
`include "adder.v"
`include "CONV3.v"
`include "fc.v"
`include "globalave.v"
module top #(
parameter CH_NUM = 1,    //input channel number
parameter ACT_PER_ADDR = 4, //how many pixel
parameter BW_PER_ACT = 12, //bit per pixel
parameter WEIGHT_PER_ADDR = 72, //9*8 weight
parameter BIAS_PER_ADDR = 8, //1*8 bias
parameter BW_PER_PARAM = 8
)
(
input clk,
input srst_n,     // synchronous reset (active low)
input enable,     // enable signal for notifying that the unshuffled image is ready in SRAM A
output reg valid, // output valid for testbench to check answers in corresponding SRAM groups
// read data from SRAM group A
input [CH_NUM*ACT_PER_ADDR*BW_PER_ACT-1:0] sram_rdata_a0,
input [CH_NUM*ACT_PER_ADDR*BW_PER_ACT-1:0] sram_rdata_a1,
input [CH_NUM*ACT_PER_ADDR*BW_PER_ACT-1:0] sram_rdata_a2,
input [CH_NUM*ACT_PER_ADDR*BW_PER_ACT-1:0] sram_rdata_a3,
// read data from SRAM group B
input [CH_NUM*ACT_PER_ADDR*BW_PER_ACT-1:0] sram_rdata_b0,
input [CH_NUM*ACT_PER_ADDR*BW_PER_ACT-1:0] sram_rdata_b1,
input [CH_NUM*ACT_PER_ADDR*BW_PER_ACT-1:0] sram_rdata_b2,
input [CH_NUM*ACT_PER_ADDR*BW_PER_ACT-1:0] sram_rdata_b3,
// read data from parameter SRAM
input [WEIGHT_PER_ADDR*BW_PER_PARAM-1:0] sram_rdata_weight,  
input [BIAS_PER_ADDR*BW_PER_PARAM-1:0] sram_rdata_bias,
// read address to SRAM group A //57*57*64
output reg [18-1:0] sram_raddr_a0,
output reg [18-1:0] sram_raddr_a1,
output reg [18-1:0] sram_raddr_a2,
output reg [18-1:0] sram_raddr_a3,
// read address to SRAM group B //28*28*64
output reg [16-1:0] sram_raddr_b0,
output reg [16-1:0] sram_raddr_b1,
output reg [16-1:0] sram_raddr_b2,
output reg [16-1:0] sram_raddr_b3,
// read address to parameter SRAM //every address have 8 weight and every weight has 9 numbers, total address = 82198/8 
output reg [12-1:0] sram_raddr_weight,       
output reg [6-1:0] sram_raddr_bias,
// write enable for SRAM groups A & B
output reg sram_wen_a0,
output reg sram_wen_a1,
output reg sram_wen_a2,
output reg sram_wen_a3,
output reg sram_wen_b0,
output reg sram_wen_b1,
output reg sram_wen_b2,
output reg sram_wen_b3,
// word mask for SRAM groups A & B // to decide which pixel to write (specially for avg pooling when only write 1 pixel per channel one time)
output reg [CH_NUM*ACT_PER_ADDR-1:0] sram_wordmask_a,
output reg [CH_NUM*ACT_PER_ADDR-1:0] sram_wordmask_b,
// write addrress to SRAM groups A & B
output reg [18-1:0] sram_waddr_a,
output reg [16-1:0] sram_waddr_b,
output reg sram_waddr_mode, // 1 for normal mode
// write data to SRAM groups A & B
output reg [CH_NUM*ACT_PER_ADDR*BW_PER_ACT-1:0] sram_wdata_a,
output reg [CH_NUM*ACT_PER_ADDR*BW_PER_ACT-1:0] sram_wdata_b

);

reg [4:0] n_state, state, state_1, state_2, state_3;
reg [6:0] n_in_x, in_x, in_x_1, in_x_2, in_x_3;
reg [6:0] n_in_y, in_y, in_y_1, in_y_2, in_y_3;
reg [6:0] n_in_ch, in_ch, in_ch_1;
reg [6:0] in_xy_target, in_ch_target;
reg [6:0] kernel_num, n_kernel_num, kernel_num_target;
reg [6:0] kernel_num_1, kernel_num_2, kernel_num_3;
reg [8:0] cnt, n_cnt, cnt_target;
reg [3:0] resblock_counter, n_resblock_counter, resblock_counter_target, resblock_counter_1;
reg in_ch_carry, in_ch_carry_1, in_ch_carry_2; 
reg resblock_rst;
reg avg_enable, avg_enable_1, avg_enable_2, avg_enable_3;
reg res_enable, res_enable_1, res_enable_2, res_enable_3;
reg normal_sram_wen0,normal_sram_wen1,normal_sram_wen2,normal_sram_wen3;
reg pool_sram_wen0,pool_sram_wen1,pool_sram_wen2,pool_sram_wen3;
reg [18-1:0] conv3_sram_raddr_a0, conv3_sram_raddr_a1, conv3_sram_raddr_a2, conv3_sram_raddr_a3;
reg [16-1:0] conv3_sram_raddr_b0, conv3_sram_raddr_b1, conv3_sram_raddr_b2, conv3_sram_raddr_b3;
reg [18-1:0] resblock_sram_raddr_a0, resblock_sram_raddr_a1, resblock_sram_raddr_a2, resblock_sram_raddr_a3;
reg [16-1:0] resblock_sram_raddr_b0, resblock_sram_raddr_b1, resblock_sram_raddr_b2, resblock_sram_raddr_b3;
reg [18-1:0] normal_sram_waddr_a;
reg [16-1:0] normal_sram_waddr_b;
reg [18-1:0] pool_sram_waddr_a;
reg [16-1:0] pool_sram_waddr_b;
wire [16-1:0] dense_sram_waddr_b;
wire [CH_NUM*ACT_PER_ADDR-1:0] normal_wordmask;
reg [CH_NUM*ACT_PER_ADDR-1:0] pool_wordmask;


wire [(12+8+3)*4-1:0] conv3_f_ch0, conv3_f_ch1, conv3_f_ch2, conv3_f_ch3, conv3_f_ch4, conv3_f_ch5, conv3_f_ch6, conv3_f_ch7;
wire [(12+8+3+6)*4-1:0] in_ch0, in_ch1, in_ch2, in_ch3, in_ch4, in_ch5, in_ch6, in_ch7;
wire [9*8-1:0] w0, w1, w2, w3, w4, w5, w6, w7;
wire [8-1:0] b0, b1, b2, b3, b4, b5, b6, b7;
wire [1:0]pool_x,pool_y;
reg [4*4*12-1:0] conv3_f0;
reg [4*12-1:0] resblock_sram_rdata;
wire [4*12-1:0] resblock_sram_wdata;
wire [4*12-1:0] global_sram_wdata;
wire [4*12-1:0] fc_sram_wdata;
reg global_enable,fc_enable;
wire [5:0]ccc;
assign {w0,w1,w2,w3,w4,w5,w6,w7} = sram_rdata_weight;
assign {b0,b1,b2,b3,b4,b5,b6,b7} = sram_rdata_bias;


always @(posedge clk) begin
    if(~srst_n) begin
        in_x_3 <= 0;
        in_x_2 <= 0;
        in_x_1 <= 0;
        in_y_3 <= 0;
        in_y_2 <= 0;
        in_y_1 <= 0;
        kernel_num_3 <= 0;
        kernel_num_2 <= 0;
        kernel_num_1 <= 0;
        state_3 <= 0;
        state_2 <= 0;
        state_1 <= 0;
    end
    else begin
        in_x_3 <= in_x_2;
        in_x_2 <= in_x_1;
        in_x_1 <= in_x;
        in_y_3 <= in_y_2;
        in_y_2 <= in_y_1;
        in_y_1 <= in_y;
        kernel_num_3 <= kernel_num_2;
        kernel_num_2 <= kernel_num_1;
        kernel_num_1 <= kernel_num;
        state_3 <= state_2;
        state_2 <= state_1;
        state_1 <= state;
    end
end


always @(posedge clk) begin
    if(~srst_n)begin
        in_ch_1 <= 0;
        avg_enable_3 <= 0;
        avg_enable_2 <= 0;
        avg_enable_1 <= 0;
        res_enable_3 <= 0;
        res_enable_2 <= 0;
        res_enable_1 <= 0;
    end
    else begin
        in_ch_1 <= in_ch;
        avg_enable_3 <= avg_enable_2;
        avg_enable_2 <= avg_enable_1;
        avg_enable_1 <= avg_enable;
        res_enable_3 <= res_enable_2;
        res_enable_2 <= res_enable_1;
        res_enable_1 <= res_enable;
    end
end

resblock resblock(
    .clk(clk),
    .avg_enable(avg_enable_3),
    .res_enable(res_enable_3),
    .sram_rdata(resblock_sram_rdata),
    .in_ch0(in_ch0),
    .in_ch1(in_ch1),
    .in_ch2(in_ch2),
    .in_ch3(in_ch3),
    .in_ch4(in_ch4),
    .in_ch5(in_ch5),
    .in_ch6(in_ch6),
    .in_ch7(in_ch7),
    .new(resblock_rst),
    .bias0(b0),
    .bias1(b1),
    .bias2(b2),
    .bias3(b3),
    .bias4(b4),
    .bias5(b5),
    .bias6(b6),
    .bias7(b7),
    .sram_wdata(resblock_sram_wdata)
);
adder adder(
    .conv3_f_ch0(conv3_f_ch0),
    .conv3_f_ch1(conv3_f_ch1),
    .conv3_f_ch2(conv3_f_ch2),
    .conv3_f_ch3(conv3_f_ch3),
    .conv3_f_ch4(conv3_f_ch4),
    .conv3_f_ch5(conv3_f_ch5),
    .conv3_f_ch6(conv3_f_ch6),
    .conv3_f_ch7(conv3_f_ch7),
    .clk(clk),
    .srst_n(srst_n),
    .add_ch0(in_ch0),
    .add_ch1(in_ch1),
    .add_ch2(in_ch2),
    .add_ch3(in_ch3),
    .add_ch4(in_ch4),
    .add_ch5(in_ch5),
    .add_ch6(in_ch6),
    .add_ch7(in_ch7),
    .counter(in_ch_1)
);
CONV3 conv3 (
    .f0(conv3_f0),//4*4*12
    .w0(w0),//9*8
    .w1(w1),
    .w2(w2),
    .w3(w3),
    .w4(w4),
    .w5(w5),
    .w6(w6),
    .w7(w7),
    .conv3_f_ch0(conv3_f_ch0),
    .conv3_f_ch1(conv3_f_ch1),
    .conv3_f_ch2(conv3_f_ch2),
    .conv3_f_ch3(conv3_f_ch3),
    .conv3_f_ch4(conv3_f_ch4),
    .conv3_f_ch5(conv3_f_ch5),
    .conv3_f_ch6(conv3_f_ch6),
    .conv3_f_ch7(conv3_f_ch7),
    .clk(clk)
);

globalave globalave(  //資料來的那一個cycle enable
    .f0({sram_rdata_b0[47:24], sram_rdata_b1[47:24],
                            sram_rdata_b0[23: 0], sram_rdata_b1[23: 0],
                            sram_rdata_b2[47:24], sram_rdata_b3[47:24],
                            sram_rdata_b2[23: 0], sram_rdata_b3[23: 0] }),//4*4*12
    .clk(clk),
    .srst_n(srst_n),
    .global_enable(global_enable),
    .sram_wdata(global_sram_wdata)
);

fc fc(   //資料來的那一個cycle enable
    .f0(sram_rdata_a0[47:36]),//1 pixel 12 bits
    .clk(clk),
    .srst_n(srst_n),
    .fc_enable(fc_enable),
    .weight(sram_rdata_weight[575:528]),
    .bias(sram_rdata_bias[63:16]),
    .sram_wdata(fc_sram_wdata),
    .counter(ccc) //six pixels output, first output 0~3 channel, second output 4~5 channel
);


// conv3_sram_raddr
always @(*) begin
    conv3_sram_raddr_a0=(n_in_ch*57+n_in_y[6:1]+n_in_y[0])*57+n_in_x[6:1]+n_in_x[0];
    conv3_sram_raddr_a1=(n_in_ch*57+n_in_y[6:1]+n_in_y[0])*57+n_in_x[6:1];
    conv3_sram_raddr_a2=(n_in_ch*57+n_in_y[6:1])*57+n_in_x[6:1]+n_in_x[0];
    conv3_sram_raddr_a3=(n_in_ch*57+n_in_y[6:1])*57+n_in_x[6:1];
    conv3_sram_raddr_b0=(n_in_ch*28+n_in_y[6:1]+n_in_y[0])*28+n_in_x[6:1]+n_in_x[0];
    conv3_sram_raddr_b1=(n_in_ch*28+n_in_y[6:1]+n_in_y[0])*28+n_in_x[6:1];
    conv3_sram_raddr_b2=(n_in_ch*28+n_in_y[6:1])*28+n_in_x[6:1]+n_in_x[0];
    conv3_sram_raddr_b3=(n_in_ch*28+n_in_y[6:1])*28+n_in_x[6:1];
end

//conv3_f0
always @(*) begin
    case (state)
    // read from sram a
    5'd1,5'd5,5'd9,5'd13,5'd17,5'd21:begin
        case ({in_y[0],in_x[0]})
            2'b00:begin
                conv3_f0 = {sram_rdata_a0[47:24], sram_rdata_a1[47:24],
                            sram_rdata_a0[23: 0], sram_rdata_a1[23: 0],
                            sram_rdata_a2[47:24], sram_rdata_a3[47:24],
                            sram_rdata_a2[23: 0], sram_rdata_a3[23: 0] };
            end 
            2'b01:begin
                conv3_f0 = {sram_rdata_a1[47:24], sram_rdata_a0[47:24],
                            sram_rdata_a1[23: 0], sram_rdata_a0[23: 0],
                            sram_rdata_a3[47:24], sram_rdata_a2[47:24],
                            sram_rdata_a3[23: 0], sram_rdata_a2[23: 0] };
            end 
            2'b10:begin
                conv3_f0 = {sram_rdata_a2[47:24], sram_rdata_a3[47:24],
                            sram_rdata_a2[23: 0], sram_rdata_a3[23: 0],
                            sram_rdata_a0[47:24], sram_rdata_a1[47:24],
                            sram_rdata_a0[23: 0], sram_rdata_a1[23: 0] };
            end 
            2'b11:begin
                conv3_f0 = {sram_rdata_a3[47:24], sram_rdata_a2[47:24],
                            sram_rdata_a3[23: 0], sram_rdata_a2[23: 0],
                            sram_rdata_a1[47:24], sram_rdata_a0[47:24],
                            sram_rdata_a1[23: 0], sram_rdata_a0[23: 0] };
            end
        endcase
    end
    // read from sram b
    5'd3,5'd7,5'd11,5'd15,5'd19:begin
        case ({in_y[0],in_x[0]})
            2'b00:begin
                conv3_f0 = {sram_rdata_b0[47:24], sram_rdata_b1[47:24],
                            sram_rdata_b0[23: 0], sram_rdata_b1[23: 0],
                            sram_rdata_b2[47:24], sram_rdata_b3[47:24],
                            sram_rdata_b2[23: 0], sram_rdata_b3[23: 0] };
            end 
            2'b01:begin
                conv3_f0 = {sram_rdata_b1[47:24], sram_rdata_b0[47:24],
                            sram_rdata_b1[23: 0], sram_rdata_b0[23: 0],
                            sram_rdata_b3[47:24], sram_rdata_b2[47:24],
                            sram_rdata_b3[23: 0], sram_rdata_b2[23: 0] };
            end 
            2'b10:begin
                conv3_f0 = {sram_rdata_b2[47:24], sram_rdata_b3[47:24],
                            sram_rdata_b2[23: 0], sram_rdata_b3[23: 0],
                            sram_rdata_b0[47:24], sram_rdata_b1[47:24],
                            sram_rdata_b0[23: 0], sram_rdata_b1[23: 0] };
            end 
            2'b11:begin
                conv3_f0 = {sram_rdata_b3[47:24], sram_rdata_b2[47:24],
                            sram_rdata_b3[23: 0], sram_rdata_b2[23: 0],
                            sram_rdata_b1[47:24], sram_rdata_b0[47:24],
                            sram_rdata_b1[23: 0], sram_rdata_b0[23: 0] };
            end
        endcase
    end
    default: 
        conv3_f0 = 0;
    endcase
end
reg no_in_ch_carry_n;
always @(*) begin
    if (~no_in_ch_carry_n) begin
        in_ch_carry = 0;
    end
    else begin
        if(in_ch==in_ch_target)begin
            in_ch_carry = 1;
        end
        else begin
            in_ch_carry = 0;
        end
    end
    
end

// fsm
always @(*) begin
    // target
    in_xy_target = 0;
    in_ch_target = 0;
    kernel_num_target = 0;
    cnt_target = 0;
    no_in_ch_carry_n=1;
    avg_enable = 0;
    res_enable = 0;
    global_enable = 0;
    fc_enable = 0;
    valid = 0;
    case (state)
        5'd0: begin
            no_in_ch_carry_n = 0;
            if(enable)begin
                in_xy_target = 0;
                in_ch_target = 0;
                kernel_num_target = 0;
                cnt_target = 0;
            end
        end
        5'd1:begin//pooling
            in_xy_target = 112-1;
            in_ch_target = 3-1;
            kernel_num_target = 32/8-1;
            avg_enable = 1;
            res_enable = 0;
        end
        5'd2:begin//idle
            avg_enable = 1;
            cnt_target = 4;
            no_in_ch_carry_n = 0;
        end
        5'd3:begin
            in_xy_target = 55-1;
            in_ch_target = 32-1;
            kernel_num_target = 32/8-1;
        end
        5'd4:begin//idle
            cnt_target = 10;
            no_in_ch_carry_n = 0;
        end
        5'd5:begin//pooling
            in_xy_target = 54-1;
            in_ch_target = 32-1;
            kernel_num_target = 32/8-1;
            avg_enable = 1;
        end
        5'd6:begin//idle
            avg_enable = 1;
            cnt_target = 4;
            no_in_ch_carry_n = 0;
        end
        5'd7:begin
            in_xy_target = 26-1;
            in_ch_target = 32-1;
            kernel_num_target = 32/8-1;
        end
        5'd8:begin//idle
            cnt_target = 10;
            no_in_ch_carry_n = 0;
        end
        5'd9:begin//res
            in_xy_target = 25-1;
            in_ch_target = 32-1;
            kernel_num_target = 32/8-1;
            res_enable = 1;
        end
        5'd10:begin//idle
            res_enable = 1;
            cnt_target = 10;
            no_in_ch_carry_n = 0;
        end
        5'd11:begin
            in_xy_target = 24-1;
            in_ch_target = 32-1;
            kernel_num_target = 32/8-1;
        end
        5'd12:begin//idle
            cnt_target = 10;
            no_in_ch_carry_n = 0;
        end
        5'd13:begin//res
            in_xy_target = 23-1;
            in_ch_target = 32-1;
            kernel_num_target = 32/8-1;
            res_enable = 1;
        end
        5'd14:begin//idle
            res_enable = 1;
            cnt_target = 10;
            no_in_ch_carry_n = 0;
        end
        5'd15:begin//pooling
            in_xy_target = 22-1;
            in_ch_target = 32-1;
            kernel_num_target = 64/8-1;
            avg_enable = 1;
        end
        5'd16:begin//idle
            avg_enable = 1;
            cnt_target = 4;
            no_in_ch_carry_n = 0;
        end
        5'd17:begin
            in_xy_target = 10-1;
            in_ch_target = 64-1;
            kernel_num_target = 64/8-1;
        end
        5'd18:begin//idle
            cnt_target = 10;
            no_in_ch_carry_n = 0;
        end
        5'd19:begin//res
            in_xy_target = 9-1;
            in_ch_target = 64-1;
            kernel_num_target = 64/8-1;
            res_enable = 1;
        end
        5'd20:begin//idle
            res_enable = 1;
            cnt_target = 10;
            no_in_ch_carry_n = 0;
        end
        5'd21:begin//pooling
            in_xy_target = 8-1;
            in_ch_target = 64-1;
            kernel_num_target = 64/8-1;
            avg_enable = 1;
        end
        5'd22:begin//idle
            avg_enable = 1;
            cnt_target = 4;
            no_in_ch_carry_n = 0;
        end
        5'd23:begin//global pooling
            no_in_ch_carry_n = 0;
            cnt_target = 256+1;
            if(cnt>=1)global_enable=1;
        end
        5'd24:begin//dense
            no_in_ch_carry_n = 0;
            cnt_target = 64+2;
            if(cnt>=1)fc_enable=1;
        end
        5'd25:begin// idle
            cnt_target = 2;
        end
        5'd26:begin // finish
            valid = 1;
        end
    endcase
end

reg [12-1:0]weight_offset;
reg [6-1:0]n_offset_counter,offset_counter,temp_offset_counter;

//weight and bias address one offset and one counter 
always @*begin
    sram_raddr_weight = n_in_ch + weight_offset;
    sram_raddr_bias   = temp_offset_counter;
end
always @*begin
    if(in_ch==in_ch_target&&in_y==in_xy_target&&in_x==in_xy_target)
        n_offset_counter = offset_counter + 1;
    else
        n_offset_counter = offset_counter;
end
always @(posedge clk) begin
    if(~srst_n) begin
        offset_counter <= 0;
        temp_offset_counter <= 0;
    end
    else begin
        offset_counter <= n_offset_counter;
        temp_offset_counter <= offset_counter;
    end
end

//for weight
always @*begin
    weight_offset = 0;
    case(n_offset_counter)
    6'd0,6'd1,6'd2,6'd3,6'd4:begin
                                    weight_offset = 3*n_offset_counter;
                                end
    6'd5,6'd6,6'd7,6'd8,6'd9,6'd10,6'd11,6'd12,6'd13,6'd14,6'd15,6'd16,6'd17,6'd18,6'd19,6'd20,6'd21,6'd22,6'd23,6'd24,6'd25,6'd26,6'd27,6'd28,6'd29,6'd30,6'd31,6'd32,6'd33,6'd34,6'd35,6'd36:begin
                                    weight_offset = 32*(n_offset_counter-4)+12;
    end
    6'd37,6'd38,6'd39,6'd40,6'd41,6'd42,6'd43,6'd44,6'd45,6'd46,6'd47,6'd48,6'd49,6'd50,6'd51,6'd52,6'd53,6'd54,6'd55,6'd56,6'd57,6'd58,6'd59,6'd60:begin
                                    weight_offset = 64*(n_offset_counter-36)+1036;
    end
    endcase
end

//global average address 
reg [16-1:0] globalave_sram_raddr_b0, globalave_sram_raddr_b1, globalave_sram_raddr_b2, globalave_sram_raddr_b3;
always @(*) begin
    globalave_sram_raddr_b0 = cnt[8:2]*28*28+cnt[1:0];
    globalave_sram_raddr_b1 = cnt[8:2]*28*28+cnt[1:0];
    globalave_sram_raddr_b2 = cnt[8:2]*28*28+cnt[1:0];
    globalave_sram_raddr_b3 = cnt[8:2]*28*28+cnt[1:0];
end

//fc address
reg [18-1:0] fc_sram_raddr_a0, fc_sram_raddr_a1, fc_sram_raddr_a2, fc_sram_raddr_a3;
always @(*) begin
    fc_sram_raddr_a0 = cnt*57*57;
    fc_sram_raddr_a1 = cnt*57*57;
    fc_sram_raddr_a2 = cnt*57*57;
    fc_sram_raddr_a3 = cnt*57*57;
end



//(ch*57+y[6:1]+y[0])*57+x[6:1]+x[0]

//address 晚原本的sram address 三個cycle
reg [6:0] res_x_1,res_y_1,res_kernel_1;


always @(posedge clk)begin
    if(~srst_n)begin
        res_x_1 <= 0;
        res_y_1 <= 0;
        res_kernel_1 <= 0;
    end
    else if(in_ch == in_ch_target)begin
        res_x_1 <= in_x;
        res_y_1 <= in_y;
        res_kernel_1 <= kernel_num;
    end
end              
always @(*)begin
    case({res_x_1[0],res_y_1[0]})
        2'b00:begin
                resblock_sram_rdata = sram_rdata_a3;
            end
        2'b10:begin
                resblock_sram_rdata = sram_rdata_a2;
            end           
        2'b01:begin
                resblock_sram_rdata = sram_rdata_a1;
            end     
        2'b11:begin
                resblock_sram_rdata = sram_rdata_a0;
            end
    endcase
end
always @*begin
    resblock_sram_raddr_a0 = resblock_counter*57*57+res_kernel_1*8*57*57+res_x_1[6:1]+res_x_1[0]+(res_y_1[6:1]+res_y_1[0])*57;
    resblock_sram_raddr_a1 = resblock_counter*57*57+res_kernel_1*8*57*57+res_x_1[6:1]+(res_y_1[6:1]+res_y_1[0])*57;
    resblock_sram_raddr_a2 = resblock_counter*57*57+res_kernel_1*8*57*57+res_x_1[6:1]+res_x_1[0]+(res_y_1[6:1])*57;
    resblock_sram_raddr_a3 = resblock_counter*57*57+res_kernel_1*8*57*57+res_x_1[6:1]+(res_y_1[6:1])*57;
    resblock_sram_raddr_b0 = resblock_counter*28*28+res_kernel_1*8*28*28+res_x_1[6:1]+res_x_1[0]+(res_y_1[6:1]+res_y_1[0])*28;
    resblock_sram_raddr_b1 = resblock_counter*28*28+res_kernel_1*8*28*28+res_x_1[6:1]+(res_y_1[6:1]+res_y_1[0])*28;
    resblock_sram_raddr_b2 = resblock_counter*28*28+res_kernel_1*8*28*28+res_x_1[6:1]+res_x_1[0]+(res_y_1[6:1])*28;
    resblock_sram_raddr_b3 = resblock_counter*28*28+res_kernel_1*8*28*28+res_x_1[6:1]+(res_y_1[6:1])*28;
end


//sram write address for normal
always @(*) begin
    normal_sram_waddr_a = ((res_kernel_1*8+resblock_counter_1)*57+res_y_1[6:1])*57+res_x_1[6:1];
    normal_sram_waddr_b = ((res_kernel_1*8+resblock_counter_1)*28+res_y_1[6:1])*28+res_x_1[6:1];
end

assign normal_wordmask = 4'b0000;


//sram write address for pooling address will change after four wordmask round
//sram address 0 -> 跳四層 -> 0 -> 跳四層 -> 0 跳四層 -> .......
/*
always @(*) begin
    pool_sram_waddr_a0 = res_kernel_1*8*57*57+resblock_counter_1*4*57*57+in_x_3/4+(in_y_3/4)*57;
    pool_sram_waddr_a1 = res_kernel_1*8*57*57+resblock_counter_1*4*57*57+(in_x_3-2)/4+(in_y_3/4)*57;
    pool_sram_waddr_a2 = res_kernel_1*8*57*57+resblock_counter_1*4*57*57+in_x_3/4+(in_y_3/4-2)*57;
    pool_sram_waddr_a3 = res_kernel_1*8*57*57+resblock_counter_1*4*57*57+(in_x_3-2)/4+(in_y_3/4-2)*57;
    pool_sram_waddr_b0 = res_kernel_1*8*28*28+resblock_counter_1*4*28*28+in_x_3/4+(in_y_3/4)*28;
    pool_sram_waddr_b1 = res_kernel_1*8*28*28+resblock_counter_1*4*28*28+(in_x_3-2)/4+(in_y_3/4)*28;
    pool_sram_waddr_b2 = res_kernel_1*8*28*28+resblock_counter_1*4*28*28+in_x_3/4+(in_y_3/4-2)*28;
    pool_sram_waddr_b3 = res_kernel_1*8*28*28+resblock_counter_1*4*28*28+(in_x_3-2)/4+(in_y_3/4-2)*28;
end
*/
always @(*) begin
    pool_sram_waddr_a = res_kernel_1*8*57*57+resblock_counter_1*4*57*57+res_x_1[6:2]+res_y_1[6:2]*57;
    pool_sram_waddr_b = res_kernel_1*8*28*28+resblock_counter_1*4*28*28+res_x_1[6:2]+res_y_1[6:2]*28;
end



//word mask decide by x,y location
always @(*)begin
    case({in_x_3[0],in_y_3[0]})
        2'b00: pool_wordmask = 4'b0111;
        2'b10: pool_wordmask = 4'b1011;
        2'b11: pool_wordmask = 4'b1110;
        2'b01: pool_wordmask = 4'b1101;
        default: pool_wordmask = 4'b0000;
    endcase
end


//sram write address for global average pooling
reg [18-1:0] globalavg_sram_waddr_a;
always @(*)begin
    globalavg_sram_waddr_a = (cnt-1)*57;
end

//sram write address for dense layer
assign dense_sram_waddr_b = 0;


//write enable
always @(*) begin
    if(resblock_counter_1==resblock_counter_target)begin
        normal_sram_wen0 = 1;
        normal_sram_wen1 = 1;
        normal_sram_wen2 = 1;
        normal_sram_wen3 = 1;
    end
    else begin
        case ({res_y_1[0],res_x_1[0]})
            2'b00:begin
                normal_sram_wen0 = 0;
                normal_sram_wen1 = 1;
                normal_sram_wen2 = 1;
                normal_sram_wen3 = 1;
            end
            2'b01:begin
                normal_sram_wen0 = 1;
                normal_sram_wen1 = 0;
                normal_sram_wen2 = 1;
                normal_sram_wen3 = 1;
            end
            2'b10:begin
                normal_sram_wen0 = 1;
                normal_sram_wen1 = 1;
                normal_sram_wen2 = 0;
                normal_sram_wen3 = 1;
            end
            2'b11:begin
                normal_sram_wen0 = 1;
                normal_sram_wen1 = 1;
                normal_sram_wen2 = 1;
                normal_sram_wen3 = 0;
            end
        endcase
    end
end
assign pool_x = in_x_3 % 4;
assign pool_y = in_y_3 % 4;

always @(*)begin
    if(resblock_counter_1==resblock_counter_target)begin
        case({pool_x,pool_y})
            4'b0000,4'b0001,4'b0100,4'b0101:begin //00 01 10 11
                    pool_sram_wen0 = 0;
                    pool_sram_wen1 = 1;
                    pool_sram_wen2 = 1;
                    pool_sram_wen3 = 1;
                    end
            4'b1000,4'b1100,4'b1001,4'b1101:begin //20 30 21 31
                    pool_sram_wen0 = 1;
                    pool_sram_wen1 = 0;
                    pool_sram_wen2 = 1;
                    pool_sram_wen3 = 1;
                    end
            4'b0010,4'b0011,4'b0110,4'b0111:begin //02 03 12 13
                    pool_sram_wen0 = 1;
                    pool_sram_wen1 = 1;
                    pool_sram_wen2 = 0;
                    pool_sram_wen3 = 1;
                    end                               
            4'b1010,4'b1011,4'b1110,4'b1111:begin //22 23 32 33
                    pool_sram_wen0 = 1;
                    pool_sram_wen1 = 1;
                    pool_sram_wen2 = 1;
                    pool_sram_wen3 = 0;
                    end
            default:begin pool_sram_wen0 = 1;
                    pool_sram_wen1 = 1;
                    pool_sram_wen2 = 1;
                    pool_sram_wen3 = 1;
                    end
        endcase
    end
    else begin
            pool_sram_wen0 = 1;
            pool_sram_wen1 = 1;
            pool_sram_wen2 = 1;
            pool_sram_wen3 = 1;
        end
end

//mux read address a

always @(*)begin
    case(state)
        5'd1,5'd5,5'd9,5'd13,5'd17,5'd21:begin //conv3 
                sram_raddr_a0 = conv3_sram_raddr_a0;
                sram_raddr_a1 = conv3_sram_raddr_a1;
                sram_raddr_a2 = conv3_sram_raddr_a2;
                sram_raddr_a3 = conv3_sram_raddr_a3;
            end
        5'd19:begin  //res shortcut
                sram_raddr_a0 = resblock_sram_raddr_a0;
                sram_raddr_a1 = resblock_sram_raddr_a1;
                sram_raddr_a2 = resblock_sram_raddr_a2; 
                sram_raddr_a3 = resblock_sram_raddr_a3; 
            end
        5'd24:begin //fc layer
                sram_raddr_a0 = fc_sram_raddr_a0;
                sram_raddr_a1 = fc_sram_raddr_a1;
                sram_raddr_a2 = fc_sram_raddr_a2;
                sram_raddr_a3 = fc_sram_raddr_a3;
            end      
        default:begin
                sram_raddr_a0 = conv3_sram_raddr_a0;
                sram_raddr_a1 = conv3_sram_raddr_a1;
                sram_raddr_a2 = conv3_sram_raddr_a2;
                sram_raddr_a3 = conv3_sram_raddr_a3;
            end
        endcase
end


//mux read address b
always @(*) begin
    case (state)
        5'd3,5'd7,5'd11,5'd15,5'd19: begin// conv3 read from sram b
            sram_raddr_b0 = conv3_sram_raddr_b0;
            sram_raddr_b1 = conv3_sram_raddr_b1;
            sram_raddr_b2 = conv3_sram_raddr_b2;
            sram_raddr_b3 = conv3_sram_raddr_b3;
        end
        5'd9,5'd13:begin//res
            sram_raddr_b0 = resblock_sram_raddr_b0;
            sram_raddr_b1 = resblock_sram_raddr_b1;
            sram_raddr_b2 = resblock_sram_raddr_b2;
            sram_raddr_b3 = resblock_sram_raddr_b3;
        end
        5'd23:begin//global
            sram_raddr_b0 = globalave_sram_raddr_b0;
            sram_raddr_b1 = globalave_sram_raddr_b1;
            sram_raddr_b2 = globalave_sram_raddr_b2;
            sram_raddr_b3 = globalave_sram_raddr_b3;
        end
        default: begin
            sram_raddr_b0 = conv3_sram_raddr_b0;
            sram_raddr_b1 = conv3_sram_raddr_b1;
            sram_raddr_b2 = conv3_sram_raddr_b2;
            sram_raddr_b3 = conv3_sram_raddr_b3;
        end
    endcase
end

//mux write address a
always @(*) begin
    case (state)
        5'd3,5'd7,5'd11,5'd19,
        5'd4,5'd8,5'd12,5'd20: begin// normal
            sram_waddr_a = normal_sram_waddr_a;
        end
        5'd15,5'd16:begin//pooling
            sram_waddr_a = pool_sram_waddr_a;
        end
        5'd23:begin//global
            sram_waddr_a = globalavg_sram_waddr_a;
        end
        default: begin
            sram_waddr_a = normal_sram_waddr_a;
        end
    endcase
end



//mux write address b
always @(*)begin
    case(state)
        5'd1,5'd2,5'd5,5'd6,5'd21,5'd22:begin //conv3 store in B pooling
                sram_waddr_b = pool_sram_waddr_b;
            end
        5'd9,5'd10,5'd13,5'd14,5'd17,5'd18:begin //conv3 store in b normal
                sram_waddr_b = normal_sram_waddr_b;
            end
        5'd24:begin //fc layer
                sram_waddr_b = dense_sram_waddr_b;
            end     
        default:begin
                sram_waddr_b = pool_sram_waddr_b;
            end
        endcase
end

//mux write enable
always @(*) begin
    sram_wen_a0 = 1;
    sram_wen_a1 = 1;
    sram_wen_a2 = 1;
    sram_wen_a3 = 1;
    sram_wen_b0 = 1;
    sram_wen_b1 = 1;
    sram_wen_b2 = 1;
    sram_wen_b3 = 1;
    case (state)
        5'd3,5'd7,5'd11,5'd19,
        5'd4,5'd8,5'd12,5'd20:begin//normal write a
            sram_wen_a0 = normal_sram_wen0;
            sram_wen_a1 = normal_sram_wen1;
            sram_wen_a2 = normal_sram_wen2;
            sram_wen_a3 = normal_sram_wen3;
        end
        5'd9,5'd10,5'd13,5'd14,5'd17,5'd18:begin//normal write b
            sram_wen_b0 = normal_sram_wen0;
            sram_wen_b1 = normal_sram_wen1;
            sram_wen_b2 = normal_sram_wen2;
            sram_wen_b3 = normal_sram_wen3;
        end 
        5'd15,5'd16:begin//pool WRITE A
            sram_wen_a0 = pool_sram_wen0;
            sram_wen_a1 = pool_sram_wen1;
            sram_wen_a2 = pool_sram_wen2;
            sram_wen_a3 = pool_sram_wen3;
        end
        5'd1,5'd2,5'd5,5'd6,5'd21,5'd22:begin//POOL WRITE B
            sram_wen_b0 = pool_sram_wen0;
            sram_wen_b1 = pool_sram_wen1;
            sram_wen_b2 = pool_sram_wen2;
            sram_wen_b3 = pool_sram_wen3;
        end
        5'd24:begin//fc
            sram_wen_b0 = (ccc == 6'd0)? 0:1;
            sram_wen_b1 = (ccc == 6'd1)? 0:1;
            sram_wen_b2 = 1;
            sram_wen_b3 = 1;
        end
        5'd23:begin//global avg
            sram_wen_b0 = 0;
        end
        default:begin
            sram_wen_a0 = 1;
            sram_wen_a1 = 1;
            sram_wen_a2 = 1;
            sram_wen_a3 = 1;
            sram_wen_b0 = 1;
            sram_wen_b1 = 1;
            sram_wen_b2 = 1;
            sram_wen_b3 = 1;
        end       
    endcase
end

//mux wordmask
always @(*)begin
    sram_wordmask_a = 4'b0000;
    sram_wordmask_b = 4'b0000;
    case(state)
        5'd1,5'd2,5'd5,5'd6,5'd21,5'd22:begin //pooling store to b
                sram_wordmask_b = pool_wordmask;
            end
        5'd15,5'd16:begin
                sram_wordmask_a = pool_wordmask;
            end
        default:begin
                sram_wordmask_a = 4'b0000;
                sram_wordmask_b = 4'b0000;
            end
    endcase
end
    
//mux write data a、b
always @(*)begin
    case(state)
        5'd23:begin //global layer write a
                sram_wdata_a = global_sram_wdata;
            end    
        default:begin
                sram_wdata_a = resblock_sram_wdata;
            end
    endcase
end

always @(*)begin
    case(state)
        5'd24:begin //conv3 store in B pooling
                sram_wdata_b = fc_sram_wdata;
            end    
        default:begin
                sram_wdata_b = resblock_sram_wdata;
            end
    endcase
end

always @(*)begin
    sram_waddr_mode = avg_enable_3;
end

always @(posedge clk) begin
    if(~srst_n) begin
        resblock_counter_1 <= 0;
    end
    else begin
        resblock_counter_1 <= resblock_counter;
    end
end

// resblock_counter_target
always @(*) begin
    if(avg_enable_3)begin
        resblock_counter_target = 2;
    end
    else begin
        resblock_counter_target = 8;
    end
end

// resblock_counter
always @(*) begin
    if(resblock_counter<resblock_counter_target)begin
        n_resblock_counter = resblock_counter + 1;
    end
    else begin
        n_resblock_counter = resblock_counter;
    end
end
always @(posedge clk) begin
    if(~srst_n||resblock_rst) begin
        resblock_counter <= 0;
    end
    else begin
        resblock_counter <= n_resblock_counter;
    end
end

always @(*) begin
    resblock_rst = in_ch_carry_1;
end
always @(posedge clk) begin
    in_ch_carry_2 <= in_ch_carry_1;
    in_ch_carry_1 <= in_ch_carry;
end

// cnt
always @(*) begin
    if(cnt==cnt_target)begin
        n_cnt = 0;
    end
    else begin
        n_cnt = cnt + 1;
    end
end
always @(posedge clk) begin
    if(~srst_n) begin
        cnt <= 0;
    end
    else begin
        cnt <= n_cnt;
    end
end


// in_ch
always @(*) begin
    if(in_ch==in_ch_target&&cnt==cnt_target)begin
        n_in_ch = 0;
    end
    else if(cnt==cnt_target)begin
        n_in_ch = in_ch + 1;
    end
    else begin
        n_in_ch = in_ch;
    end
end
always @(posedge clk) begin
    if(~srst_n) begin
        in_ch <= 0;
    end
    else begin
        in_ch <= n_in_ch;
    end
end

// in_x
always @(*) begin
    if(in_x==in_xy_target&&in_ch==in_ch_target&&cnt==cnt_target)begin
        n_in_x = 0;
    end
    else if(in_ch==in_ch_target&&cnt==cnt_target) begin
        n_in_x = in_x + 1;
    end
    else begin
        n_in_x = in_x;
    end
end
always @(posedge clk) begin
    if(~srst_n) begin
        in_x <= 0;
    end
    else begin
        in_x <= n_in_x;
    end
end

// in_y
always @(*) begin
    if(in_y==in_xy_target&&in_x==in_xy_target&&in_ch==in_ch_target&&cnt==cnt_target)begin
        n_in_y = 0;
    end
    else if(in_x==in_xy_target&&in_ch==in_ch_target&&cnt==cnt_target)begin
        n_in_y = in_y + 1;
    end
    else begin
        n_in_y = in_y;
    end
end
always @(posedge clk) begin
    if(~srst_n) begin
        in_y <= 0;
    end
    else begin
        in_y <= n_in_y;
    end
end

// kernel_num
always @(*) begin
    if(kernel_num==kernel_num_target&&in_ch==in_ch_target&&in_y==in_xy_target&&in_x==in_xy_target&&cnt==cnt_target)begin
        n_kernel_num = 0;
    end
    else if(in_ch==in_ch_target&&in_y==in_xy_target&&in_x==in_xy_target&&cnt==cnt_target)begin
        n_kernel_num = kernel_num + 1;
    end
    else begin
        n_kernel_num = kernel_num;
    end
end
always @(posedge clk) begin
    if(~srst_n) begin
        kernel_num <= 0;
    end
    else begin
        kernel_num <= n_kernel_num;
    end
end

// state
always @(*) begin
    if(kernel_num==kernel_num_target&&in_ch==in_ch_target&&in_x==in_xy_target&&in_y==in_xy_target&&cnt==cnt_target)begin
        n_state = state + 1;
    end
    else begin
        n_state = state;
    end
end
always @(posedge clk) begin
    if(~srst_n) begin
        state <= 0;
    end
    else begin
        state <= n_state;
    end
end

endmodule