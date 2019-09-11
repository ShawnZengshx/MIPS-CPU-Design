`timescale 1ns / 1ps

`include "defines.v"
module stall_control(
		input wire rst,
		input wire stall_req_id,   //来自id段的stall请求
		input wire stall_req_ex,	//来自ex段的stall请求
		
		output reg pc_stall, //表示是否暂停pc阶段 为1表示需要暂停，下同
		output reg if_stall, //表示是否暂停if阶段
		output reg id_stall, //表示是否暂停id阶段
		output reg ex_stall, //表示是否暂停ex阶段
		output reg mem_stall, //表示是否暂停mem阶段
		output reg wb_stall //表示是否暂停wb阶段
		
    );

	always@(*)begin
		if(rst == `RstEnable) begin
			pc_stall <= 1'b0;
			if_stall <= 1'b0;
			id_stall <= 1'b0;
			ex_stall <= 1'b0;
			mem_stall <= 1'b0;
			wb_stall <= 1'b0;
		end else if(stall_req_id == 1'b1) begin
			pc_stall <= 1'b1;
			if_stall <= 1'b1;
			id_stall <= 1'b1;
			ex_stall <= 1'b0;
			mem_stall <= 1'b0;
			wb_stall <= 1'b0;
		end else if(stall_req_ex == 1'b1) begin
			pc_stall <= 1'b1;
			if_stall <= 1'b1;
			id_stall <= 1'b1;
			ex_stall <= 1'b1;
			mem_stall <= 1'b0;
			wb_stall <= 1'b0;
		end else begin
			pc_stall <= 1'b0;
			if_stall <= 1'b0;
			id_stall <= 1'b0;
			ex_stall <= 1'b0;
			mem_stall <= 1'b0;
			wb_stall <= 1'b0;
		end
	end

endmodule
