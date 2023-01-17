//==================================================================================================
//  Note:          Use only for teaching materials of IC Design Lab, NTHU.
//  Copyright: (c) 2022 Vision Circuits and Systems Lab, NTHU, Taiwan. ALL Rights Reserved.
//==================================================================================================

module sram_50176x48b #(     //for activation
parameter CH_NUM = 1,
parameter ACT_PER_ADDR = 4,
parameter BW_PER_ACT = 12
)
(
input clk,
input [CH_NUM*ACT_PER_ADDR-1:0] wordmask,  //4 bits
input csb,  //chip enable
input wsb,  //write enable
input msb, //mode enable
input [CH_NUM*ACT_PER_ADDR*BW_PER_ACT-1:0] wdata, //write data 48 bits
input [16-1:0] waddr, //write address
input [16-1:0] raddr, //read address

output reg [CH_NUM*ACT_PER_ADDR*BW_PER_ACT-1:0] rdata //read data 48 bits
);

reg [CH_NUM*ACT_PER_ADDR*BW_PER_ACT-1:0] _rdata;
reg [CH_NUM*ACT_PER_ADDR*BW_PER_ACT-1:0] mem [0:50176-1];
wire [CH_NUM*ACT_PER_ADDR*BW_PER_ACT-1:0] bit_mask;


assign bit_mask = {{12{wordmask[3]}}, {12{wordmask[2]}}, {12{wordmask[1]}}, {12{wordmask[0]}}};

always @(posedge clk) begin
    if(~csb && ~wsb && msb) begin
        mem[waddr] <= (wdata & ~(bit_mask)) | (mem[waddr] & bit_mask);
    end
    else if(~csb && ~wsb && ~msb)begin
        mem[waddr] <= ({4{wdata[47:36]}} & ~(bit_mask)) | (mem[waddr] & bit_mask);
        mem[waddr+28*28] <= ({4{wdata[35:24]}} & ~(bit_mask)) | (mem[waddr] & bit_mask);
        mem[waddr+2*28*28] <= ({4{wdata[23:12]}} & ~(bit_mask)) | (mem[waddr] & bit_mask);
        mem[waddr+3*28*28] <= ({4{wdata[11:0]}} & ~(bit_mask)) | (mem[waddr] & bit_mask);
    end
end

always @(posedge clk) begin
    if(~csb) begin
        _rdata <= mem[raddr];
    end
end

always @* begin
    rdata = #(1) _rdata;
end

task load_act(
    input integer index,
    input [CH_NUM*ACT_PER_ADDR*BW_PER_ACT-1:0] param_input
);
    mem[index] = param_input;
endtask

task reset_sram;
    integer i;
    begin
        for(i=0;i<18;i=i+1)begin
            mem[i] = 192'bX;
        end
    end
endtask

endmodule