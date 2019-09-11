`timescale 1ns / 1ps

`include "defines.v"
module my_mips_cpu(
		input wire clk,
		input wire rst
    );
		wire[`InstAddrBus] inst_addr; //用于连接指令寄存器的地址
		wire[`InstBus] inst; //从指令寄存器取出的指令
		wire rom_ce; //读使能端

		//例化处理器top_cpu
		top_cpu top_cpu0(
						.clk(clk), .rom_data_inst(inst), .rst(rst),
						.rom_addr_out(inst_addr), .rom_ce_o(rom_ce)
		                 );
		
		//例化指令寄存器inst_rom
		inst_rom inst_rom0(
						.ce(rom_ce),
						.addr(inst_addr), .inst(inst)
								);
endmodule
