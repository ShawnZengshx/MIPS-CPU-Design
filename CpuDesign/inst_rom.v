`timescale 1ns / 1ps

`include "defines.v"
//指令寄存器
module inst_rom(
		input wire ce, //读使能信号
		input wire[`InstAddrBus] addr, //读取的地址
		output reg[`InstBus] inst //读取的指令
    );
	 
	 reg[`InstBus] inst_mem[0:`InstMemNum-1]; // 定义的寄存器，用于存放指令
	 initial $readmemh("memoryinit", inst_mem); //使用文件存放指令
	 always@(*)begin
	  if(ce == `ChipDisable) begin
		inst <= `ZeroWord;
	  end else begin 
		inst <= inst_mem[addr[`InstMemNumLog2 + 1:2]]; //读取时需要将地址除以4，即右移2位
	  end
	 end

endmodule
