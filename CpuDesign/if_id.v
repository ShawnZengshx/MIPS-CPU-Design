`timescale 1ns / 1ps

`include "defines.v"
module if_id(
		input wire clk,
		input wire rst,
		input wire if_stall, //表示if段是否需要暂停
		input wire id_stall, //判断id段是否需要暂停，以明确if段的指令的输出情况
		//指令宽度为32
		input wire[`InstAddrBus] if_pc, //取指阶段所取得的指令的地址
		input wire[`InstBus] if_inst, //取指阶段所取得的指令
		
		output reg[`InstAddrBus] id_pc, //译码阶段指令对应的地址
		output reg[`InstBus] id_inst //译码阶段所对应的指令
		
    );
		always@(posedge clk)begin
		 if(rst == `RstEnable) begin
			id_pc <= `ZeroWord;
			id_inst <= `ZeroWord;
		 end else if((if_stall == 1'b1) && (id_stall == 1'b0)) begin
			id_pc <= `ZeroWord;
			id_inst <= `ZeroWord; //如果需要暂停，且id段可以接着进行则将本次的指令设为空
		 end else if (if_stall == 1'b0) begin
			id_pc <= if_pc;
			id_inst <= if_inst;
		 end
		end


endmodule
