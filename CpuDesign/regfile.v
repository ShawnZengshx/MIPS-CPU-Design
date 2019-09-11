`timescale 1ns / 1ps

`include "defines.v"
module regfile(
		input wire clk,		// regfile��ʵ����wb��
		input wire rst,
		
		//д�˿�
		input wire we, //дʹ���ź�
		input wire [`RegAddrBus] waddr, //Ҫд��ļĴ����ĵ�ַ
		input wire [`RegBus] wdata, //Ҫд��ͼĴ���������
		
		//���˿�1
		input wire re1, //��ʹ�ܶ�
		input wire[`RegAddrBus] raddr1, //��һ���Ĵ�����ȡ���ݵĵ�ַ
		output reg[`RegBus] rdata1,// ��һ���˿ڶ���������
		
		//���˿�2
		input wire re2, 
		input wire[`RegAddrBus] raddr2,
		output reg[`RegBus] rdata2
		
    );
		reg[`RegBus] regs[0: `RegNum-1]; // ����32��32λ�ļĴ���
		initial $readmemh("regsinit", regs);
		
		//д����
		always@(posedge clk)begin
		 if(rst == `RstDisable) begin
			if((we == `WriteEnable)&& (waddr != 5'b0)) begin
				regs[waddr] <= wdata;
			end else if((we == `WriteEnable) && (waddr == 5'b0)) begin
				regs[waddr] <= `ZeroWord;
			end
		 end
		end
		//���˿�1�Ĳ���
		always@(*)begin
		 if (rst == `RstEnable) begin
			rdata1 <= `ZeroWord;
		 end else if (raddr1 == 5'b0) begin
			rdata1 <= `ZeroWord;
		end else if((raddr1 == waddr) && (we == `WriteEnable)
						&& (re1 == `ReadEnable))begin  //���������������ָ����������
			rdata1 <= wdata;
		end else if(re1 == `ReadEnable)begin
			rdata1 <= regs[raddr1];
		end else begin
			rdata1 <= `ZeroWord;
			end
		end
		
		//���˿�2�Ĳ���
		
		always@(*)begin
		 if(rst == `RstEnable) begin
			rdata2 <= `ZeroWord;
		 end else if (raddr2 == 5'b0) begin
			rdata2 <= `ZeroWord;
		end else if((raddr2 == waddr) && (we == `WriteEnable)
						&& (re2 == `ReadEnable))begin
			rdata2 <= wdata;
		end else if(re2 == `ReadEnable)begin
			rdata2 <= regs[raddr2];
		end else begin
			rdata2 <= `ZeroWord;
			end
		end
		
			
endmodule
