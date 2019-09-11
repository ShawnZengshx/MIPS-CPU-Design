`timescale 1ns / 1ps

`include "defines.v"
module data_mem(
		input wire clk,
		input wire ce,				//���ݴ洢����ʹ���ź�
		input wire[`RegBus] wdata, //��Ҫд����ź�
		input wire[`DataAddrBus] addr,  //��Ҫ���ʵ�Ŀ���ַ
		input wire we,     //дʹ���ź�
		output reg[`RegBus] rdata   //���ж�ȡ������
    );
		//�����ĸ��ֽ�����
		reg[`RegBus] data_mem[0:`DataMemNum - 1];

		
		//��˴洢
		//д����
		always@(posedge clk) begin
			if(ce == `ChipDisable) begin
			end else if(we == `WriteEnable) begin
				data_mem[addr >> 2] = wdata;
			end
		end

		//������
		always@(*) begin
			if(ce == `ChipDisable) begin
				rdata <= `ZeroWord;
			end else if(we == `WriteDisable) begin
				rdata <= data_mem[addr >> 2];
			end else begin
				rdata <= `ZeroWord;
			end
		end
		

endmodule
