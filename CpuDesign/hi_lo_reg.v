`timescale 1ns / 1ps

// ���ڳ˷��������ļĴ���
`include "defines.v"
module hi_lo_reg(
		input wire clk,
		input wire rst,
		
		input wire we, //дʹ�ܶ�
		input wire[`RegBus] hi_data_i, //Ҫд��hi�Ĵ�����ֵ
		input wire[`RegBus] lo_data_i, //Ҫд��lo�Ĵ�����ֵ
		
		output reg[`RegBus] hi_data_o, //hi�Ĵ����Ķ�ȡ��ֵ
		output reg[`RegBus] lo_data_o  //lo�Ĵ����Ķ�ȡ��ֵ
    );
		
		// reg[`RegBus] hidatamem[0:1];
		// reg[`RegBus] lodatamem[0:1];
		always@(posedge clk) begin
			if(rst == `RstEnable) begin
				hi_data_o <= `ZeroWord;
				lo_data_o <= `ZeroWord;
				// hidatamem[0] <= `ZeroWord;
				// lodatamem[0] <= `ZeroWord;
			end else if(we == `WriteEnable) begin
				hi_data_o <= hi_data_i;
				lo_data_o <= lo_data_i;
				// hidatamem[1] <= hi_data_i;
				// lodatamem[1] <= lo_data_i;
			end
		end

endmodule
