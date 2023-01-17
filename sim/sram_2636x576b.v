//==================================================================================================
//  Note:          Use only for teaching materials of IC Design Lab, NTHU.
//  Copyright: (c) 2022 Vision Circuits and Systems Lab, NTHU, Taiwan. ALL Rights Reserved.
//==================================================================================================


module sram_2636x576b #(       //for weight
parameter WEIGHT_PER_ADDR = 72,  //9 weight per kernel, 8 kernel
parameter BW_PER_PARAM = 8
)
(
input clk,
input csb,  //chip enable
input wsb,  //write enable
input [WEIGHT_PER_ADDR*BW_PER_PARAM-1:0] wdata, //write data
input [12-1:0] waddr, //write address
input [12-1:0] raddr, //read address

output reg [WEIGHT_PER_ADDR*BW_PER_PARAM-1:0] rdata
);

reg [WEIGHT_PER_ADDR*BW_PER_PARAM-1:0] mem [0:2636-1];
reg [WEIGHT_PER_ADDR*BW_PER_PARAM-1:0] _rdata;

always @(posedge clk) begin
    if(~csb && ~wsb)
        mem[waddr] <= wdata;
end

always @(posedge clk) begin
    if(~csb)
        _rdata <= mem[raddr];
end

always @* begin
    rdata = #(1) _rdata;
end

task load_param(
    input integer index,
    input [WEIGHT_PER_ADDR*BW_PER_PARAM-1:0] param_input
);
    mem[index] = param_input;
endtask

endmodule