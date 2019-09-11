`timescale 1ns / 1ps

`include "defines.v"
module ex_mem(
		input wire clk,
		input wire rst,
		input wire mem_stall, //表示mem是否需要stall
		input wire ex_stall, //表示ex是否需要stall以保障ex段的输出
		
		input wire[`RegAddrBus] ex_waddr, //来自ex段的写入目的寄存器的地址
		input wire ex_wen, //来自ex段的是否需要写入目的寄存器
		input wire[`RegBus] ex_wdata, //来自ex段的运算结果
		
		input wire ex_hilo_wen,  //表示是否需要写入到Hilo寄存器
		input wire[`RegBus] ex_hi_i, //输入的ex段的hi的值
		input wire[`RegBus] ex_lo_i, //输入的ex段的lo的值
		
		output reg[`RegAddrBus] mem_waddr, //传入到mem段的写入目的寄存器的地址
		output reg mem_wen, //传入到mem段的是否需要写入到目的寄存器
		output reg[`RegBus] mem_wdata, //传入到mem段的最终的运算的结果
		
		output reg mem_hilo_wen,     //表示mem是否需要写入到hilo寄存器
		output reg[`RegBus] mem_hi,  //表示mem写入到hi寄存器的值
		output reg[`RegBus] mem_lo,   //表示mem写入到lo寄存器的值
		
		//lw、sw类的相关输入
		input wire[`AluOpBus] ex_aluop,    //输入的ex的操作符
		input wire[`RegBus] ex_mem_addr,   //ex加载的寄存器的地址
		input wire[`RegBus] ex_reg2,       //ex要存储的数
		
		//lw、sw类的相关的输出
		output reg[`AluOpBus] mem_aluop,
		output reg[`RegBus] mem_mem_addr,
		output reg[`RegBus] mem_reg2
		
    );
	   always@(posedge clk)begin
		 if(rst == `RstEnable) begin
		   mem_waddr <= `NOPRegAddr;
			mem_wen <= `WriteDisable;
			mem_wdata <= `ZeroWord;
			mem_hilo_wen <= `WriteDisable;
			mem_hi <= `ZeroWord;
			mem_lo <= `ZeroWord;
		 end else if((ex_stall == 1'b1) && (mem_stall == 1'b0)) begin
			mem_waddr <= `NOPRegAddr;
			mem_wen <= `WriteDisable;
			mem_wdata <= `ZeroWord;        //如果ex段需要暂停而mem段不需要，则将空值输出给下一个mem段
		 end else if(ex_hilo_wen == 1'b1) begin
			mem_waddr <= `NOPRegAddr;
			mem_wen <= `WriteDisable;
			mem_wdata <= `ZeroWord;
			mem_hilo_wen <= `WriteEnable;
			mem_hi <= ex_hi_i;
			mem_lo <= ex_lo_i;
		 end else if(ex_stall == 1'b0) begin
			mem_waddr <= ex_waddr;
			mem_wen <= ex_wen;
			mem_wdata <= ex_wdata;
			mem_hilo_wen <= `WriteDisable;
			mem_hi <= `ZeroWord;
			mem_lo <= `ZeroWord;
			mem_aluop <= ex_aluop;
			mem_mem_addr <= ex_mem_addr;
			mem_reg2 <= ex_reg2;
		 end else begin
			mem_waddr <= ex_waddr;
			mem_wen <= ex_wen;
			mem_wdata <= ex_wdata;
			mem_hilo_wen <= `WriteDisable;
			mem_hi <= `ZeroWord;
			mem_lo <= `ZeroWord;
		 end
      end	
endmodule
