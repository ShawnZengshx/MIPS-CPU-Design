`timescale 1ns / 1ps

module inst_rom_tb;

	// Inputs
	reg ce;
	reg [31:0] addr;

	// Outputs
	wire [31:0] inst;

	// Instantiate the Unit Under Test (UUT)
	inst_rom uut (
		.ce(ce), 
		.addr(addr), 
		.inst(inst)
	);

	initial begin
		// Initialize Inputs
		#20;
		ce = 1;
		addr = 8'h 00000004;

		// Wait 100 ns for global reset to finish
		#100;
      $stop;  
		// Add stimulus here

	end
      
endmodule

