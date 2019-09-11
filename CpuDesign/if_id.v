`timescale 1ns / 1ps

`include "defines.v"
module if_id(
		input wire clk,
		input wire rst,
		input wire if_stall, //��ʾif���Ƿ���Ҫ��ͣ
		input wire id_stall, //�ж�id���Ƿ���Ҫ��ͣ������ȷif�ε�ָ���������
		//ָ����Ϊ32
		input wire[`InstAddrBus] if_pc, //ȡָ�׶���ȡ�õ�ָ��ĵ�ַ
		input wire[`InstBus] if_inst, //ȡָ�׶���ȡ�õ�ָ��
		
		output reg[`InstAddrBus] id_pc, //����׶�ָ���Ӧ�ĵ�ַ
		output reg[`InstBus] id_inst //����׶�����Ӧ��ָ��
		
    );
		always@(posedge clk)begin
		 if(rst == `RstEnable) begin
			id_pc <= `ZeroWord;
			id_inst <= `ZeroWord;
		 end else if((if_stall == 1'b1) && (id_stall == 1'b0)) begin
			id_pc <= `ZeroWord;
			id_inst <= `ZeroWord; //�����Ҫ��ͣ����id�ο��Խ��Ž����򽫱��ε�ָ����Ϊ��
		 end else if (if_stall == 1'b0) begin
			id_pc <= if_pc;
			id_inst <= if_inst;
		 end
		end


endmodule
