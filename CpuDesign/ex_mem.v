`timescale 1ns / 1ps

`include "defines.v"
module ex_mem(
		input wire clk,
		input wire rst,
		input wire mem_stall, //��ʾmem�Ƿ���Ҫstall
		input wire ex_stall, //��ʾex�Ƿ���Ҫstall�Ա���ex�ε����
		
		input wire[`RegAddrBus] ex_waddr, //����ex�ε�д��Ŀ�ļĴ����ĵ�ַ
		input wire ex_wen, //����ex�ε��Ƿ���Ҫд��Ŀ�ļĴ���
		input wire[`RegBus] ex_wdata, //����ex�ε�������
		
		input wire ex_hilo_wen,  //��ʾ�Ƿ���Ҫд�뵽Hilo�Ĵ���
		input wire[`RegBus] ex_hi_i, //�����ex�ε�hi��ֵ
		input wire[`RegBus] ex_lo_i, //�����ex�ε�lo��ֵ
		
		output reg[`RegAddrBus] mem_waddr, //���뵽mem�ε�д��Ŀ�ļĴ����ĵ�ַ
		output reg mem_wen, //���뵽mem�ε��Ƿ���Ҫд�뵽Ŀ�ļĴ���
		output reg[`RegBus] mem_wdata, //���뵽mem�ε����յ�����Ľ��
		
		output reg mem_hilo_wen,     //��ʾmem�Ƿ���Ҫд�뵽hilo�Ĵ���
		output reg[`RegBus] mem_hi,  //��ʾmemд�뵽hi�Ĵ�����ֵ
		output reg[`RegBus] mem_lo,   //��ʾmemд�뵽lo�Ĵ�����ֵ
		
		//lw��sw����������
		input wire[`AluOpBus] ex_aluop,    //�����ex�Ĳ�����
		input wire[`RegBus] ex_mem_addr,   //ex���صļĴ����ĵ�ַ
		input wire[`RegBus] ex_reg2,       //exҪ�洢����
		
		//lw��sw�����ص����
		output reg[`AluOpBus] mem_aluop,
		output reg[`RegBus] mem_mem_addr,
		output reg[`RegBus] mem_reg2
		
    );
	   always@(posedge clk)begin
		 if(rst == `RstEnable) begin
		   mem_waddr <= `NOPRegAddr;
			mem_wen <= `WriteDisable;
			mem_wdata <= `ZeroWord;
			mem_hilo_wen <= `WriteDisable;
			mem_hi <= `ZeroWord;
			mem_lo <= `ZeroWord;
		 end else if((ex_stall == 1'b1) && (mem_stall == 1'b0)) begin
			mem_waddr <= `NOPRegAddr;
			mem_wen <= `WriteDisable;
			mem_wdata <= `ZeroWord;        //���ex����Ҫ��ͣ��mem�β���Ҫ���򽫿�ֵ�������һ��mem��
		 end else if(ex_hilo_wen == 1'b1) begin
			mem_waddr <= `NOPRegAddr;
			mem_wen <= `WriteDisable;
			mem_wdata <= `ZeroWord;
			mem_hilo_wen <= `WriteEnable;
			mem_hi <= ex_hi_i;
			mem_lo <= ex_lo_i;
		 end else if(ex_stall == 1'b0) begin
			mem_waddr <= ex_waddr;
			mem_wen <= ex_wen;
			mem_wdata <= ex_wdata;
			mem_hilo_wen <= `WriteDisable;
			mem_hi <= `ZeroWord;
			mem_lo <= `ZeroWord;
			mem_aluop <= ex_aluop;
			mem_mem_addr <= ex_mem_addr;
			mem_reg2 <= ex_reg2;
		 end else begin
			mem_waddr <= ex_waddr;
			mem_wen <= ex_wen;
			mem_wdata <= ex_wdata;
			mem_hilo_wen <= `WriteDisable;
			mem_hi <= `ZeroWord;
			mem_lo <= `ZeroWord;
		 end
      end	
endmodule
