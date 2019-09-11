`timescale 1ns / 1ps

`include "defines.v"
module mem(
		input wire rst,
		
		input wire[`RegAddrBus] mem_waddr, //mem段的写入的寄存器地址
		input wire mem_wen, //mem段的是否需要写入寄存器
		input wire[`RegBus] mem_data, //mem段的结果
		
		input wire mem_hilo_wen,    //表示mem是否需要写入hilo寄存器
		input wire[`RegBus] mem_hi_i,    //mem收到的hi的值
		input wire[`RegBus] mem_lo_i,    //mem收到的lo的值
		
		output reg[`RegAddrBus] mem_waddro,
		output reg mem_weno,
		output reg[`RegBus] mem_datao,
		
		output reg mem_hilo_wen_o,
		output reg[`RegBus] mem_hi_o,
		output reg[`RegBus] mem_lo_o,
		
		//lw、sw相关
		input wire[`AluOpBus] aluop_i,
		input wire[`RegBus] mem_addr_i,
		input wire[`RegBus] reg2_i,
		
		input wire[`RegBus] mem_data_i,   //从数据存储器读取的数据
		
		output reg[`RegBus] mem_addr_o,
		output reg mem_we_o,
		output reg[`RegBus] mem_data_o,
		output reg mem_ce_o
    );
		
		always@(*)begin
		 if(rst == `RstEnable) begin
			mem_waddro <= `NOPRegAddr;
			mem_weno <= `WriteDisable;
			mem_datao <= `ZeroWord;
			mem_hilo_wen_o <= `WriteDisable;
			mem_hi_o <= `ZeroWord;
			mem_lo_o <= `ZeroWord;
			mem_addr_o <= `ZeroWord;
			mem_we_o <= `WriteDisable;
			mem_data_o <= `ZeroWord;
			mem_ce_o <= `ChipDisable;
		 end else begin
			mem_waddro <= mem_waddr;
			mem_weno <= mem_wen;
			mem_datao <= mem_data;
			mem_hilo_wen_o <= mem_hilo_wen;
			mem_hi_o <= mem_hi_i;
			mem_lo_o <= mem_lo_i;
			mem_we_o <= `WriteDisable;
			mem_addr_o <= `ZeroWord;
			mem_ce_o <= `ChipDisable;
			case(aluop_i) 
				`EXE_LW_OP: begin
					mem_addr_o <= mem_addr_i;
					mem_we_o <= `WriteDisable;
					mem_datao <= mem_data_i;
					mem_ce_o <= `ChipEnable;
				end
				`EXE_SW_OP: begin
					mem_addr_o <= mem_addr_i;
					mem_we_o <= `WriteEnable;
					mem_data_o <= reg2_i;
					mem_ce_o <= `ChipEnable;
				end
			endcase
		 end
		end
		
endmodule
