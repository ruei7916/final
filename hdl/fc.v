module fc #(
parameter CH_NUM = 1,  //channel number
parameter ACT_PER_ADDR = 4, //how many pixel
parameter BW_PER_ACT = 12, //bit per pixel
parameter WEIGHT_PER_ADDR = 9, //how many weight per address
parameter BIAS_PER_ADDR = 1,
parameter BW_PER_PARAM = 8, //weight and bias bit numbers
parameter CONV3_BW = BW_PER_ACT+BW_PER_PARAM+3
) 
(
input signed[BW_PER_ACT-1:0]f0,//1 pixel 12 bits
input clk,
input srst_n,
input fc_enable,
input [47:0]weight,
input [47:0]bias,
output reg[ACT_PER_ADDR*BW_PER_ACT-1:0]sram_wdata,  //six pixels output, first output 0~3 channel, second output 4~5 channel
output reg[5:0]counter
);

reg signed[7:0] w[0:5];
reg signed[7:0] b[0:5];
reg [5:0]next_counter;

always @*begin
  {w[0],w[1],w[2],w[3],w[4],w[5]} = weight;
  {b[0],b[1],b[2],b[3],b[4],b[5]} = bias;
end



always @*begin
  if(fc_enable)
    next_counter = counter + 1;
  else
    next_counter = 0;
end

always @(posedge clk)begin
  if(~srst_n)
    counter <= 0;
  else
    counter <= next_counter;
end

reg signed[20-1:0]ch[0:5];
reg signed[27-1:0]temp_out_ch[0:5];
reg signed[27-1:0]out_ch[0:5];
always @*begin
  ch[0] = f0*w[0];
  ch[1] = f0*w[1];
  ch[2] = f0*w[2];
  ch[3] = f0*w[3];
  ch[4] = f0*w[4];
  ch[5] = f0*w[5];
end

always @*begin
  if(counter == 2'd0)begin
    temp_out_ch[0] = ch[0] + (b[0] << 8);
    temp_out_ch[1] = ch[1] + (b[1] << 8);
    temp_out_ch[2] = ch[2] + (b[2] << 8);
    temp_out_ch[3] = ch[3] + (b[3] << 8);
    temp_out_ch[4] = ch[4] + (b[4] << 8);
    temp_out_ch[5] = ch[5] + (b[5] << 8);
  end
  else  begin
    temp_out_ch[0] = out_ch[0] + ch[0];
    temp_out_ch[1] = out_ch[1] + ch[1];
    temp_out_ch[2] = out_ch[2] + ch[2];
    temp_out_ch[3] = out_ch[3] + ch[3];
    temp_out_ch[4] = out_ch[4] + ch[4];
    temp_out_ch[5] = out_ch[5] + ch[5];
  end
end
integer i;
always @(posedge clk)begin
  for(i=0; i<6; i=i+1)begin
    out_ch[i] <= temp_out_ch[i];
  end
end

// rouding and quantize and output and store
reg signed[12-1:0]result[0:5];
wire signed[27-1:0]q_output[0:5];
assign q_output[0] = (out_ch[0] + 64) >>>7;
assign q_output[1] = (out_ch[1] + 64) >>>7;
assign q_output[2] = (out_ch[2] + 64) >>>7;
assign q_output[3] = (out_ch[3] + 64) >>>7;
assign q_output[4] = (out_ch[4] + 64) >>>7;
assign q_output[5] = (out_ch[5] + 64) >>>7;

always @*begin
  if(q_output[0] > 2047)
    result[0] = 2047;
  else if(q_output[0] < -2048)
    result[0] = -2048;
  else
    result[0] = q_output[0][11:0];
end

always @*begin
  if(q_output[1] > 2047)
    result[1] = 2047;
  else if(q_output[1] < -2048)
    result[1] = -2048;
  else
    result[1] = q_output[1][11:0];
end 

always @*begin
  if(q_output[2] > 2047)
    result[2] = 2047;
  else if(q_output[2] < -2048)
    result[2] = -2048;
  else
    result[2] = q_output[2][11:0];
end

always @*begin
  if(q_output[3] > 2047)
    result[3] = 2047;
  else if(q_output[3] < -2048)
    result[3] = -2048;
  else
    result[3] = q_output[3][11:0];
end

always @*begin
  if(q_output[4] > 2047)
    result[4] = 2047;
  else if(q_output[4] < -2048)
    result[4] = -2048;
  else
    result[4] = q_output[4][11:0];
end 

always @*begin
  if(q_output[5] > 2047)
    result[5] = 2047;
  else if(q_output[5] < -2048)
    result[5] = -2048;
  else
    result[5] = q_output[5][11:0];
end

reg [11:0]temp_result[0:1];

always @(posedge clk)begin
  if(counter == 6'd0)begin
    temp_result[0] <= result[4];
    temp_result[1] <= result[5];
  end
end

always @*begin
  if(counter == 6'd0)
    sram_wdata = {result[0],result[1],result[2],result[3]};
  else
    sram_wdata = {temp_result[0],temp_result[1],result[2],result[3]};
end

endmodule



