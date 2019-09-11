`timescale 1ns / 1ps

`include "defines.v"
module pc(
		input wire clk,
		input wire rst,
		input wire pc_stall, //输入信号表示pc阶段是否需要暂停
		input wire if_branch, //判断是否是分支指令的结果，pc需要进行修改，1表示需要进行修改
		input wire[`RegBus] target_pc, //表示如果实现的是分支预测指令，则将分值的目标地址赋给pc
		
		output reg[`InstAddrBus] pc,
      output reg ce		//片选信号
		
	);
	always @(posedge clk) begin
	 if(rst == `RstEnable) begin
		ce <= `ChipDisable;
	 end else begin
		ce <= `ChipEnable;
	 end
	end
	
	always@(posedge clk) begin
	 if(ce == `ChipDisable) begin
		pc <= 32'h00000000;	//指令寄存器禁用时，pc的值为0
	 end else if(pc_stall == 1'b0) begin //如果没有stall
		if(if_branch == 1'b1) begin       //如果是分支指令，则将地址修改为分支目标的地址
			pc <= target_pc;
		end else begin
			pc <= pc + 4'h4;		//指令寄存器使能的时候，pc的值每周期+4
		end
	 end
	end
		

endmodule
