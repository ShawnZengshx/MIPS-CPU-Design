`timescale 1ns / 1ps

// 用于乘法、除法的寄存器
`include "defines.v"
module hi_lo_reg(
		input wire clk,
		input wire rst,
		
		input wire we, //写使能端
		input wire[`RegBus] hi_data_i, //要写入hi寄存器的值
		input wire[`RegBus] lo_data_i, //要写入lo寄存器的值
		
		output reg[`RegBus] hi_data_o, //hi寄存器的读取的值
		output reg[`RegBus] lo_data_o  //lo寄存器的读取的值
    );
		
		// reg[`RegBus] hidatamem[0:1];
		// reg[`RegBus] lodatamem[0:1];
		always@(posedge clk) begin
			if(rst == `RstEnable) begin
				hi_data_o <= `ZeroWord;
				lo_data_o <= `ZeroWord;
				// hidatamem[0] <= `ZeroWord;
				// lodatamem[0] <= `ZeroWord;
			end else if(we == `WriteEnable) begin
				hi_data_o <= hi_data_i;
				lo_data_o <= lo_data_i;
				// hidatamem[1] <= hi_data_i;
				// lodatamem[1] <= lo_data_i;
			end
		end

endmodule
