`timescale 1ns / 1ps

`include "defines.v"
module booth_tb;

	// Inputs
	reg clk;
	reg rst;
	reg [31:0] mult_op1;
	reg [31:0] mult_op2;
	reg start;

	// Outputs
	wire is_done;
	wire [63:0] result;

	// Instantiate the Unit Under Test (UUT)
	booth_mult uut (
		.clk(clk), 
		.rst(rst), 
		.mult_op1(mult_op1), 
		.mult_op2(mult_op2), 
		.start(start), 
		.is_done(is_done), 
		.result(result)
	);
	initial begin
		clk = 0;
		forever #10 clk = ~clk;
	end
	initial begin
		// Initialize Inputs
		rst = 1;
		mult_op1 = 0;
		mult_op2 = 0;
		start = 0;
		# 20;
		rst = 0;
		start = 1;
		mult_op1=32'h00_00_00_ff;
		mult_op2=32'h80_00_00_ff;
		// Wait 100 ns for global reset to finish
		#1000;
		$stop;
        
		// Add stimulus here

	end
      
endmodule

