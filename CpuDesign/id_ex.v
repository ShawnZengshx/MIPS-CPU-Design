`timescale 1ns / 1ps

`include "defines.v"
module id_ex(
		input wire clk,
		input wire rst,
		input wire id_stall,	//判断id段是否需要进行暂停
		input wire ex_stall, //判断ex段是否需要进行暂停以保障输出
		
		input wire [`AluOpBus] id_aluop, //从id段得到的alu的操作符
		input wire [`RegBus]	id_reg1, //从id段得到的源操作数1
		input wire [`RegBus] id_reg2, //从id段得到的源操作数2
		input wire [`RegAddrBus] id_waddr, //判断从id来的操作的结果写入目的寄存器的地址
		input wire id_wen, //判断是否要写入目的寄存器
		
		//分支控制的输入
		input wire id_is_in_delay_slot, //id段传输的信号判断id段是否处于分支延迟槽
		input wire [`RegBus] id_link_address, //保存着id段分支前返回地址
		input wire next_is_in_delay_slot, //判断下一条指令是否在延迟槽
		input wire id_if_branch, //表示id目前指令是否是分支指令
		
		//lw、sw类的指令的控制
		input wire[`RegBus] id_inst,  //来自id段的指令
		output reg[`RegBus] ex_inst,  //输出到ex段的指令
		//分支控制的输出
		output reg ex_is_in_delay_slot,  //表示ex段是否位于分支延迟槽
		output reg [`RegBus] ex_link_address, //保存着返回地址
		output reg is_in_delay_slot_o,  //用于输出当前译码指令是否处在分支延迟槽
		output reg ex_if_branch,  //表示ex段指令是否是分支指令

		output reg[`AluOpBus] ex_aluop, //写入到ex段的alu的操作符
		output reg[`RegBus] ex_reg1, //写入到ex段的alu的源操作数1
		output reg[`RegBus] ex_reg2, //写入到ex段的alu的源操作数2
		output reg[`RegAddrBus] ex_waddr, //alu运算结果写入到的目的寄存器的地址
		output reg ex_wen //判断是否需要写入到目的寄存器
		
    );
	 
	 //接下来需要做的就是把id段的各项操作数、操作符、地址写入到ex段
		always@(posedge clk)begin
		 if(rst == `RstEnable) begin
			ex_aluop <= `EXE_NOP_OP;
			ex_reg1 <= `ZeroWord;
			ex_reg2 <= `ZeroWord;
			ex_waddr <= `NOPRegAddr;
			ex_wen <= `WriteDisable;
			ex_link_address <= `ZeroWord;
			ex_is_in_delay_slot <= 1'b0;
			is_in_delay_slot_o <= 1'b0;
			ex_if_branch <= 1'b0;
		 end else if((id_stall == 1'b1) && (ex_stall == 1'b0)) begin
			ex_aluop <= `EXE_NOP_OP;
			ex_reg1 <= `ZeroWord;
			ex_reg2 <= `ZeroWord;
			ex_waddr <= `NOPRegAddr;
			ex_wen <= `WriteDisable;		//当id段需要暂停而ex段不需要时，则将空指令输出到ex段
			ex_link_address <= `ZeroWord;
			ex_is_in_delay_slot <= 1'b0;
			ex_if_branch <= 1'b0;
		 end else if(id_stall == 1'b0) begin    //如果译码段没有被暂停
			ex_aluop <= id_aluop;
			ex_reg1 <= id_reg1;
			ex_reg2 <= id_reg2;
			ex_waddr <= id_waddr;
			ex_wen <= id_wen;
			ex_link_address <= id_link_address;
			ex_is_in_delay_slot <= id_is_in_delay_slot;
			is_in_delay_slot_o <= next_is_in_delay_slot;
			ex_if_branch <= id_if_branch;
			ex_inst <= id_inst;
		 end
		end


endmodule
