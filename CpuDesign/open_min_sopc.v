`timescale 1ns / 1ps

`include "defines.v"
module my_mips_cpu(
		input wire clk,
		input wire rst
    );
		wire[`InstAddrBus] inst_addr; //��������ָ��Ĵ����ĵ�ַ
		wire[`InstBus] inst; //��ָ��Ĵ���ȡ����ָ��
		wire rom_ce; //��ʹ�ܶ�

		//����������top_cpu
		top_cpu top_cpu0(
						.clk(clk), .rom_data_inst(inst), .rst(rst),
						.rom_addr_out(inst_addr), .rom_ce_o(rom_ce)
		                 );
		
		//����ָ��Ĵ���inst_rom
		inst_rom inst_rom0(
						.ce(rom_ce),
						.addr(inst_addr), .inst(inst)
								);
endmodule
