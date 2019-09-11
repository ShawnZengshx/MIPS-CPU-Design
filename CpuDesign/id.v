`timescale 1ns / 1ps

`include "defines.v"
module id(
		input wire rst,
		
		input wire[`InstAddrBus] id_pc, //id�׶ε�ָ��ĵ�ַ
		input wire[`InstBus] id_inst, //id�׶ε�ָ��
		
		input wire is_in_delay_slot, //�жϵ�ǰָ���Ƿ���λ���ӳٲ���
		output reg if_branch, //�жϵ�ǰָ���Ƿ�����תָ��
		
		output reg next_is_in_delay_slot, //��ʾ��һ���Ƿ�λ���ӳٲ���
		output reg[`RegBus] target_pc, //��ʾ��ָ֧��Ŀ���pc��ַ
		output reg[`RegBus] link_addr_o, //ת�Ƶ�ַҪ����ķ��ص�ַ
		output reg is_in_delay_slot_o, //����ǰָ���Ƿ�λ���ӳٲ۵��ź��ͳ�
		
		//��ȡRegfile��ֵ
		input wire[`RegBus] reg1_data_i, //��regs�ĵ�һ������˿���������
		input wire[`RegBus] reg2_data_i, //�ڶ����˿�����
		
		output reg reg1_rden, //reg��һ���˿ڵĶ�ʹ���ź�
		output reg reg2_rden, //reg�ڶ����˿ڵĶ�ʹ���ź�
		output reg[`RegAddrBus] reg1_addr, //��һ���˿ڵĶ���ַ
		output reg[`RegAddrBus] reg2_addr, //�ڶ����˿ڵĶ���ַ
		
		output reg[`AluOpBus] alu_op, //alu������
		output reg[`RegBus] rs_o, //����׶�alu���е�Դ������1������ex�ε�����
		output reg[`RegBus] rt_o, //����׶�alu���е�Դ������2
		output reg[`RegAddrBus] rd_o, //����׶ε�ָ��д��ļĴ�����ַ
		output reg rd_en, //����׶�ָ���Ƿ�Ҫд��Ŀ�ļĴ���	
		output wire stall_req_id, //��ʾid���Ƿ�����stall
		
		output wire[`RegBus] id_inst_out, //��id�׶ε�ָ��������������ex�ν���
		
		
		//����ʵ��dataforwarding�����������
		//����ex�ε�ָ���������
		input wire ex_wreg_en, //�ж��Ƿ���Ҫд�뵽Ŀ�ļĴ���
		input wire[`RegBus] ex_wdata_i, //��Ҫд�������
		input wire[`RegAddrBus] ex_waddr, //��Ҫд���Ŀ��Ĵ����ĵ�ַ
		
		//����mem�ε�������
		input wire mem_wreg_en, //�ж��Ƿ���Ҫд�뵽Ŀ�ļĴ���
		input wire[`RegBus] mem_wdata_i, //��Ҫд�������
		input wire[`RegAddrBus] mem_waddr, //��Ҫд���Ŀ��Ĵ����ĵ�ַ
		
		//����load���������
		input wire[`AluOpBus] ex_aluop_i   //��ex�λ�ȡ�Ĳ�����
    );
		wire[5:0] op = id_inst[31:26];   //ָ���������ж�r��i��j������
		wire[4:0] op2 = id_inst[10:6];	
		wire[5:0] op3 = id_inst[5:0];		//�����������жϾ�������һ������
		wire[4:0] op4 = id_inst[20:16];
		
		reg[`RegBus] imm; //ָ����Ҫ��������
		reg instvalid; //�ж�ָ���Ƿ���Ч
		
		wire[`RegBus] pc_8;		//��������ڶ���ָ��ĵ�ַ
		wire[`RegBus] pc_4;		//������һ��ָ��ĵ�ַ
		
		wire[`RegBus] offset_extended; //��ƫ������չ
		
		//����load��������صı���
		reg stall_reg1_load;		//�жϵ�һ���������Ƿ���load���������
		reg stall_reg2_load;		//�жϵڶ����������Ƿ���load���������
		wire pre_inst_if_load;  //�ж���һ��ָ���Ƿ���load��ָ��
		
		assign pre_inst_if_load = (ex_aluop_i == `EXE_LW_OP) ? 1'b1 : 1'b0;
		
		//assign stall_req_id = 1'b0; //Ĭ��ֵΪ0������Ҫ����stall
		
		assign id_inst_out = id_inst;
		
		assign pc_4 = id_pc + 4;
		assign pc_8 = id_pc + 8;
		assign offset_extended = {{14{id_inst[15]}}, id_inst[15:0], 2'b00}; //����offset����չ
		
		always@(*)begin
		 if(rst == `RstEnable) begin
			alu_op <= `EXE_NOP_OP;
			rd_o <= `NOPRegAddr;
			rd_en <= `WriteDisable;
			instvalid <= `InstInvalid;
			reg1_rden <= 1'b0;
			reg2_rden <= 1'b0;
			reg1_addr <= `NOPRegAddr;
			reg2_addr <= `NOPRegAddr;
			imm <= 32'h0;
			link_addr_o <= `ZeroWord;
			target_pc <= `ZeroWord;
			if_branch <= 1'b0;
			next_is_in_delay_slot <= 1'b0;
		 end else begin
			alu_op <= `EXE_NOP_OP;
			rd_o <= id_inst[15:11];
			rd_en <= `WriteDisable;
			instvalid <= `InstInvalid;
			reg1_rden <= 1'b0;
			reg2_rden <= 1'b0;
			reg1_addr <= id_inst[25:21];		//ָ���е�RS
			reg2_addr <= id_inst[20:16];		//ָ���е�RT 
			imm <= `ZeroWord;
			link_addr_o <= `ZeroWord;
			target_pc <= `ZeroWord;
			if_branch <= 1'b0;
			next_is_in_delay_slot <= 1'b0;
			
			case(op)
				`EXE_RR: begin			//�����ж��Ƿ���RR��ָ��
					case(op2)
					 5'b00000: begin
					 case(op3)
						`EXE_OR: begin			//orָ��
							alu_op <= `EXE_OR_OP;
							rd_en <=`WriteEnable;
							instvalid <= `InstValid;
							reg1_rden <= 1'b1; //��Ҫ��ȡ�˿�1����
							reg2_rden <= 1'b1; //��Ҫ��ȡ�˿�2����
						end
						`EXE_AND: begin		//andָ��
							alu_op <= `EXE_AND_OP;
							rd_en <= `WriteEnable;
							instvalid <= `InstValid;
							reg1_rden <= 1'b1;
							reg2_rden <= 1'b1;
						end
						`EXE_XOR: begin		//xorָ��
							alu_op <= `EXE_XOR_OP;
							rd_en <= `WriteEnable;
							instvalid <= `InstValid;
							reg1_rden <= 1'b1;
							reg2_rden <= 1'b1;
						end
						`EXE_NOR: begin		//norָ��
							alu_op <= `EXE_NOR_OP;
							rd_en <= `WriteEnable;
							instvalid <= `InstValid;
							reg1_rden <= 1'b1;
							reg2_rden <= 1'b1;
						end
						`EXE_SLLV: begin		//sllvָ��
							alu_op <= `EXE_SLL_OP;
							rd_en <= `WriteEnable;
							instvalid <= `InstValid;
							reg1_rden <= 1'b1;
							reg2_rden <= 1'b1;
						end
						`EXE_SRLV: begin		//srlvָ��
							alu_op <= `EXE_SRL_OP;
							rd_en <= `WriteEnable;
							instvalid <= `InstValid;
							reg1_rden <= 1'b1;
							reg2_rden <= 1'b1;
						end
						`EXE_SRAV: begin		//sravָ��
							alu_op <= `EXE_SRA_OP;
							rd_en <= `WriteEnable;
							instvalid <= `InstValid;
							reg1_rden <= 1'b1;
							reg2_rden <= 1'b1;
						end
						`EXE_ADD: begin		//����addָ�� rd �� rs + rt
							alu_op <= `EXE_ADD_OP;
							rd_en <= `WriteEnable;
							instvalid <= `InstValid;
							reg1_rden <= 1'b1;
							reg2_rden <= 1'b1;
						end
						`EXE_ADDU: begin		//adduָ��
							alu_op <= `EXE_ADDU_OP;
							rd_en <= `WriteEnable;
							instvalid <= `InstValid;
							reg1_rden <= 1'b1;
							reg2_rden <= 1'b1;
						end
						`EXE_SUB: begin		//subָ��
							alu_op <= `EXE_SUB_OP;
							rd_en <= `WriteEnable;
							instvalid <= `InstValid;
							reg1_rden <= 1'b1;
							reg2_rden <= 1'b1;
						end
						`EXE_SUBU: begin		//subuָ��
							alu_op <= `EXE_SUBU_OP;
							rd_en <= `WriteEnable;
							instvalid <= `InstValid;
							reg1_rden <= 1'b1;
							reg2_rden <= 1'b1;
						end
						`EXE_MULT: begin		//multָ��
							alu_op <= `EXE_MULT_OP;
							rd_en <= `WriteEnable;
							instvalid <= `InstValid;
							reg1_rden <= 1'b1;
							reg2_rden <= 1'b1;
						end
						`EXE_MULTU: begin		//multuָ��
							alu_op <= `EXE_MULTU_OP;
							rd_en <= `WriteEnable;
							instvalid <= `InstValid;
							reg1_rden <= 1'b1;
							reg2_rden <= 1'b1;
						end
						`EXE_SLT: begin		//sltָ��
							alu_op <= `EXE_SLT_OP;
							rd_en <= `WriteEnable;
							instvalid <= `InstValid;
							reg1_rden <= 1'b1;
							reg2_rden <= 1'b1;
						end
						`EXE_SLTU: begin		//sltuָ��
							alu_op <= `EXE_SLTU_OP;
							rd_en <= `WriteEnable;
							instvalid <= `InstValid;
							reg1_rden <= 1'b1;
							reg2_rden <= 1'b1;
						end
						`EXE_JR: begin				//jrָ� ��rs��ֵ����pc
							alu_op <= `EXE_JR_OP;
							rd_en <= `WriteDisable;
							instvalid <= `InstValid;
							reg1_rden <= 1'b1;
							reg2_rden <= 1'b0;
							link_addr_o <= `ZeroWord;		//����Ҫ���淵�ص�ַ
							target_pc <= rs_o;				//��rs�Ĵ�����ֵ����target_pc
							if_branch <= 1'b1;
							next_is_in_delay_slot <= 1'b1;
						end
						`EXE_JALR: begin			//jalrָ� ��rs��ֵ����pc�� ����ָ��ĺ���ڶ���ָ���ַ����rd
							alu_op <= `EXE_JALR_OP;
							rd_en <= `WriteDisable;
							instvalid <= `InstValid;
							reg1_rden <= 1'b1;
							reg2_rden <= 1'b0;
							link_addr_o <= pc_8;			//������ĵڶ���ָ���
							rd_o <= id_inst[15:11];		//д��rd�Ĵ����ĵ�ַ
							target_pc <= rs_o;			//��rs�Ĵ�����ֵ����target_pc
							if_branch <= 1'b1;
							next_is_in_delay_slot <= 1'b1;
						end
						`EXE_MULT: begin						//�з������˷�
							alu_op <= `EXE_MULT_OP;
							rd_en <= `WriteDisable;
							instvalid <= `InstValid;
							reg1_rden <= 1'b1;
							reg2_rden <= 1'b1;
						end	
						`EXE_MULTU: begin						//�޷������˷�
							alu_op <= `EXE_MULTU_OP;
							rd_en <= `WriteDisable;
							instvalid <= `InstValid;
							reg1_rden <= 1'b1;
							reg2_rden <= 1'b1;
						end
					 default: begin
					 end
					 endcase
					 end
					default: begin
					end
					endcase
					end
				//��������I����J��ָ��
				//I��ָ��
				`EXE_ORI: begin				//GPR[rt] �� GPR[rs] or zero_extend(immediate)
					rd_en <= `WriteEnable; //����ori��Ҫ�����д��Ŀ�ļĴ�������дʹ�ܿ���
					alu_op <= `EXE_OR_OP; //alu����or����
					reg1_rden <= 1'b1; 	//��Ҫ�Ӷ˿�1��ȡ����
					reg2_rden <= 1'b0;	//����Ҫ�Ӷ˿�2��ȡ����
					imm <= {16'h0, id_inst[15:0]}; 
					rd_o <= id_inst[20:16];
					instvalid <= `InstValid;
				 end
				`EXE_ANDI: begin				//andiָ��
					rd_en <= `WriteEnable;
					instvalid <= `InstValid;
					reg1_rden <= 1'b1;
					reg2_rden <= 1'b0;
					imm <= {16'h0, id_inst[15:0]};
					rd_o <= id_inst[20:16];
					alu_op <= `EXE_AND_OP;
				end
				`EXE_XORI: begin				//xoriָ�� GPR[rt] �� GPR[rs] xor zero_extend(immediate)
					rd_en <= `WriteEnable;
					instvalid <= `InstValid;
					reg1_rden <= 1'b1;
					reg2_rden <= 1'b0;
					imm <= {16'h0, id_inst[15:0]};
					rd_o <= id_inst[20:16];
					alu_op <= `EXE_XOR_OP;
				end
				`EXE_LUI: begin				//luiָ��
					rd_en <= `WriteEnable;
					instvalid <= `InstValid;
					reg1_rden <= 1'b1;
					reg2_rden <= 1'b0;
					imm <= {id_inst[15:0], 16'h0};
					rd_o <= id_inst[20:16];
					alu_op <= `EXE_OR_OP;
				end
				`EXE_ADDI: begin			
				/*addiָ��
				  temp �� (GPR[rs]31||GPR[rs]31..0) + sign_extend(immediate) if temp32 =? temp31 then
				  SignalException(IntegerOverflow)
				  else
				  GPR[rt] �� temp endif*/
					rd_en <= `WriteEnable;
					instvalid <= `InstValid;
					reg1_rden <= 1'b1;
					reg2_rden <= 1'b0;
					imm <= {{16{id_inst[15]}}, id_inst[15:0]}; //���з���λ��չ������д���λ16��
					rd_o <= id_inst[20:16];
					alu_op <= `EXE_ADDI_OP;
				end
				`EXE_ADDIU: begin			//addiuָ��
					rd_en <= `WriteEnable;
					instvalid <= `InstValid;
					reg1_rden <= 1'b1;
					reg2_rden <= 1'b0;
					imm <= {{16{id_inst[15]}}, id_inst[15:0]};
					rd_o <= id_inst[20:16];
					alu_op <= `EXE_ADDIU_OP;
				end
				`EXE_SLTI: begin			//sltiָ��   rt �� (rs < immediate)
					rd_en <= `WriteEnable;
					instvalid <= `InstValid;
					reg1_rden <= 1'b1;
					reg2_rden <= 1'b0;
					imm <= {{16{id_inst[15]}}, id_inst[15:0]};
					rd_o <= id_inst[20:16];
					alu_op <= `EXE_SLTI_OP;
				end
				`EXE_SLTIU: begin			//sltiuָ��  rt �� (unsigned rs < unsigned immediate)
					rd_en <= `WriteEnable;
					instvalid <= `InstValid;
					reg1_rden <= 1'b1;
					reg2_rden <= 1'b0;
					imm <= {{16{id_inst[15]}}, id_inst[15:0]};
					rd_o <= id_inst[20:16];
					alu_op <= `EXE_SLTIU_OP;
				end
				//J��ָ��
				`EXE_J: begin					//ֱ����תJָ�� �µĵ�ַ����Ҫ��pc+4���ǰ4λ����target��28λ������λ��ֵ
					rd_en <= `WriteDisable;
					alu_op <= `EXE_J_OP;
					reg1_rden <= 1'b0;		//ֱ����ת������Ҫ���мĴ����Ķ�����
					reg2_rden <= 1'b0;
					link_addr_o <= `ZeroWord;    //����Ҫ���淵�ص�ַ
					if_branch <= 1'b1;
					next_is_in_delay_slot <= 1'b1;
					instvalid <= `InstValid;
					target_pc <= {pc_4[31:28], id_inst[25:0], 2'b00};
				end
				`EXE_JAL: begin				//ֱ����תjalָ� ͬjָ���ͬ��Ҫ����תָ���ĵڶ���ָ���ַ���ظ�31�żĴ���
					rd_en <= `WriteDisable; 
					alu_op <= `EXE_J_OP;
					reg1_rden <= 1'b0;
					reg2_rden <= 1'b0;
					link_addr_o <= pc_8;		//������ĵڶ���ָ��ĵ�ַ����
					rd_o <= 5'b11111;			//Ŀ��Ĵ�����ַ
					if_branch <= 1'b1;
					next_is_in_delay_slot <= 1'b1;
					instvalid <= `InstValid;
					target_pc <= {pc_4[31:28], id_inst[25:0], 2'b00}; 
				end
				
				//lw��sw��ָ��
				`EXE_LW: begin						//rt �� memory[base+offset]
					rd_en <= `WriteEnable;
					alu_op <= `EXE_LW_OP;		
					reg1_rden <= 1'b1;			//��rs�ļĴ�����ֵ��Ϊ��ֵ���е�ַ����
					reg2_rden <= 1'b0;		   //�����ǽ�����д�뵽rt�Ĵ������ʲ���Ҫ���ж�����
					rd_o <= id_inst[20:16];
					instvalid <= `InstValid;
				end
				`EXE_SW: begin						//memory[base+offset] �� rt  base = [rs]
					rd_en <= `WriteDisable;
					alu_op <= `EXE_SW_OP;
					reg1_rden <= 1'b1;
					reg2_rden <= 1'b1;
					instvalid <= `InstValid;
				end
				
				//I����תָ��
				`EXE_BEQ: begin			//��ָ֧�branch if equal����������Ĵ�����ֵ��ͬ������ת
					rd_en <= `WriteDisable;
					alu_op <= `EXE_BEQ_OP;
					reg1_rden <= 1'b1;
					reg2_rden <= 1'b1;
					instvalid <= `InstValid;
					if(rs_o == rt_o) begin
						target_pc <= pc_4 + offset_extended;
						if_branch <= 1'b1;
						next_is_in_delay_slot <= 1'b1;
					end
				end
				`EXE_BGTZ: begin			//��ָ֧������һ���Ĵ�����ֵ����0������ת
					rd_en <= `WriteDisable;
					alu_op <= `EXE_BGTZ_OP;
					reg1_rden <= 1'b1;
					reg2_rden <= 1'b0;
					instvalid <= `InstValid;
					if((rs_o[31] == 1'b0) && (rs_o != `ZeroWord)) begin		//�����λ�ж�
						target_pc <= pc_4 + offset_extended;
						if_branch <= 1'b1;
						next_is_in_delay_slot <= 1'b1;
					end
				end
				`EXE_BLEZ: begin			//��ָ֧������һ���Ĵ�����ֵС�ڵ���0������ת
					rd_en <= `WriteDisable;
					alu_op <= `EXE_BLEZ_OP;
					reg1_rden <= 1'b1;
					reg2_rden <= 1'b0;
					instvalid <= `InstValid;
					if((rs_o[31] == 1'b1) || (rs_o == `ZeroWord)) begin
						target_pc <= pc_4 + offset_extended;
						if_branch <= 1'b1;
						next_is_in_delay_slot <= 1'b1;
					end
				end
				`EXE_BNE: begin		//��ָ֧���������Ĵ���������һ��������ת
					rd_en <= `WriteDisable;
					alu_op <= `EXE_BNE_OP;
					reg1_rden <= 1'b1;
					reg2_rden <= 1'b1;
					instvalid <= `InstValid;
					if(rs_o != rt_o) begin
						target_pc <= pc_4 + offset_extended;
						if_branch <= 1'b1;
						next_is_in_delay_slot <= 1'b1;
					end
				end
				`EXE_REGIMM_INST: begin			//һ������ķ�ָ֧��
					case(op4)			//����ָ���16-20λ�����ж�����
						`EXE_BGEZ: begin			//����Ĵ���1��ֵ���ڵ���0������ת
							rd_en <= `WriteDisable;
							alu_op <= `EXE_BGEZ_OP;
							reg1_rden <= 1'b1;
							reg2_rden <= 1'b0;
							instvalid <= `InstValid;
							if(rs_o[31] == 1'b0) begin
								target_pc <= pc_4 + offset_extended;
								if_branch <= 1'b1;
								next_is_in_delay_slot <= 1'b1;
							end
						end
						`EXE_BGEZAL: begin		//ͬbgez�� ������Ҫ����ת��ĵڶ���ָ��ĵ�ַ���͸�31�żĴ���
							rd_en <= `WriteDisable;
							alu_op <= `EXE_BGEZAL_OP;
							reg1_rden <= 1'b1;
							reg2_rden <= 1'b0;
							link_addr_o <= pc_8;
							rd_o <= 5'b11111;
							instvalid <= `InstValid;
							if(rs_o[31] == 1'b0) begin
								target_pc <= pc_4 + offset_extended;
								if_branch <= 1'b1;
								next_is_in_delay_slot <= 1'b1;
							end
						end
						`EXE_BLTZ: begin			//���rsλ�üĴ�����ֵС��0������ת
							rd_en <= `WriteDisable;
							alu_op <= `EXE_BGEZAL_OP;
							reg1_rden <= 1'b1;
							reg2_rden <= 1'b0;
							instvalid <= `InstValid;
							if(rs_o[31] == 1'b1) begin
								target_pc <= pc_4 + offset_extended;
								if_branch <= 1'b1;
								next_is_in_delay_slot <= 1'b1;
							end
						end
					default: begin
					end
					endcase
				end
				 default: begin
				 end
			endcase
			if((id_inst[31:21] == 11'b00000000000))begin //sllָ�� �߼�����
				if(op3 == `EXE_SLL)begin
					rd_en <= `WriteEnable;
					instvalid <= `InstValid;
					reg1_rden <= 1'b0;
					reg2_rden <= 1'b1;
					imm[4:0] <= id_inst[10:6];
					rd_o <= id_inst[15:11];
					alu_op <= `EXE_SLL_OP;
				end else if(op3 == `EXE_SRL)begin		//srlָ�� �߼�����
					rd_en <= `WriteEnable;
					instvalid <= `InstValid;
					reg1_rden <= 1'b0;
					reg2_rden <= 1'b1;
					imm[4:0] <= id_inst[10:6];
					rd_o <= id_inst[15:11];
					alu_op <= `EXE_SRL_OP;
				end else if(op3 == `EXE_SRA)begin		//sraָ�� ��������
					rd_en <= `WriteEnable;
					instvalid <= `InstValid;
					reg1_rden <= 1'b0;
					reg2_rden <= 1'b1;
					imm[4:0] <= id_inst[10:6];
					rd_o <= id_inst[15:11];
					alu_op <= `EXE_SRA_OP;
				end
			end
		end
		end
		
		
		//ȷ��alu��Դ������1
		//ʹ��dataforwarding����������
		always@(*)begin
		 stall_reg1_load <= 1'b0;
		 if(rst == `RstEnable) begin
				rs_o <= `ZeroWord;  
		 end else if(pre_inst_if_load == 1'b1 && ex_waddr == reg1_addr && reg1_rden == 1'b1) begin
				stall_reg1_load <= 1'b1;
		 end else if((reg1_rden == 1'b1) && (ex_wreg_en == 1'b1) //�������ָ������ݳ�ͻ
						&& ex_waddr == reg1_addr)begin
				rs_o <= ex_wdata_i;
		 end else if((reg1_rden == 1'b1) && (mem_wreg_en == 1'b1) //������һ��ָ������ݳ�ͻ
						&& mem_waddr == reg1_addr) begin
				rs_o <= mem_wdata_i;
		 end else if(reg1_rden == 1'b0)begin				//�������Ҫ���ʼĴ���������������ֵ
				rs_o <= imm;
		 end else if(reg1_rden == 1'b1)begin
				rs_o <= reg1_data_i;
		 end else begin
				rs_o <= `ZeroWord;
			end
		end
		//ȷ��alu��Դ������2
		always@(*)begin
		 stall_reg2_load <= 1'b0;
		 if(rst == `RstEnable) begin
				rt_o <= `ZeroWord;
		 end else if(pre_inst_if_load == 1'b1 && ex_waddr == reg2_addr && reg2_rden == 1'b1) begin
				stall_reg2_load <= 1'b1;
		 end else if((reg2_rden == 1'b1) && ex_wreg_en == 1'b1
						&& ex_waddr == reg2_addr)begin
				rt_o <= ex_wdata_i;
		 end else if((reg2_rden == 1'b1) && mem_wreg_en == 1'b1
						&& mem_waddr == reg2_addr)begin
				rt_o <= mem_wdata_i;
		 end else if(reg2_rden == 1'b0)begin
				rt_o <= imm;
		 end else if(reg2_rden == 1'b1)begin
				rt_o <= reg2_data_i;
		 end else begin
				rt_o <= `ZeroWord;
			end
		end
		//���Ƿ����ӳٲ��е��źŽ������
		always@(*) begin
			if(rst == `RstEnable) begin
				is_in_delay_slot_o <= 1'b0;
			end else begin
				is_in_delay_slot_o <= is_in_delay_slot;
			end
		end
		
		assign stall_req_id = stall_reg1_load | stall_reg2_load;    //ֻҪ��һ���Ĵ�������load��������أ��ͷ���stall����

endmodule
