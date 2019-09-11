`timescale 1ns / 1ps

`include "defines.v"
module stall_control(
		input wire rst,
		input wire stall_req_id,   //����id�ε�stall����
		input wire stall_req_ex,	//����ex�ε�stall����
		
		output reg pc_stall, //��ʾ�Ƿ���ͣpc�׶� Ϊ1��ʾ��Ҫ��ͣ����ͬ
		output reg if_stall, //��ʾ�Ƿ���ͣif�׶�
		output reg id_stall, //��ʾ�Ƿ���ͣid�׶�
		output reg ex_stall, //��ʾ�Ƿ���ͣex�׶�
		output reg mem_stall, //��ʾ�Ƿ���ͣmem�׶�
		output reg wb_stall //��ʾ�Ƿ���ͣwb�׶�
		
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
