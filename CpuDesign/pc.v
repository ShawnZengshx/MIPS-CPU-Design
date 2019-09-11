`timescale 1ns / 1ps

`include "defines.v"
module pc(
		input wire clk,
		input wire rst,
		input wire pc_stall, //�����źű�ʾpc�׶��Ƿ���Ҫ��ͣ
		input wire if_branch, //�ж��Ƿ��Ƿ�ָ֧��Ľ����pc��Ҫ�����޸ģ�1��ʾ��Ҫ�����޸�
		input wire[`RegBus] target_pc, //��ʾ���ʵ�ֵ��Ƿ�֧Ԥ��ָ��򽫷�ֵ��Ŀ���ַ����pc
		
		output reg[`InstAddrBus] pc,
      output reg ce		//Ƭѡ�ź�
		
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
		pc <= 32'h00000000;	//ָ��Ĵ�������ʱ��pc��ֵΪ0
	 end else if(pc_stall == 1'b0) begin //���û��stall
		if(if_branch == 1'b1) begin       //����Ƿ�ָ֧��򽫵�ַ�޸�Ϊ��֧Ŀ��ĵ�ַ
			pc <= target_pc;
		end else begin
			pc <= pc + 4'h4;		//ָ��Ĵ���ʹ�ܵ�ʱ��pc��ֵÿ����+4
		end
	 end
	end
		

endmodule
