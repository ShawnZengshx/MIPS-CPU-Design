`timescale 1ns / 1ps

`include "defines.v"
//ָ��Ĵ���
module inst_rom(
		input wire ce, //��ʹ���ź�
		input wire[`InstAddrBus] addr, //��ȡ�ĵ�ַ
		output reg[`InstBus] inst //��ȡ��ָ��
    );
	 
	 reg[`InstBus] inst_mem[0:`InstMemNum-1]; // ����ļĴ��������ڴ��ָ��
	 initial $readmemh("memoryinit", inst_mem); //ʹ���ļ����ָ��
	 always@(*)begin
	  if(ce == `ChipDisable) begin
		inst <= `ZeroWord;
	  end else begin 
		inst <= inst_mem[addr[`InstMemNumLog2 + 1:2]]; //��ȡʱ��Ҫ����ַ����4��������2λ
	  end
	 end

endmodule
