`timescale 1ns / 1ps

`include "defines.v"
module top_cpu(
		input wire clk,
		input wire rst,
		
		input wire[`RegBus] rom_data_inst, //��ָ��Ĵ���ȡ����ָ��
		input wire[`RegBus] rom_data, //�����ݴ洢����ȡ��������
		output wire[`RegBus] rom_addr_out, //�����ָ��Ĵ����ĵ�ַ
		output wire[`RegBus] rom_data_addr_out, //��������ݴ洢���ĵ�ַ
		output wire rom_data_ce_o, //���ݴ洢����ʹ���ź�
		output wire rom_ce_o //ָ��Ĵ���ʹ���ź�
		
    );
	 
		//��֧��ص�һЩ�м����
		wire id_if_branch;    //��ʾid���Ƿ��Ƿ�ָ֧��
		wire[`RegBus] pc_target_address;  //pc��Ŀ���ַ
		wire id_if_branch_o;
		wire ex_if_branch;
		wire next_is_in_delay_slot_o;  //���� ��һ��ָ���Ƿ��ڷ�֧�ӳٲ���
		wire[`RegBus] link_addr_o;  //���淵�صĵ�ַ����Ҫд��Ĵ����ģ�
		wire is_in_delay_slot_o;
		wire ex_is_in_delay_slot_O;  //��ʾex���Ƿ��ڷ�֧�ӳٲ�
		wire ex_link_address_o;  //ex�εõ��ı��淵�صĵ�ַ
		wire is_in_delay_slot_o_ex;  //ex�δ������Ƿ��ڷ�֧�ӳٲ�
		//����if->id�ε�����
		wire[`InstAddrBus] pc; //��Ҫ��ȡ��ָ��ĵ�ַ
		wire[`InstAddrBus] id_pc_inst; //�����id�ε�ָ��ĵ�ַ
		wire[`InstBus] id_inst_i; //id�εõ���ָ��
		
		//����id������Լ�����id->ex�ε���������
		wire[`AluOpBus] id_aluop_o; //id��ȡ�õ�alu������
		wire[`RegBus] id_reg1_o; //id��ȡ�õ�Դ������1
		wire[`RegBus] id_reg2_o; //id��ȡ�õ�Դ������2
		wire id_wreg_en; //id��ȡ�õ��Ƿ���Ҫ�����д�뵽Ŀ�ļĴ���
		wire[`RegAddrBus] id_waddr; //id��ȡ�õĽ����д�뵽Ŀ�ļĴ����ĵ�ַ
		
		//����id/ex������Լ�ex�ε���������
		wire[`AluOpBus] ex_aluop; //ex�β��õ�alu�Ĳ�����
		wire[`RegBus] ex_reg1_i; //ex�β��õ�alu��Դ������1
		wire[`RegBus] ex_reg2_i; //ex�β��õ�alu��Դ������2
		wire ex_wreg_eni; //ex���Ƿ���Ҫ�����д�뵽Ŀ�ļĴ���
		wire[`RegAddrBus] ex_waddri; //ex������д��Ĵ����ĵ�ַ
		
		//����ex�ε�����Լ�ex/mem�ε����������
		wire	ex_wreg_eno; 
		wire[`RegAddrBus] ex_waddro;
		wire[`RegBus] ex_wdata_o;  //ex�����ռ���Ľ��
		
		//����ex/mem�ε�����Լ�mem�ε���������
		wire mem_wreg_eni; //mem�ε��Ƿ���Ҫ������͵�Ŀ�ļĴ���
		wire[`RegAddrBus] mem_waddri; //mem�ν�����͵�Ŀ�ļĴ����ĵ�ַ
		wire[`RegBus] mem_wdata_i; //mem�ε����ս��
		
		//����mem�ε�����Լ�mem/wb�ε���������
		wire mem_wreg_eno;
		wire[`RegAddrBus] mem_waddro;
		wire[`RegBus] mem_wdata_o;
		 
		//����mem/wb������Լ�wb�ε����������
		wire wb_wreg_eni;
		wire[`RegAddrBus] wb_waddri;
		wire[`RegBus] wb_wdata_i;
		
		//��id����regfile����
		wire reg1_read;	//reg�˿�1�Ķ�ʹ��
		wire reg2_read; 	//reg�˿�2�Ķ�ʹ��
		wire[`RegBus] reg1_data; //��reg�˿�1����������
		wire[`RegBus] reg2_data; //��reg�˿�2����������
		wire[`RegAddrBus] reg1_addr; //��ȡreg�˿�1�ĵ�ַ
		wire[`RegAddrBus] reg2_addr; //��ȡreg�˿�2�ĵ�ַ
		
		//��ʾ���ε�stall�Լ�stall������
		wire stall_req_id;
		wire stall_req_ex;
		wire pc_stall;
		wire if_stall;
		wire id_stall;
		wire ex_stall;
		wire mem_stall;
		wire wb_stall;
		
		//����ʵ�ֳ˷�������
		wire ex_hilo_we_o;  //ex��������Ƿ���Ҫд��hilo�Ĵ���
		wire[`RegBus] ex_hi_o;  //ex�������hi��ֵ
		wire[`RegBus] ex_lo_o;  //ex�������lo��ֵ
		wire mem_hilo_we_o;
		wire[`RegBus] mem_hi_o;
		wire[`RegBus] mem_lo_o;
		wire mem_wb_hilo_we_o;
		wire[`RegBus] mem_wb_hi_o;
		wire[`RegBus] mem_wb_lo_o;
		wire wb_hilo_we;
		wire[`RegBus] wb_hi_o;
		wire[`RegBus] wb_lo_o;
		
		//lw��sw���
		wire[`RegBus] inst_o;
		wire[`RegBus] ex_inst_i;
		wire[`AluOpBus] ex_aluop_o;
		wire[`RegBus] mem_addr_i;
		wire[`RegBus] reg2_i;
		wire[`AluOpBus] mem_aluop_o;
		wire[`RegBus] mem_addr_o;
		wire[`RegBus] mem_reg2;
		wire[`RegBus] mem_addro;
		wire  mem_we_o;
		wire[`RegBus] mem_data_o;
		wire  mem_ce_o;
		wire[`RegBus] data_rom_o;
		wire[31:0] signed_mult_op1;
		wire[31:0] signed_mult_op2;
		wire mult_start;
		wire mult_is_done;
		wire[63:0] signed_mult_result;
		//pcʵ����
		pc pc0( .clk(clk), .pc(pc), .rst(rst), .ce(rom_ce_o), .pc_stall(pc_stall),
				  .target_pc(pc_target_address), .if_branch(id_if_branch_o)
				);
		
		assign rom_addr_out = pc; //ָ��Ĵ����������ַ����pc��ֵ
		
		//if/id��ʵ����
		if_id if_id0(
					.clk(clk), .if_pc(pc), .rst(rst),
					.if_stall(if_stall), .id_stall(id_stall),
					.if_inst(rom_data_inst), .id_pc(id_pc_inst),
					.id_inst(id_inst_i)
						);
		
		//����id�ε�ģ�黯
		id id0(
			  .id_pc(id_pc_inst), .id_inst(id_inst_i), .rst(rst),
			  
			  //����regfile������
			  .reg1_data_i(reg1_data), .reg2_data_i(reg2_data),
			  
			  //�͵�regfileģ�����Ϣ
			  .reg1_rden(reg1_read), .reg2_rden(reg2_read),
			  .reg1_addr(reg1_addr), .reg2_addr(reg2_addr),
			  
			  //�͵�id�ε���Ϣ
			  .alu_op(id_aluop_o), .rs_o(id_reg1_o),
			  .rt_o(id_reg2_o), .rd_en(id_wreg_en), .rd_o(id_waddr),
			  
			  //����ex�ε�����
			  .ex_wreg_en(ex_wreg_eno), .ex_wdata_i(ex_wdata_o),
			  .ex_waddr(ex_waddro),
			  
			  //����mem�ε�����
			  .mem_wreg_en(mem_wreg_eno), .mem_wdata_i(mem_wdata_o),
			  .mem_waddr(mem_waddro), 
			  
			  //��stall�������
			  .stall_req_id(stall_req_id),
			  
			  //��֧���
			  .target_pc(pc_target_address),
			  .if_branch(id_if_branch_o), 
			  .is_in_delay_slot_o(is_in_delay_slot_o),
			  .link_addr_o(link_addr_o),
			  .next_is_in_delay_slot(next_is_in_delay_slot_o),
			  .is_in_delay_slot(is_in_delay_slot_o_ex),
			  
			  //lw��sw���
			  .id_inst_out(inst_o),
			  .ex_aluop_i(ex_aluop_o)
				);
				
		//����regfile��ģ��ʵ����
		regfile regfile1(
						.clk(clk), .we(wb_wreg_eni), .waddr(wb_waddri),
						.rst(rst),
						.wdata(wb_wdata_i), .re1(reg1_read), .re2(reg2_read),
						.raddr1(reg1_addr), .raddr2(reg2_addr),
						.rdata1(reg1_data), .rdata2(reg2_data)
							 );
		//����id/exģ���ʵ����
		id_ex id_ex0(
					.clk(clk),
					.rst(rst),
					.id_stall(id_stall), .ex_stall(ex_stall),
					//��id�δ�������Ϣ
					.id_aluop(id_aluop_o), .id_reg1(id_reg1_o), .id_reg2(id_reg2_o),
					.id_wen(id_wreg_en), .id_waddr(id_waddr),
					
					//���͵�ex�ε���Ϣ
					.ex_aluop(ex_aluop), .ex_reg1(ex_reg1_i), .ex_reg2(ex_reg2_i),
					.ex_wen(ex_wreg_eni), .ex_waddr(ex_waddri),
					
					//��֧���
					.id_is_in_delay_slot(is_in_delay_slot_o),
					.id_link_address(link_addro),
					.id_if_branch(id_if_branch_o),
					.next_is_in_delay_slot(next_is_in_delay_slot_o),
					.ex_is_in_delay_slot(ex_is_in_delay_slot_o),
					.ex_link_address(ex_link_address_o),
					.is_in_delay_slot_o(is_in_delay_slot_o_ex),
					.ex_if_branch(ex_if_branch),
					
					//lw��sw���
					.id_inst(inst_o),
					.ex_inst(ex_inst_i)
						);
		//ex�ε�ģ��ʵ����
		ex ex0(
			  .rst(rst),
			  //��id/ex�δ�������Ϣ
			  .id_aluop(ex_aluop), .id_reg1(ex_reg1_i), .id_reg2(ex_reg2_i),
			  .id_wen(ex_wreg_eni), .id_waddr(ex_waddri),
			  
			  //�����ex/memģ�����Ϣ
			  .wd_wen(ex_wreg_eno), .wd_waddr(ex_waddro), .wdata(ex_wdata_o),
			  
			  //��ex�ε�stall�������
			  .stall_req_ex(stall_req_ex),
			  
			  //��֧���
			  .is_in_delay_slot_i(ex_is_in_delay_slot_o),
			  .link_address_i(ex_link_address_o),
			  .ex_if_branch(ex_if_branch),
				
			  //�˷����
			  .hilo_we(ex_hilo_we_o),
			  .hi_o(ex_hi_o),
			  .lo_o(ex_lo_o),
			  //�з��ų˷�
			  .mult_finished(mult_is_done),
			  .mult_start(mult_start),
			  .signed_mult_result(signed_mult_result),
			  .signed_mult_op1(signed_mult_op1),
			  .signed_mult_op2(signed_mult_op2),
			  
			  //lw��sw���
			  .id_inst(ex_inst_i),
			  .aluop_o(ex_aluop_o),
			  .mem_waddr_o(mem_addr_i),
			  .id_reg2_o(reg2_i)
				);
		//ex/memģ��ʵ����
		ex_mem ex_mem0(
						 .clk(clk),
						 .rst(rst),
						 .ex_stall(ex_stall), .mem_stall(mem_stall),
						 //����ex�ε���Ϣ
						 .ex_wen(ex_wreg_eno), .ex_waddr(ex_waddro), .ex_wdata(ex_wdata_o),
						 
						 //�͵�mem�ε���Ϣ
						 .mem_wen(mem_wreg_eni), .mem_waddr(mem_waddri), .mem_wdata(mem_wdata_i),
						 
						 //�˷����
						 .ex_hilo_wen(ex_hilo_we_o), .ex_hi_i(ex_hi_o), .ex_lo_i(ex_lo_o),
						 .mem_hilo_wen(mem_hilo_we_o), .mem_hi(mem_hi_o), .mem_lo(mem_lo_o),

						 //lw��sw���
						 .ex_aluop(ex_aluop_o),
						 .ex_mem_addr(mem_addr_i),
						 .ex_reg2(reg2_i),
						 .mem_aluop(mem_aluop_o),
						 .mem_mem_addr(mem_addr_o),
						 .mem_reg2(mem_reg2)
						  );
		//memģ��ʵ����
		mem mem0(
				  .rst(rst),
				  //����ex/mem����Ϣ
				  .mem_wen(mem_wreg_eni), .mem_waddr(mem_waddri), .mem_data(mem_wdata_i),
				  
				  //�͵�mem/wb�ε���Ϣ
				  .mem_weno(mem_wreg_eno), .mem_waddro(mem_waddro), .mem_datao(mem_wdata_o),
				  
				  //�˷����
				  .mem_hilo_wen(mem_hilo_we_o), .mem_hi_i(mem_hi_o), .mem_lo_i(mem_lo_o),
				  .mem_hilo_wen_o(mem_wb_hilo_we_o), .mem_hi_o(mem_wb_hi_o), .mem_lo_o(mem_wb_lo_o),
				  
				  //lw��sw���
				  .aluop_i(mem_aluop_o),
				  .mem_addr_i(mem_addr_o),
				  .reg2_i(mem_reg2),
				  .mem_data_i(data_rom_o),
				  .mem_addr_o(mem_addro),
				  .mem_we_o(mem_we_o),
				  .mem_data_o(mem_data_o),
				  .mem_ce_o(mem_ce_o)
				  );
		//mem/wbģ��ʵ����
		mem_wb mem_wb0(
					.clk(clk),
					.rst(rst),
					.mem_stall(mem_stall), .wb_stall(wb_stall),
					//����mem�ε���Ϣ
					.mem_wen(mem_wreg_eno), .mem_waddr(mem_waddro), .mem_wdata(mem_wdata_o),
					
					//�����wb�ε���Ϣ
					.wb_wen(wb_wreg_eni), .wb_waddr(wb_waddri), .wb_wdata(wb_wdata_i),
					
					//�˷���صĲ���
					.mem_hilo_wen(mem_wb_hilo_we_o), .mem_hi_i(mem_wb_hi_o), .mem_lo_i(mem_wb_lo_o),
					.wb_hilo_wen(wb_hilo_we_o), .wb_hi_o(wb_hi_o), .wb_lo_o(wb_lo_o)
						  );
		//��stall_controlģ��ʵ����
		stall_control sc(
					.rst(rst),
					.stall_req_id(stall_req_id), .stall_req_ex(stall_req_ex),
					.pc_stall(pc_stall), .if_stall(if_stall),
					.id_stall(id_stall), .ex_stall(ex_stall),
					.mem_stall(mem_stall), .wb_stall(wb_stall)
							 );
		//��hilo�Ĵ���ʵ����
		hi_lo_reg hlr(
					.clk(clk),
					.rst(rst),
					.we(mem_wb_hilo_we_o),
					.hi_data_i(mem_wb_hi_o),
					.lo_data_i(mem_wb_lo_o)
						 );
		data_mem dm(
					.clk(clk),
					.ce(mem_ce_o),
					.wdata(mem_data_o),
					.addr(mem_addro),
					.we(mem_we_o),
					.rdata(data_rom_o)
					  );
		booth_mult bm(
					.clk(clk),
					.rst(rst),
					.mult_op1(signed_mult_op1),
					.mult_op2(signed_mult_op2),
					.start(mult_start),
					.is_done(mult_is_done),
					.result(signed_mult_result)
					  );
		
		
endmodule
