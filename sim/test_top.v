`timescale 1ns/100ps

`define CYCLE 10
`define END_CYCLES 1000000 // you can enlarge the cycle count limit for longer simulation
`define FLAG_DUMPWV 1

module test_top;

// ===== module I/O ===== //
reg clk;
reg srst_n;
reg enable;
wire valid;

// ===== instantiation ===== //
top u0(.clk(clk), .srst_n(srst_n), .enable(enable), .valid(valid));


// ===== waveform dumpping ===== //

initial begin
    if(`FLAG_DUMPWV)begin
        $fsdbDumpfile("final.fsdb");
        $fsdbDumpvars("+mda");
    end
end


// ===== system reset ===== //
initial begin
    clk = 0;
    while(1) #(`CYCLE/2) clk = ~clk;
end

initial begin
        srst_n = 1;
        enable = 0;
        @(negedge clk); srst_n = 1'b0;
        @(negedge clk); srst_n = 1'b1; enable = 1'b1;
        @(negedge clk); enable = 1'b0;
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


endmodule