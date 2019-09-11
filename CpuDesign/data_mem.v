`timescale 1ns / 1ps

`include "defines.v"
module data_mem(
		input wire clk,
		input wire ce,				//数据存储器的使能信号
		input wire[`RegBus] wdata, //需要写入的信号
		input wire[`DataAddrBus] addr,  //需要访问的目标地址
		input wire we,     //写使能信号
		output reg[`RegBus] rdata   //从中读取的数据
    );
		//定义四个字节数组
		reg[`RegBus] data_mem[0:`DataMemNum - 1];

		
		//大端存储
		//写操作
		always@(posedge clk) begin
			if(ce == `ChipDisable) begin
			end else if(we == `WriteEnable) begin
				data_mem[addr >> 2] = wdata;
			end
		end

		//读操作
		always@(*) begin
			if(ce == `ChipDisable) begin
				rdata <= `ZeroWord;
			end else if(we == `WriteDisable) begin
				rdata <= data_mem[addr >> 2];
			end else begin
				rdata <= `ZeroWord;
			end
		end
		

endmodule
