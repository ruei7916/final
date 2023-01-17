module globalave #(
parameter CH_NUM = 1,  //channel number
parameter ACT_PER_ADDR = 4, //how many pixel
parameter BW_PER_ACT = 12, //bit per pixel
parameter WEIGHT_PER_ADDR = 9, //how many weight per address
parameter BIAS_PER_ADDR = 1,
parameter BW_PER_PARAM = 8, //weight and bias bit numbers
parameter  CONV3_BW = BW_PER_ACT+BW_PER_PARAM+3
) (
input [4*ACT_PER_ADDR*BW_PER_ACT-1:0]f0,//4*4*12
input clk,
input srst_n,
input global_enable,
output [ACT_PER_ADDR*BW_PER_ACT-1:0]sram_wdata
);
//input average pooling has width 8*8 four address
reg [1:0]counter,next_counter;

always @*begin
  if(global_enable)
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

reg signed[17-1:0]add_0,add_1;    //4*4 sums up first two row and repeat 4 times total extral bits 2
reg signed[17-1:0]temp_add_0,temp_add_1; //4*4 third and fourth row and repeat 4 times total extral bits 2
reg signed[15-1:0]sum_0,sum_1; //first two rows sums up,third and fourth rows sums up extral bit 3
reg signed[18-1:0]out;

always @(posedge clk)begin
  if(~srst_n)begin
    add_0 <= 0;
    add_1 <= 0;
  end
  else begin
    add_0 <= temp_add_0;
    add_1 <= temp_add_1;
  end
end

always @*begin
  if(counter == 2'd0)begin
    temp_add_0 = sum_0;
    temp_add_1 = sum_1;
  end
  else begin
    temp_add_0 = add_0 + sum_0;
    temp_add_1 = add_1 + sum_1;
  end
end
//first two rows sums up,third and fourth rows sums up
always @*begin
  sum_0 = f0[191:180] + f0[179:168] + f0[167:156] + f0[155:144] + f0[143:132] + f0[131:120] + f0[119:108] + f0[107:96];
  sum_1 = f0[95:84] + f0[83:72] + f0[71:60] + f0[59:48] + f0[47:36] + f0[35:24] + f0[23:12] + f0[11:0];
end

always @*begin
  out = (add_0 + add_1)/64;
end
reg signed[11:0]result;

always @*begin
  if(out > 2047)
    result = 2047;
  else if(out < -2048)
    result = -2048;
  else
    result = out[11:0];
end

assign sram_wdata = {result,36'd0};

endmodule


/*
191 180
179 168
167 156
155 144
143 132
131 120
119 108
107 96
95  84
83  72
71  60
59  48
47  36
35  24
23  12
11  0
*/

