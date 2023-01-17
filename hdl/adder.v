module adder #(
parameter CH_NUM = 1,  //channel number
parameter ACT_PER_ADDR = 4, //how many pixel
parameter BW_PER_ACT = 12, //bit per pixel
parameter WEIGHT_PER_ADDR = 9, //how many weight per address
parameter BIAS_PER_ADDR = 1,
parameter BW_PER_PARAM = 8, //weight and bias bit numbers
parameter  CONV3_BW = BW_PER_ACT+BW_PER_PARAM+3,
parameter  ADDER_BW = CONV3_BW + 6 //add 64 channel will have 6 bits extra
)(
input signed[CONV3_BW*4-1:0] conv3_f_ch0,
input signed[CONV3_BW*4-1:0] conv3_f_ch1,
input signed[CONV3_BW*4-1:0] conv3_f_ch2,
input signed[CONV3_BW*4-1:0] conv3_f_ch3,
input signed[CONV3_BW*4-1:0] conv3_f_ch4,
input signed[CONV3_BW*4-1:0] conv3_f_ch5,
input signed[CONV3_BW*4-1:0] conv3_f_ch6,
input signed[CONV3_BW*4-1:0] conv3_f_ch7,
//input enable,   //enable counter for chossing add how many times
//input [1:0]counter_mode, //choose how many time it should add
input clk,
input srst_n,
output reg signed[ADDER_BW*4-1:0] add_ch0,
output reg signed[ADDER_BW*4-1:0] add_ch1,
output reg signed[ADDER_BW*4-1:0] add_ch2,
output reg signed[ADDER_BW*4-1:0] add_ch3,
output reg signed[ADDER_BW*4-1:0] add_ch4,
output reg signed[ADDER_BW*4-1:0] add_ch5,
output reg signed[ADDER_BW*4-1:0] add_ch6,
output reg signed[ADDER_BW*4-1:0] add_ch7,
input [6:0]counter
);

reg [6:0]target;
//reg [6:0]counter,next_counter;
reg signed[ADDER_BW*4-1:0] temp_add_ch0;
reg signed[ADDER_BW*4-1:0] temp_add_ch1;
reg signed[ADDER_BW*4-1:0] temp_add_ch2;
reg signed[ADDER_BW*4-1:0] temp_add_ch3;
reg signed[ADDER_BW*4-1:0] temp_add_ch4;
reg signed[ADDER_BW*4-1:0] temp_add_ch5;
reg signed[ADDER_BW*4-1:0] temp_add_ch6;
reg signed[ADDER_BW*4-1:0] temp_add_ch7;

/*
always @*begin
  case(counter_mode)
    2'd0: target = 7'd2;
    2'd1: target = 7'd31;
    2'd2: target = 7'd63;
  default: target = 7'd2;
  endcase
end

always @*begin
  if(enable)
    next_counter = counter + 1;
  else if(counter == target)
    next_counter = 0;
  else
    next_counter = 0;
end

always @(posedge clk)begin
  if(~srst_n)
    counter <= 0;
  else
    counter <= next_counter;
end
*/
always @(posedge clk)begin
  if(~srst_n)begin
    add_ch0 <= 0;
    add_ch1 <= 0;
    add_ch2 <= 0;
    add_ch3 <= 0;
    add_ch4 <= 0;
    add_ch5 <= 0;
    add_ch6 <= 0;
    add_ch7 <= 0;
  end
  else begin
    add_ch0 <= temp_add_ch0;
    add_ch1 <= temp_add_ch1;
    add_ch2 <= temp_add_ch2;
    add_ch3 <= temp_add_ch3;
    add_ch4 <= temp_add_ch4;
    add_ch5 <= temp_add_ch5;
    add_ch6 <= temp_add_ch6;
    add_ch7 <= temp_add_ch7;
  end
end

always @*begin
  if(counter == 7'd0)begin
    temp_add_ch0 = conv3_f_ch0;
    temp_add_ch1 = conv3_f_ch1;
    temp_add_ch2 = conv3_f_ch2;
    temp_add_ch3 = conv3_f_ch3;
    temp_add_ch4 = conv3_f_ch4;
    temp_add_ch5 = conv3_f_ch5;
    temp_add_ch6 = conv3_f_ch6;
    temp_add_ch7 = conv3_f_ch7;
  end
  else begin
    temp_add_ch0 = {(add_ch0[115:87]+conv3_f_ch0[91:69]),(add_ch0[86:58]+conv3_f_ch0[68:46]),(add_ch0[57:29]+conv3_f_ch0[45:23]),(add_ch0[28:0]+conv3_f_ch0[22:0])};
    temp_add_ch1 = {(add_ch1[115:87]+conv3_f_ch1[91:69]),(add_ch1[86:58]+conv3_f_ch1[68:46]),(add_ch1[57:29]+conv3_f_ch1[45:23]),(add_ch1[28:0]+conv3_f_ch1[22:0])};
    temp_add_ch2 = {(add_ch2[115:87]+conv3_f_ch2[91:69]),(add_ch2[86:58]+conv3_f_ch2[68:46]),(add_ch2[57:29]+conv3_f_ch2[45:23]),(add_ch2[28:0]+conv3_f_ch2[22:0])};
    temp_add_ch3 = {(add_ch3[115:87]+conv3_f_ch3[91:69]),(add_ch3[86:58]+conv3_f_ch3[68:46]),(add_ch3[57:29]+conv3_f_ch3[45:23]),(add_ch3[28:0]+conv3_f_ch3[22:0])};
    temp_add_ch4 = {(add_ch4[115:87]+conv3_f_ch4[91:69]),(add_ch4[86:58]+conv3_f_ch4[68:46]),(add_ch4[57:29]+conv3_f_ch4[45:23]),(add_ch4[28:0]+conv3_f_ch4[22:0])};
    temp_add_ch5 = {(add_ch5[115:87]+conv3_f_ch5[91:69]),(add_ch5[86:58]+conv3_f_ch5[68:46]),(add_ch5[57:29]+conv3_f_ch5[45:23]),(add_ch5[28:0]+conv3_f_ch5[22:0])};
    temp_add_ch6 = {(add_ch6[115:87]+conv3_f_ch6[91:69]),(add_ch6[86:58]+conv3_f_ch6[68:46]),(add_ch6[57:29]+conv3_f_ch6[45:23]),(add_ch6[28:0]+conv3_f_ch6[22:0])};
    temp_add_ch7 = {(add_ch7[115:87]+conv3_f_ch7[91:69]),(add_ch7[86:58]+conv3_f_ch7[68:46]),(add_ch7[57:29]+conv3_f_ch7[45:23]),(add_ch7[28:0]+conv3_f_ch7[22:0])};
  end
end



endmodule
/*
[28:0] [22:0]
[57:29] [45:23]
[86:58] [68:46]
[115:87] [91:69]
*/  
    
    
