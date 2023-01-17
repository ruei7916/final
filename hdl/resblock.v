module resblock#(
parameter CH_NUM = 1,  //channel number
parameter ACT_PER_ADDR = 4, //how many pixel
parameter BW_PER_ACT = 12, //bit per pixel
parameter WEIGHT_PER_ADDR = 9, //how many weight per address
parameter BIAS_PER_ADDR = 1,
parameter BW_PER_PARAM = 8, //weight and bias bit numbers
parameter  CONV3_BW = BW_PER_ACT+BW_PER_PARAM+3,
parameter  ADDER_BW = CONV3_BW + 6
)
(
input clk,
input avg_enable,
input res_enable,
input signed[ACT_PER_ADDR*BW_PER_ACT-1:0] sram_rdata,
input signed[ADDER_BW*4-1:0] in_ch0,
input signed[ADDER_BW*4-1:0] in_ch1,
input signed[ADDER_BW*4-1:0] in_ch2,
input signed[ADDER_BW*4-1:0] in_ch3,
input signed[ADDER_BW*4-1:0] in_ch4,
input signed[ADDER_BW*4-1:0] in_ch5,
input signed[ADDER_BW*4-1:0] in_ch6,
input signed[ADDER_BW*4-1:0] in_ch7,
input new,
input [BW_PER_PARAM-1:0]bias0,
input [BW_PER_PARAM-1:0]bias1,
input [BW_PER_PARAM-1:0]bias2,
input [BW_PER_PARAM-1:0]bias3,
input [BW_PER_PARAM-1:0]bias4,
input [BW_PER_PARAM-1:0]bias5,
input [BW_PER_PARAM-1:0]bias6,
input [BW_PER_PARAM-1:0]bias7,
output reg [ACT_PER_ADDR*BW_PER_ACT-1:0]sram_wdata
);

wire signed[30*4-1:0]relu_out[0:7];
reg signed[29:0]ch0[0:3];
reg signed[29:0]ch1[0:3];
reg signed[29:0]ch2[0:3];
reg signed[29:0]ch3[0:3];
reg signed[29:0]ch4[0:3];
reg signed[29:0]ch5[0:3];
reg signed[29:0]ch6[0:3];
reg signed[29:0]ch7[0:3];

biasnrelu a0(.in_pixel(in_ch0),.bias(bias0),.bias_out(relu_out[0]));
biasnrelu a1(.in_pixel(in_ch1),.bias(bias1),.bias_out(relu_out[1]));
biasnrelu a2(.in_pixel(in_ch2),.bias(bias2),.bias_out(relu_out[2]));
biasnrelu a3(.in_pixel(in_ch3),.bias(bias3),.bias_out(relu_out[3]));
biasnrelu a4(.in_pixel(in_ch4),.bias(bias4),.bias_out(relu_out[4]));
biasnrelu a5(.in_pixel(in_ch5),.bias(bias5),.bias_out(relu_out[5]));
biasnrelu a6(.in_pixel(in_ch6),.bias(bias6),.bias_out(relu_out[6]));
biasnrelu a7(.in_pixel(in_ch7),.bias(bias7),.bias_out(relu_out[7]));

reg signed[31:0]pool_ch0,pool_ch1,pool_ch2,pool_ch3,pool_ch4,pool_ch5,pool_ch6,pool_ch7;

always @*begin
  {ch0[0],ch0[1],ch0[2],ch0[3]} = relu_out[0];
  {ch1[0],ch1[1],ch1[2],ch1[3]} = relu_out[1];
  {ch2[0],ch2[1],ch2[2],ch2[3]} = relu_out[2];
  {ch3[0],ch3[1],ch3[2],ch3[3]} = relu_out[3];
  {ch4[0],ch4[1],ch4[2],ch4[3]} = relu_out[4];
  {ch5[0],ch5[1],ch5[2],ch5[3]} = relu_out[5];
  {ch6[0],ch6[1],ch6[2],ch6[3]} = relu_out[6];
  {ch7[0],ch7[1],ch7[2],ch7[3]} = relu_out[7];
end

  
// add before pooling
always @*begin
  pool_ch0 = ch0[0]+ch0[1]+ch0[2]+ch0[3];
  pool_ch1 = ch1[0]+ch1[1]+ch1[2]+ch1[3];  
  pool_ch2 = ch2[0]+ch2[1]+ch2[2]+ch2[3]; 
  pool_ch3 = ch3[0]+ch3[1]+ch3[2]+ch3[3]; 
  pool_ch4 = ch4[0]+ch4[1]+ch4[2]+ch4[3];
  pool_ch5 = ch5[0]+ch5[1]+ch5[2]+ch5[3];
  pool_ch6 = ch6[0]+ch6[1]+ch6[2]+ch6[3];
  pool_ch7 = ch7[0]+ch7[1]+ch7[2]+ch7[3];
end

wire signed[BW_PER_ACT-1:0] out_ch0[0:3];
wire signed[BW_PER_ACT-1:0] out_ch1[0:3];
wire signed[BW_PER_ACT-1:0] out_ch2[0:3];
wire signed[BW_PER_ACT-1:0] out_ch3[0:3];
wire signed[BW_PER_ACT-1:0] out_ch4[0:3];
wire signed[BW_PER_ACT-1:0] out_ch5[0:3];
wire signed[BW_PER_ACT-1:0] out_ch6[0:3];
wire signed[BW_PER_ACT-1:0] out_ch7[0:3];

//quantize when there is no avg pooling
quantize b0(.accumlated_output(ch0[0]),.result(out_ch0[0]));
quantize b1(.accumlated_output(ch0[1]),.result(out_ch0[1]));
quantize b2(.accumlated_output(ch0[2]),.result(out_ch0[2]));
quantize b3(.accumlated_output(ch0[3]),.result(out_ch0[3]));

quantize b4(.accumlated_output(ch1[0]),.result(out_ch1[0]));
quantize b5(.accumlated_output(ch1[1]),.result(out_ch1[1]));
quantize b6(.accumlated_output(ch1[2]),.result(out_ch1[2]));
quantize b7(.accumlated_output(ch1[3]),.result(out_ch1[3]));

quantize b8(.accumlated_output(ch2[0]),.result(out_ch2[0]));
quantize b9(.accumlated_output(ch2[1]),.result(out_ch2[1]));
quantize b10(.accumlated_output(ch2[2]),.result(out_ch2[2]));
quantize b11(.accumlated_output(ch2[3]),.result(out_ch2[3]));

quantize b12(.accumlated_output(ch3[0]),.result(out_ch3[0]));
quantize b13(.accumlated_output(ch3[1]),.result(out_ch3[1]));
quantize b14(.accumlated_output(ch3[2]),.result(out_ch3[2]));
quantize b15(.accumlated_output(ch3[3]),.result(out_ch3[3]));

quantize b16(.accumlated_output(ch4[0]),.result(out_ch4[0]));
quantize b17(.accumlated_output(ch4[1]),.result(out_ch4[1]));
quantize b18(.accumlated_output(ch4[2]),.result(out_ch4[2]));
quantize b19(.accumlated_output(ch4[3]),.result(out_ch4[3]));

quantize b20(.accumlated_output(ch5[0]),.result(out_ch5[0]));
quantize b21(.accumlated_output(ch5[1]),.result(out_ch5[1]));
quantize b22(.accumlated_output(ch5[2]),.result(out_ch5[2]));
quantize b23(.accumlated_output(ch5[3]),.result(out_ch5[3]));

quantize b24(.accumlated_output(ch6[0]),.result(out_ch6[0]));
quantize b25(.accumlated_output(ch6[1]),.result(out_ch6[1]));
quantize b26(.accumlated_output(ch6[2]),.result(out_ch6[2]));
quantize b27(.accumlated_output(ch6[3]),.result(out_ch6[3]));

quantize b28(.accumlated_output(ch7[0]),.result(out_ch7[0]));
quantize b29(.accumlated_output(ch7[1]),.result(out_ch7[1]));
quantize b30(.accumlated_output(ch7[2]),.result(out_ch7[2]));
quantize b31(.accumlated_output(ch7[3]),.result(out_ch7[3]));

reg signed[31:0] temp_pool_ch0,temp_pool_ch1,temp_pool_ch2,temp_pool_ch3,temp_pool_ch4,temp_pool_ch5,temp_pool_ch6,temp_pool_ch7;
reg signed[BW_PER_ACT-1:0] temp_out_ch0[0:3];
reg signed[BW_PER_ACT-1:0] temp_out_ch1[0:3];
reg signed[BW_PER_ACT-1:0] temp_out_ch2[0:3];
reg signed[BW_PER_ACT-1:0] temp_out_ch3[0:3];
reg signed[BW_PER_ACT-1:0] temp_out_ch4[0:3];
reg signed[BW_PER_ACT-1:0] temp_out_ch5[0:3];
reg signed[BW_PER_ACT-1:0] temp_out_ch6[0:3];
reg signed[BW_PER_ACT-1:0] temp_out_ch7[0:3];

//shift register for average output
always @(posedge clk)begin
  if(new)begin
    temp_pool_ch0 <= pool_ch0;
    temp_pool_ch1 <= pool_ch1;
    temp_pool_ch2 <= pool_ch2;
    temp_pool_ch3 <= pool_ch3;
    temp_pool_ch4 <= pool_ch4;
    temp_pool_ch5 <= pool_ch5;
    temp_pool_ch6 <= pool_ch6;
    temp_pool_ch7 <= pool_ch7;
  end
  else begin
    temp_pool_ch0 <= temp_pool_ch4;
    temp_pool_ch1 <= temp_pool_ch5;
    temp_pool_ch2 <= temp_pool_ch6;
    temp_pool_ch3 <= temp_pool_ch7;
    temp_pool_ch4 <= 0;
    temp_pool_ch5 <= 0;
    temp_pool_ch6 <= 0;
    temp_pool_ch7 <= 0;
  end
end
integer i;
//shift register for convolution without adding
always @(posedge clk)begin
  if(new)begin
    for(i=0; i<4; i = i + 1)begin
      temp_out_ch0[i] <= out_ch0[i];
      temp_out_ch1[i] <= out_ch1[i];
      temp_out_ch2[i] <= out_ch2[i];
      temp_out_ch3[i] <= out_ch3[i];
      temp_out_ch4[i] <= out_ch4[i];
      temp_out_ch5[i] <= out_ch5[i];
      temp_out_ch6[i] <= out_ch6[i];
      temp_out_ch7[i] <= out_ch7[i];               
    end
  end
  else begin
    for(i=0; i<4; i = i + 1)begin
      temp_out_ch0[i] <= temp_out_ch1[i];
      temp_out_ch1[i] <= temp_out_ch2[i];
      temp_out_ch2[i] <= temp_out_ch3[i];
      temp_out_ch3[i] <= temp_out_ch4[i];
      temp_out_ch4[i] <= temp_out_ch5[i];
      temp_out_ch5[i] <= temp_out_ch6[i];
      temp_out_ch6[i] <= temp_out_ch7[i];
      temp_out_ch7[i] <= 0;
    end
  end
end

reg signed[31:0]avg_out_ch0,avg_out_ch1,avg_out_ch2,avg_out_ch3;
reg signed[31:0]q_out_ch0,q_out_ch1,q_out_ch2,q_out_ch3;
reg signed[BW_PER_ACT-1:0]result_ch0,result_ch1,result_ch2,result_ch3;
//average pooling and quantization
always @*begin
  avg_out_ch0 = temp_pool_ch0/4;
  avg_out_ch1 = temp_pool_ch1/4;
  avg_out_ch2 = temp_pool_ch2/4;
  avg_out_ch3 = temp_pool_ch3/4;
end

always @*begin
  q_out_ch0 = (avg_out_ch0 + 64) >>>7;
  if(q_out_ch0 > 2047)
    result_ch0 = 2047;
  else if(q_out_ch0 < -2048)
    result_ch0 = -2048;
  else
    result_ch0 = q_out_ch0[11:0];
end

always @*begin
  q_out_ch1 = (avg_out_ch1 + 64) >>>7;
  if(q_out_ch1 > 2047)
    result_ch1 = 2047;
  else if(q_out_ch1 < -2048)
    result_ch1 = -2048;
  else
    result_ch1 = q_out_ch1[11:0];
end

always @*begin
  q_out_ch2 = (avg_out_ch2 + 64) >>>7;
  if(q_out_ch2 > 2047)
    result_ch2 = 2047;
  else if(q_out_ch2 < -2048)
    result_ch2 = -2048;
  else
    result_ch2 = q_out_ch2[11:0];
end

always @*begin
  q_out_ch3 = (avg_out_ch3 + 64) >>>7;
  if(q_out_ch3 > 2047)
    result_ch3 = 2047;
  else if(q_out_ch3 < -2048)
    result_ch3 = -2048;
  else
    result_ch3 = q_out_ch3[11:0];
end

reg signed[BW_PER_ACT:0]res_add_ch0[0:3];
reg signed[BW_PER_ACT:0]q_res_ch0[0:3];
reg signed[BW_PER_ACT-1:0]quan_res_ch0[0:3];

//resblock add and quantization
always @*begin
  res_add_ch0[0] = temp_out_ch0[0] + sram_rdata[47:36];
  res_add_ch0[1] = temp_out_ch0[1] + sram_rdata[35:24];
  res_add_ch0[2] = temp_out_ch0[2] + sram_rdata[23:12];
  res_add_ch0[3] = temp_out_ch0[3] + sram_rdata[11:0];
end

always @*begin
  q_res_ch0[0] = res_add_ch0[0];
  if(q_res_ch0[0] > 2047)
    quan_res_ch0[0] = 2047;
  else if(q_res_ch0[0] < -2048)
    quan_res_ch0[0] = -2048;
  else
    quan_res_ch0[0] = q_res_ch0[0][11:0];
end

always @*begin
  q_res_ch0[1] = res_add_ch0[1];
  if(q_res_ch0[1] > 2047)
    quan_res_ch0[1] = 2047;
  else if(q_res_ch0[1] < -2048)
    quan_res_ch0[1] = -2048;
  else
    quan_res_ch0[1] = q_res_ch0[1][11:0];
end

always @*begin
  q_res_ch0[2] = res_add_ch0[2];
  if(q_res_ch0[2] > 2047)
    quan_res_ch0[2] = 2047;
  else if(q_res_ch0[2] < -2048)
    quan_res_ch0[2] = -2048;
  else
    quan_res_ch0[2] = q_res_ch0[2][11:0];
end

always @*begin
  q_res_ch0[3] = res_add_ch0[3];
  if(q_res_ch0[3] > 2047)
    quan_res_ch0[3] = 2047;
  else if(q_res_ch0[3] < -2048)
    quan_res_ch0[3] = -2048;
  else
    quan_res_ch0[3] = q_res_ch0[3][11:0];
end

always @*begin
  if(avg_enable)
    sram_wdata = {result_ch0,result_ch1,result_ch2,result_ch3};
  else if(res_enable)
    sram_wdata = {quan_res_ch0[0],quan_res_ch0[1],quan_res_ch0[2],quan_res_ch0[3]};
  else
    sram_wdata = {temp_out_ch0[0],temp_out_ch0[1],temp_out_ch0[2],temp_out_ch0[3]};
end

endmodule

module biasnrelu
(
input signed[29*4-1:0] in_pixel,
input signed[7:0] bias,
output signed[30*4-1:0]bias_out
);

reg signed[28:0] pixel[0:3];
reg signed[29:0] temp_pixel[0:3];
reg signed[29:0] relu_pixel[0:3];

always @*begin
  {pixel[0],pixel[1],pixel[2],pixel[3]} = in_pixel;
end

// adding bias 
always @*begin
  temp_pixel[0] = pixel[0] + (bias << 8);
  temp_pixel[1] = pixel[1] + (bias << 8);
  temp_pixel[2] = pixel[2] + (bias << 8);
  temp_pixel[3] = pixel[3] + (bias << 8);
end

always @*begin
  if(temp_pixel[0][29] == 1)
    relu_pixel[0] = 0;
  else  
    relu_pixel[0] = temp_pixel[0];
end

always @*begin
  if(temp_pixel[1][29] == 1)
    relu_pixel[1] = 0;
  else  
    relu_pixel[1] = temp_pixel[1];
end

always @*begin
  if(temp_pixel[2][29] == 1)
    relu_pixel[2] = 0;
  else  
    relu_pixel[2] = temp_pixel[2];
end

always @*begin
  if(temp_pixel[3][29] == 1)
    relu_pixel[3] = 0;
  else  
    relu_pixel[3] = temp_pixel[3];
end

assign bias_out = {relu_pixel[0],relu_pixel[1],relu_pixel[2],relu_pixel[3]};

endmodule

module quantize #(
parameter QUANTIZE_BIT = 30,
parameter ACT_BIT = 12
)

(
input signed[QUANTIZE_BIT-1:0]accumlated_output,
output reg signed[ACT_BIT-1:0]result
);

wire signed[QUANTIZE_BIT-8:0]q_output;
assign q_output = (accumlated_output + 64) >>>7;

always @*begin
  if(q_output > 2047)
    result = 2047;
  else if(q_output < -2048)
    result = -2048;
  else
    result = q_output[11:0];
end

endmodule





  /*
reg [33:0] ch0[0:3];
reg [33:0] ch1[0:3];
reg [33:0] ch2[0:3];
reg [33:0] ch3[0:3];
reg [33:0] ch4[0:3];
reg [33:0] ch5[0:3];
reg [33:0] ch6[0:3];
reg [33:0] ch7[0:3];

reg [34:0] bias_ch0[0:3];
reg [34:0] bias_ch1[0:3];
reg [34:0] bias_ch2[0:3];
reg [34:0] bias_ch3[0:3];
reg [34:0] bias_ch4[0:3];
reg [34:0] bias_ch5[0:3];
reg [34:0] bias_ch6[0:3];
reg [34:0] bias_ch7[0:3];

//plus bias
always @*begin
  bias_ch0[0] = ch0[0] + b0;
  bias_ch0[1] = ch0[1] + b0;
  bias_ch0[2] = ch0[2] + b0;
  bias_ch0[3] = ch0[3] + b0;
  
  bias_ch1[0] = ch1[0] + b1;
  bias_ch1[1] = ch1[1] + b1;
  bias_ch1[2] = ch1[2] + b1;
  bias_ch1[3] = ch1[3] + b1;  
  
  bias_ch2[0] = ch2[0] + b2;
  bias_ch2[1] = ch2[1] + b2;
  bias_ch2[2] = ch2[2] + b2;
  bias_ch2[3] = ch2[3] + b2;  
  
  bias_ch3[0] = ch3[0] + b3;
  bias_ch3[1] = ch3[1] + b3;
  bias_ch3[2] = ch3[2] + b3;
  bias_ch3[3] = ch3[3] + b3;   
  
  bias_ch4[0] = ch4[0] + b4;
  bias_ch4[1] = ch4[1] + b4;
  bias_ch4[2] = ch4[2] + b4;
  bias_ch4[3] = ch4[3] + b4;   
  
  bias_ch5[0] = ch5[0] + b5;
  bias_ch5[1] = ch5[1] + b5;
  bias_ch5[2] = ch5[2] + b5;
  bias_ch5[3] = ch5[3] + b5;     
  
  bias_ch6[0] = ch6[0] + b6;
  bias_ch6[1] = ch6[1] + b6;
  bias_ch6[2] = ch6[2] + b6;
  bias_ch6[3] = ch6[3] + b6;     
  
  bias_ch7[0] = ch7[0] + b7;
  bias_ch7[1] = ch7[1] + b7;
  bias_ch7[2] = ch7[2] + b7;
  bias_ch7[3] = ch7[3] + b7;       
 
end
      
*/
  
