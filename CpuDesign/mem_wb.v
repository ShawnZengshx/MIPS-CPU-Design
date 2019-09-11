`timescale 1ns / 1ps

`include "defines.v"
module mem_wb(
		input wire clk,
		input wire rst,
		input wire mem_stall, //��ʾmem���Ƿ���Ҫstall
		input wire wb_stall,  //��ʾwb���Ƿ���Ҫstall
		
		input wire[`RegAddrBus] mem_waddr, //����mem�ε�д��Ŀ�ļĴ����ĵ�ַ
		input wire mem_wen, //����mem�ε��Ƿ���Ҫд��Ŀ�ļĴ���
		input wire[`RegBus] mem_wdata, //����mem�ε����յĽ��
		
		input wire mem_hilo_wen,
		input wire[`RegBus] mem_hi_i,
		input wire[`RegBus] mem_lo_i,
		
		output reg[`RegAddrBus] wb_waddr, //����д�ص�Ŀ�ļĴ����ĵ�ַ
		output reg wb_wen, //�Ƿ���Ҫ�����д�ص�Ŀ�ļĴ���
		output reg[`RegBus] wb_wdata, //����д�صĽ��
		
		output reg wb_hilo_wen,
		output reg[`RegBus] wb_hi_o,
		output reg[`RegBus] wb_lo_o

    );
		
		always@(posedge clk) begin
		 if(rst == `RstEnable) begin
			wb_waddr <= `NOPRegAddr;
			wb_wen <= `WriteDisable;
			wb_wdata <= `ZeroWord;
		 end else if((mem_stall == 1'b1) && (wb_stall == 1'b0)) begin
			wb_waddr <= `NOPRegAddr;
			wb_wen <= `WriteDisable;
			wb_wdata <= `ZeroWord;    //���mem����Ҫ��ͣ��wb�β���Ҫ�򽫿�ֵд��wb
		 end else begin
			wb_waddr <= mem_waddr;
			wb_wen <= mem_wen;
			wb_wdata <= mem_wdata;
		 end
		end

endmodule
