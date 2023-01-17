module CONV3 #(
parameter CH_NUM = 1,  //channel number
parameter ACT_PER_ADDR = 4, //how many pixel
parameter BW_PER_ACT = 12, //bit per pixel
parameter WEIGHT_PER_ADDR = 9, //how many weight per address
parameter BIAS_PER_ADDR = 1,
parameter BW_PER_PARAM = 8, //weight and bias bit numbers
parameter  CONV3_BW = BW_PER_ACT+BW_PER_PARAM+3
) (
input [4*ACT_PER_ADDR*BW_PER_ACT-1:0]f0,//4*4*12

input [WEIGHT_PER_ADDR*BW_PER_PARAM-1:0]w0,//9*8
input [WEIGHT_PER_ADDR*BW_PER_PARAM-1:0]w1,
input [WEIGHT_PER_ADDR*BW_PER_PARAM-1:0]w2,
input [WEIGHT_PER_ADDR*BW_PER_PARAM-1:0]w3,
input [WEIGHT_PER_ADDR*BW_PER_PARAM-1:0]w4,
input [WEIGHT_PER_ADDR*BW_PER_PARAM-1:0]w5,
input [WEIGHT_PER_ADDR*BW_PER_PARAM-1:0]w6,
input [WEIGHT_PER_ADDR*BW_PER_PARAM-1:0]w7,

output [CONV3_BW*4-1:0] conv3_f_ch0,
output [CONV3_BW*4-1:0] conv3_f_ch1,
output [CONV3_BW*4-1:0] conv3_f_ch2,
output [CONV3_BW*4-1:0] conv3_f_ch3,
output [CONV3_BW*4-1:0] conv3_f_ch4,
output [CONV3_BW*4-1:0] conv3_f_ch5,
output [CONV3_BW*4-1:0] conv3_f_ch6,
output [CONV3_BW*4-1:0] conv3_f_ch7,
input clk
);

dwc2x2 u0(.clk(clk),.f(f0), .w(w0),.c(conv3_f_ch0));
dwc2x2 u1(.clk(clk),.f(f0), .w(w1),.c(conv3_f_ch1));
dwc2x2 u2(.clk(clk),.f(f0), .w(w2),.c(conv3_f_ch2));
dwc2x2 u3(.clk(clk),.f(f0), .w(w3),.c(conv3_f_ch3));
dwc2x2 u4(.clk(clk),.f(f0), .w(w4),.c(conv3_f_ch4));
dwc2x2 u5(.clk(clk),.f(f0), .w(w5),.c(conv3_f_ch5));
dwc2x2 u6(.clk(clk),.f(f0), .w(w6),.c(conv3_f_ch6));
dwc2x2 u7(.clk(clk),.f(f0), .w(w7),.c(conv3_f_ch7));

endmodule



module dwc2x2 #(
parameter CH_NUM = 1,  //channel number
parameter ACT_PER_ADDR = 4, //how many pixel
parameter BW_PER_ACT = 12, //bit per pixel
parameter WEIGHT_PER_ADDR = 9, //how many weight per address
parameter BIAS_PER_ADDR = 1,
parameter BW_PER_PARAM = 8, //weight and bias bit numbers
parameter  CONV3_BW = BW_PER_ACT+BW_PER_PARAM+3
)(
input [BW_PER_ACT*16-1:0]f,//12*16
input [WEIGHT_PER_ADDR*BW_PER_PARAM-1:0]w, //9*8
input clk,
output [CONV3_BW*4-1:0]c
);
    conv ch0(.clk(clk),.f({f[191:156],f[143:108],f[95:60]}),.w(w),.conv(c[91:69]));
    conv ch1(.clk(clk),.f({f[179:144],f[131:96],f[83:48]}),.w(w),.conv(c[68:46]));
    conv ch2(.clk(clk),.f({f[143:108],f[95:60],f[47:12]}),.w(w),.conv(c[45:23]));
    conv ch3(.clk(clk),.f({f[131:96],f[83:48],f[35:0]}),.w(w),.conv(c[22:0]));
endmodule

module conv#(
parameter CH_NUM = 1,  //channel number
parameter ACT_PER_ADDR = 4, //how many pixel
parameter BW_PER_ACT = 12, //bit per pixel
parameter WEIGHT_PER_ADDR = 9, //how many weight per address
parameter BIAS_PER_ADDR = 1,
parameter BW_PER_PARAM = 8 //weight and bias bit numbers
)
(
input clk,
input signed[BW_PER_ACT*9-1:0]f,
input signed[BW_PER_PARAM*WEIGHT_PER_ADDR-1:0]w,
output signed[BW_PER_ACT+BW_PER_PARAM+3-1:0]conv //9number , bit have to add more 3 

);
    wire signed [BW_PER_ACT+BW_PER_PARAM-1:0]temp[0:8];
    wire signed[7:0]ww[0:8];
    wire signed [11:0]ff[0:8];
    reg signed[BW_PER_ACT+BW_PER_PARAM+1-1:0]conv1,conv2,conv3;

    assign ww[0]=w[71:64];
    assign ww[1]=w[63:56];
    assign ww[2]=w[55:48];
    assign ww[3]=w[47:40];
    assign ww[4]=w[39:32];
    assign ww[5]=w[31:24];
    assign ww[6]=w[23:16];
    assign ww[7]=w[15:8];
    assign ww[8]=w[7:0];
    assign ff[0]=f[107:96];
    assign ff[1]=f[95:84];
    assign ff[2]=f[83:72];
    assign ff[3]=f[71:60];
    assign ff[4]=f[59:48];
    assign ff[5]=f[47:36];
    assign ff[6]=f[35:24];
    assign ff[7]=f[23:12];
    assign ff[8]=f[11:0];
    assign temp[0]=ff[0]*ww[0];
    assign temp[1]=ff[1]*ww[1];
    assign temp[2]=ff[2]*ww[2];
    assign temp[3]=ff[3]*ww[3];
    assign temp[4]=ff[4]*ww[4];
    assign temp[5]=ff[5]*ww[5];
    assign temp[6]=ff[6]*ww[6];
    assign temp[7]=ff[7]*ww[7];
    assign temp[8]=ff[8]*ww[8];

    always @(posedge clk) begin
        conv1<=temp[0]+temp[1]+temp[2];
        conv2<=temp[3]+temp[4]+temp[5];
        conv3<=temp[6]+temp[7]+temp[8];
    end
    assign conv=conv1+conv2+conv3;
endmodule









