`timescale 1ns / 1ps

`include "defines.v"
module ex(
		input wire rst,
		
		input wire[`AluOpBus] id_aluop, //id�δ����alu�Ĳ�����
		input wire[`RegBus] id_reg1, //��id�δ����Դ������1
		input wire[`RegBus] id_reg2, //��id�δ����Դ������2
		input wire[`RegAddrBus] id_waddr, //id�δ���Ľ����д�뵽Ŀ�ļĴ����ĵ�ַ
		input wire id_wen, //id�δ�����Ƿ�Ҫ�����д�뵽Ŀ�ļĴ�����
		
		//lw��sw���ָ��Ŀ���
		input wire [`RegBus] id_inst,    //ex�δ�id�εõ���ָ����ڻ�ȡoffset
		output wire [`RegBus] mem_waddr_o, //Ҫд��洢���ĵ�ַ
		output wire [`RegBus] id_reg2_o,   //����Ӵ洢����ȡ������
		output wire [`AluOpBus] aluop_o,   //����Ĳ�����
		//���ڳ˳����ļĴ������
		output reg[`RegBus] hi_o,   //�����hi�Ĵ�����ֵ
		output reg[`RegBus] lo_o,   //�����lo�Ĵ�����ֵ
		output reg   hilo_we,       //�Ƿ���Ҫд�뵽hi_lo�Ĵ���
		
		//��֧����ָ������
		input wire [`RegBus] link_address_i,  //ex�α���ķ�֧��ַ��Ҫ���صĵ�ַ
		input wire is_in_delay_slot_i, //��ʾ�Ƿ�λ�ڷ�֧�ӳٲ�
		input wire ex_if_branch,   //��ʾ��ǰָ���Ƿ��Ƿ�ָ֧��
		
		//�з��ų˷��ı�־״̬
		input wire mult_finished,    //��ʾ�˷��Ƿ����
		output reg mult_start,     //��ʾ��ʼ�з��ų˷�
		//�з��ų˷����������
		input wire[63:0] signed_mult_result,    //��ʾ�з��ų˷��Ľ��������
		output reg[31:0] signed_mult_op1,    //�з��ų˷��Ĳ�����1
		output reg[31:0] signed_mult_op2,    //�з��ų˷��Ĳ�����2
		
		output reg[`RegAddrBus] wd_waddr, //�ж����ս����д�뵽Ŀ�ļĴ����ĵ�ַ
		output reg wd_wen, //�ж������Ƿ���Ҫ�����д�뵽Ŀ�ļĴ���
		output reg[`RegBus] wdata,  //���յõ��Ľ��
		output reg stall_req_ex  //ex���Ƿ�����stall
    );
	 
		reg[`RegBus] logicout; //���ڱ���alu����Ľ��
		
		//���г˷�����ʱ�����
		reg[63:0] mult_result; //����32λ�˷��Ľ��
		wire[`RegBus] mult_op1; //����˷�������1
		wire[`RegBus] mult_op2; //����˷�������2
		 
		wire overflow; //��ʾ����Ƿ����
		wire reg1_eq_reg2; //��ʾ����Դ�������Ƿ���ͬ
		wire reg1_ls_reg2; //��ʾ��һ��������С�ڵڶ���������
		wire [`RegBus] id_reg2_comp; //�ڶ����������Ĳ���
		wire [`RegBus] id_reg1_comp; //��һ���������Ĳ���
		wire [`RegBus] id_reg1_not;  //��һ��������ȡ�������
		wire [`RegBus] id_reg2_not;  //�ڶ����������ķ���
		wire [`RegBus] id_reg2_not_comp; //�ڶ����������ķ���Ĳ���
		wire [`RegBus] temp; //�����ӷ��Ľ��
		wire [`RegBus] stemp; //���������Ľ��
		wire [`RegBus] signed_sum_result; //�з������Ľ��
		wire [`RegBus] signed_sub_result; //�з������Ľ��
		wire [`RegBus] unsigned_sum_result; //�޷������Ľ��
		wire [`RegBus] unsigned_sub_result; //�޷������ļ���
		wire [63:0] mul_temp;
		reg stall_for_mult;		//�Ƿ����ڳ˷�������ˮ����ͣ
		//assign stall_req_ex = 1'b0; //Ĭ��ex�β�����stall
		
		//lw��sw�����
		assign aluop_o = id_aluop;
		assign mem_waddr_o = id_reg1 + {{16{id_inst[15]}}, id_inst[15:0]};
		assign id_reg2_o = id_reg2; //�������ͳ�
		
		/*assign id_reg2_comp = ((id_aluop == `EXE_SUB_OP)||
									  (id_aluop == `EXE_SUBU_OP) ||
									  (id_aluop == `EXE_SLT_OP)
									 )? (~id_reg2) + 1 : id_reg2;  //����Ǽ������������ǱȽϲ�����
																			 //������ڶ���������ȡ�䲹��*/
		//�Ӽ�������
		assign id_reg1_comp = (id_reg1[31] == 1'b1) ?
									 {id_reg1[31], ~id_reg1[30:0]} + 1 : id_reg1;   //������1�Ĳ���
		assign id_reg2_comp = (id_reg2[31] == 1'b1) ?
									 {id_reg2[31], ~id_reg2[30:0]} + 1 : id_reg2;   //������2�Ĳ���
		assign id_reg2_not = {~id_reg2[31], id_reg2[30:0]}; //������2���෴��
		assign id_reg2_not_comp = (id_reg2_not[31] == 1'b1) ?
										  {id_reg2_not[31], ~id_reg2_not[30:0]} + 1 : id_reg2_not;  //������2���෴���Ĳ���
		assign stemp = id_reg1_comp + id_reg2_not_comp;   
		assign signed_sub_result = (stemp[31] == 1'b1) ?
										  {stemp[31], ~stemp[30:0]} + 1 : stemp;
		assign unsigned_sub_result = id_reg1 - id_reg2;								  
		assign temp = id_reg1_comp + id_reg2_comp;		//������ʱ�Ĵ�ӷ������Ľ���������ж��Ƿ����
		assign signed_sum_result = (temp[31] == 1'b1) ?
								  {temp[31], ~temp[30:0]} + 1 : temp;
		assign unsigned_sum_result = id_reg1 +id_reg2; //�޷�����ֱ�����
		
		//�ж��Ƿ���������������������Ϊ�������Ϊ������������������Ϊ�������Ϊ����Ϊ���
		assign overflow = ((!id_reg1[31] && !id_reg2[31]) && signed_sum_result[31]) ||
								((id_reg1[31] && id_reg2[31]) && !signed_sum_result[31]) || 
								((id_reg1[31] && !id_reg2[31]) && !signed_sub_result[31]) ||
								((!id_reg1[31] && id_reg2[31]) && signed_sub_result[31]);
								
		/*assign reg1_ls_reg2 = ((id_aluop == `EXE_SLT_OP))?   //������з������ıȽ�
									 ((id_reg1[31] && !id_reg2[31]) ||
									  (!id_reg1[31] && !id_reg2[31] && sum_result[31])||
									  (id_reg1[31] && id_reg2[31] && sum_result[31])) :
									  (id_reg1 < id_reg2);*/
		
		//�˳���
		assign id_reg1_not = ~id_reg1;
		
		/*assign mult_op1 = ((id_aluop == `EXE_MULT_OP) && id_reg1[31] == 1) ?
								(~id_reg1) + 1 : id_reg1;    //������з������˷���ȡ��Ϊ����ȡ����
		assign mult_op2 = ((id_aluop == `EXE_MULT_OP) && id_reg2[31] == 1) ? 
								(~id_reg2) + 1 : id_reg2;    //ͬ������1*/
		
		assign mult_op1 = {0, id_reg1[30:0]};
		assign mult_op2 = {0, id_reg2[30:0]};
		assign mul_temp = mult_op1 * mult_op2;
		
		
		
		always@(*) begin
		 if(rst == `RstEnable) begin
			mult_result <= 64'b0;
			stall_for_mult <= 1'b0;
			mult_start <= 1'b0;
		 end else if(id_aluop == `EXE_MULT_OP) begin		//������з��ų˷�
			if(mult_finished == 1'b0)begin		//����˷�δ���
				stall_for_mult <= 1'b1;
				mult_start <= 1'b1;
				signed_mult_op1 <= id_reg1;
				signed_mult_op2 <= id_reg2;
			end else begin
				stall_for_mult <= 1'b0;
				mult_start <= 1'b0;
				mult_result <= signed_mult_result;
			end
		 end else begin
			mult_result <= id_reg1 * id_reg2;    //����޷��ų˷��Ľ��
		 end
		end

		always@(*)begin
			stall_req_ex <= stall_for_mult;
		end
		
		always@(*)begin
		 if(rst == `RstEnable)begin
			logicout <= `ZeroWord;
		 end else begin
			case(id_aluop)
				`EXE_OR_OP:begin
					logicout <= id_reg1 | id_reg2; //���а�λ������
				end
				`EXE_AND_OP: begin
					logicout <= id_reg1 & id_reg2; //���а�λ�����
				end
				`EXE_XOR_OP: begin
					logicout <= id_reg1 ^ id_reg2; //����������
				end
				`EXE_NOR_OP: begin
					logicout <= ~(id_reg1 | id_reg2); //���л�Ǽ���
				end
				`EXE_SRL_OP: begin
					logicout <= id_reg2 >> id_reg1[4:0]; //�����߼�����
				end
				`EXE_SLL_OP: begin
					logicout <= id_reg2 << id_reg1[4:0]; //�����߼�����
				end
				`EXE_SRA_OP: begin //������������
				end
				`EXE_SLT_OP, `EXE_SLTU_OP: begin			//���бȽ�
					logicout <= reg1_ls_reg2;
				end
				`EXE_ADD_OP, `EXE_ADDI_OP: begin //���мӷ�
					logicout <= signed_sum_result;
				end
				`EXE_ADDU_OP, `EXE_ADDIU_OP: begin
					logicout <= unsigned_sum_result;
				end
				`EXE_SUB_OP: begin			//���м�������
					logicout <= signed_sub_result;
				end
				`EXE_SUBU_OP: begin
					logicout <= unsigned_sub_result;
				end
			default: begin
				logicout <= `ZeroWord;
			end
			endcase
		end
		end
		
		always@(*)begin
			if(((id_aluop == `EXE_ADD_OP) || (id_aluop == `EXE_ADDI_OP) ||
				(id_aluop == `EXE_SUB_OP)) && (overflow == 1'b1)) begin
					wd_wen <= `WriteDisable; //�����������д��Ĵ���
			end else begin
					wd_wen <= id_wen;
			end
			wd_waddr <= id_waddr;
			if(ex_if_branch == 1'b1) begin
				wdata <= link_address_i;				//����Ƿ�ָ֧������ת�ĵ�ַ��Ϊ������
			end else begin
				wdata <= logicout;
			end
		end
		
		always@(*) begin //���ڳ˳��������
		 if(rst == `RstEnable) begin
			hilo_we = `WriteDisable;
			hi_o <= `ZeroWord;
			lo_o <= `ZeroWord;
		 end else if((id_aluop == `EXE_MULT_OP) ||(id_aluop == `EXE_MULTU_OP)) begin
			hilo_we = `WriteEnable;
			hi_o <= mult_result[63:32];
			lo_o <= mult_result[31:0];
		 end else begin
			hilo_we = `WriteDisable;
			hi_o <= `ZeroWord;
			lo_o <= `ZeroWord;
		 end
		end
endmodule
