`timescale 1ns / 1ps

`include "defines.v"
module mem_wb(
		input wire clk,
		input wire rst,
		input wire mem_stall, //表示mem段是否需要stall
		input wire wb_stall,  //表示wb段是否需要stall
		
		input wire[`RegAddrBus] mem_waddr, //来自mem段的写入目的寄存器的地址
		input wire mem_wen, //来自mem段的是否需要写入目的寄存器
		input wire[`RegBus] mem_wdata, //来自mem段的最终的结果
		
		input wire mem_hilo_wen,
		input wire[`RegBus] mem_hi_i,
		input wire[`RegBus] mem_lo_i,
		
		output reg[`RegAddrBus] wb_waddr, //最终写回的目的寄存器的地址
		output reg wb_wen, //是否需要将结果写回到目的寄存器
		output reg[`RegBus] wb_wdata, //最终写回的结果
		
		output reg wb_hilo_wen,
		output reg[`RegBus] wb_hi_o,
		output reg[`RegBus] wb_lo_o

    );
		
		always@(posedge clk) begin
		 if(rst == `RstEnable) begin
			wb_waddr <= `NOPRegAddr;
			wb_wen <= `WriteDisable;
			wb_wdata <= `ZeroWord;
		 end else if((mem_stall == 1'b1) && (wb_stall == 1'b0)) begin
			wb_waddr <= `NOPRegAddr;
			wb_wen <= `WriteDisable;
			wb_wdata <= `ZeroWord;    //如果mem段需要暂停而wb段不需要则将空值写给wb
		 end else begin
			wb_waddr <= mem_waddr;
			wb_wen <= mem_wen;
			wb_wdata <= mem_wdata;
		 end
		end

endmodule
