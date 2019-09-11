`timescale 1ns / 1ps

`include "defines.v"
module regfile(
		input wire clk,		// regfile其实就是wb段
		input wire rst,
		
		//写端口
		input wire we, //写使能信号
		input wire [`RegAddrBus] waddr, //要写入的寄存器的地址
		input wire [`RegBus] wdata, //要写入就寄存器的数据
		
		//读端口1
		input wire re1, //读使能端
		input wire[`RegAddrBus] raddr1, //第一个寄存器读取数据的地址
		output reg[`RegBus] rdata1,// 第一个端口读出的数据
		
		//读端口2
		input wire re2, 
		input wire[`RegAddrBus] raddr2,
		output reg[`RegBus] rdata2
		
    );
		reg[`RegBus] regs[0: `RegNum-1]; // 定义32个32位的寄存器
		initial $readmemh("regsinit", regs);
		
		//写操作
		always@(posedge clk)begin
		 if(rst == `RstDisable) begin
			if((we == `WriteEnable)&& (waddr != 5'b0)) begin
				regs[waddr] <= wdata;
			end else if((we == `WriteEnable) && (waddr == 5'b0)) begin
				regs[waddr] <= `ZeroWord;
			end
		 end
		end
		//读端口1的操作
		always@(*)begin
		 if (rst == `RstEnable) begin
			rdata1 <= `ZeroWord;
		 end else if (raddr1 == 5'b0) begin
			rdata1 <= `ZeroWord;
		end else if((raddr1 == waddr) && (we == `WriteEnable)
						&& (re1 == `ReadEnable))begin  //这里解决了相隔两条指令的数据相关
			rdata1 <= wdata;
		end else if(re1 == `ReadEnable)begin
			rdata1 <= regs[raddr1];
		end else begin
			rdata1 <= `ZeroWord;
			end
		end
		
		//读端口2的操作
		
		always@(*)begin
		 if(rst == `RstEnable) begin
			rdata2 <= `ZeroWord;
		 end else if (raddr2 == 5'b0) begin
			rdata2 <= `ZeroWord;
		end else if((raddr2 == waddr) && (we == `WriteEnable)
						&& (re2 == `ReadEnable))begin
			rdata2 <= wdata;
		end else if(re2 == `ReadEnable)begin
			rdata2 <= regs[raddr2];
		end else begin
			rdata2 <= `ZeroWord;
			end
		end
		
			
endmodule
