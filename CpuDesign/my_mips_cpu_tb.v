`timescale 1ns / 1ps

`include "defines.v"

module my_mips_cpu_tb;

	// Inputs
	reg clk;
	reg rst;

	// Instantiate the Unit Under Test (UUT)
	my_mips_cpu uut (
		.clk(clk), 
		.rst(rst)
	);
	initial begin
		clk = 1'b0;
		forever #10 clk = ~clk;
	end
	initial begin
		// Initialize Inputs
		rst = 1'b1;
		#195 rst = 1'b0;
		// Wait 100 ns for global reset to finish
		#1000 rst = 1'b1;
      $stop;
		// Add ;stimulus here

	end
      
endmodule

