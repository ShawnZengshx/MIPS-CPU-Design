`timescale 1ns / 1ps

`include "defines.v"
module id_ex(
		input wire clk,
		input wire rst,
		input wire id_stall,	//�ж�id���Ƿ���Ҫ������ͣ
		input wire ex_stall, //�ж�ex���Ƿ���Ҫ������ͣ�Ա������
		
		input wire [`AluOpBus] id_aluop, //��id�εõ���alu�Ĳ�����
		input wire [`RegBus]	id_reg1, //��id�εõ���Դ������1
		input wire [`RegBus] id_reg2, //��id�εõ���Դ������2
		input wire [`RegAddrBus] id_waddr, //�жϴ�id���Ĳ����Ľ��д��Ŀ�ļĴ����ĵ�ַ
		input wire id_wen, //�ж��Ƿ�Ҫд��Ŀ�ļĴ���
		
		//��֧���Ƶ�����
		input wire id_is_in_delay_slot, //id�δ�����ź��ж�id���Ƿ��ڷ�֧�ӳٲ�
		input wire [`RegBus] id_link_address, //������id�η�֧ǰ���ص�ַ
		input wire next_is_in_delay_slot, //�ж���һ��ָ���Ƿ����ӳٲ�
		input wire id_if_branch, //��ʾidĿǰָ���Ƿ��Ƿ�ָ֧��
		
		//lw��sw���ָ��Ŀ���
		input wire[`RegBus] id_inst,  //����id�ε�ָ��
		output reg[`RegBus] ex_inst,  //�����ex�ε�ָ��
		//��֧���Ƶ����
		output reg ex_is_in_delay_slot,  //��ʾex���Ƿ�λ�ڷ�֧�ӳٲ�
		output reg [`RegBus] ex_link_address, //�����ŷ��ص�ַ
		output reg is_in_delay_slot_o,  //���������ǰ����ָ���Ƿ��ڷ�֧�ӳٲ�
		output reg ex_if_branch,  //��ʾex��ָ���Ƿ��Ƿ�ָ֧��

		output reg[`AluOpBus] ex_aluop, //д�뵽ex�ε�alu�Ĳ�����
		output reg[`RegBus] ex_reg1, //д�뵽ex�ε�alu��Դ������1
		output reg[`RegBus] ex_reg2, //д�뵽ex�ε�alu��Դ������2
		output reg[`RegAddrBus] ex_waddr, //alu������д�뵽��Ŀ�ļĴ����ĵ�ַ
		output reg ex_wen //�ж��Ƿ���Ҫд�뵽Ŀ�ļĴ���
		
    );
	 
	 //��������Ҫ���ľ��ǰ�id�εĸ��������������������ַд�뵽ex��
		always@(posedge clk)begin
		 if(rst == `RstEnable) begin
			ex_aluop <= `EXE_NOP_OP;
			ex_reg1 <= `ZeroWord;
			ex_reg2 <= `ZeroWord;
			ex_waddr <= `NOPRegAddr;
			ex_wen <= `WriteDisable;
			ex_link_address <= `ZeroWord;
			ex_is_in_delay_slot <= 1'b0;
			is_in_delay_slot_o <= 1'b0;
			ex_if_branch <= 1'b0;
		 end else if((id_stall == 1'b1) && (ex_stall == 1'b0)) begin
			ex_aluop <= `EXE_NOP_OP;
			ex_reg1 <= `ZeroWord;
			ex_reg2 <= `ZeroWord;
			ex_waddr <= `NOPRegAddr;
			ex_wen <= `WriteDisable;		//��id����Ҫ��ͣ��ex�β���Ҫʱ���򽫿�ָ�������ex��
			ex_link_address <= `ZeroWord;
			ex_is_in_delay_slot <= 1'b0;
			ex_if_branch <= 1'b0;
		 end else if(id_stall == 1'b0) begin    //��������û�б���ͣ
			ex_aluop <= id_aluop;
			ex_reg1 <= id_reg1;
			ex_reg2 <= id_reg2;
			ex_waddr <= id_waddr;
			ex_wen <= id_wen;
			ex_link_address <= id_link_address;
			ex_is_in_delay_slot <= id_is_in_delay_slot;
			is_in_delay_slot_o <= next_is_in_delay_slot;
			ex_if_branch <= id_if_branch;
			ex_inst <= id_inst;
		 end
		end


endmodule
