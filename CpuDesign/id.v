`timescale 1ns / 1ps

`include "defines.v"
module id(
		input wire rst,
		
		input wire[`InstAddrBus] id_pc, //id阶段的指令的地址
		input wire[`InstBus] id_inst, //id阶段的指令
		
		input wire is_in_delay_slot, //判断当前指令是否是位于延迟槽里
		output reg if_branch, //判断当前指令是否是跳转指令
		
		output reg next_is_in_delay_slot, //表示下一条是否位于延迟槽里
		output reg[`RegBus] target_pc, //表示分支指令目标的pc地址
		output reg[`RegBus] link_addr_o, //转移地址要保存的返回地址
		output reg is_in_delay_slot_o, //将当前指令是否位于延迟槽的信号送出
		
		//读取Regfile的值
		input wire[`RegBus] reg1_data_i, //从regs的第一个输入端口输入数据
		input wire[`RegBus] reg2_data_i, //第二个端口输入
		
		output reg reg1_rden, //reg第一个端口的读使能信号
		output reg reg2_rden, //reg第二个端口的读使能信号
		output reg[`RegAddrBus] reg1_addr, //第一个端口的读地址
		output reg[`RegAddrBus] reg2_addr, //第二个端口的读地址
		
		output reg[`AluOpBus] alu_op, //alu操作符
		output reg[`RegBus] rs_o, //译码阶段alu进行的源操作数1即送入ex段的数据
		output reg[`RegBus] rt_o, //译码阶段alu进行的源操作数2
		output reg[`RegAddrBus] rd_o, //译码阶段的指令写入的寄存器地址
		output reg rd_en, //译码阶段指令是否要写入目的寄存器	
		output wire stall_req_id, //表示id段是否申请stall
		
		output wire[`RegBus] id_inst_out, //将id阶段的指令进行输出，便于ex段进行
		
		
		//用于实现dataforwarding消除数据相关
		//处于ex段的指令的运算结果
		input wire ex_wreg_en, //判断是否需要写入到目的寄存器
		input wire[`RegBus] ex_wdata_i, //需要写入的数据
		input wire[`RegAddrBus] ex_waddr, //需要写入的目标寄存器的地址
		
		//处于mem段的运算结果
		input wire mem_wreg_en, //判断是否需要写入到目的寄存器
		input wire[`RegBus] mem_wdata_i, //需要写入的数据
		input wire[`RegAddrBus] mem_waddr, //需要写入的目标寄存器的地址
		
		//消除load型数据相关
		input wire[`AluOpBus] ex_aluop_i   //从ex段获取的操作符
    );
		wire[5:0] op = id_inst[31:26];   //指令码用于判断r、i、j的类型
		wire[4:0] op2 = id_inst[10:6];	
		wire[5:0] op3 = id_inst[5:0];		//功能码用于判断具体是哪一个操作
		wire[4:0] op4 = id_inst[20:16];
		
		reg[`RegBus] imm; //指令需要的立即数
		reg instvalid; //判断指令是否有效
		
		wire[`RegBus] pc_8;		//保存下面第二条指令的地址
		wire[`RegBus] pc_4;		//保存下一条指令的地址
		
		wire[`RegBus] offset_extended; //将偏移量扩展
		
		//消除load型数据相关的变量
		reg stall_reg1_load;		//判断第一个操作数是否有load型数据相关
		reg stall_reg2_load;		//判断第二个操作数是否有load型数据相关
		wire pre_inst_if_load;  //判断上一条指令是否是load型指令
		
		assign pre_inst_if_load = (ex_aluop_i == `EXE_LW_OP) ? 1'b1 : 1'b0;
		
		//assign stall_req_id = 1'b0; //默认值为0即不需要进行stall
		
		assign id_inst_out = id_inst;
		
		assign pc_4 = id_pc + 4;
		assign pc_8 = id_pc + 8;
		assign offset_extended = {{14{id_inst[15]}}, id_inst[15:0], 2'b00}; //进行offset的扩展
		
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
			reg1_addr <= id_inst[25:21];		//指令中的RS
			reg2_addr <= id_inst[20:16];		//指令中的RT 
			imm <= `ZeroWord;
			link_addr_o <= `ZeroWord;
			target_pc <= `ZeroWord;
			if_branch <= 1'b0;
			next_is_in_delay_slot <= 1'b0;
			
			case(op)
				`EXE_RR: begin			//进行判断是否是RR类指令
					case(op2)
					 5'b00000: begin
					 case(op3)
						`EXE_OR: begin			//or指令
							alu_op <= `EXE_OR_OP;
							rd_en <=`WriteEnable;
							instvalid <= `InstValid;
							reg1_rden <= 1'b1; //需要读取端口1的数
							reg2_rden <= 1'b1; //需要读取端口2的数
						end
						`EXE_AND: begin		//and指令
							alu_op <= `EXE_AND_OP;
							rd_en <= `WriteEnable;
							instvalid <= `InstValid;
							reg1_rden <= 1'b1;
							reg2_rden <= 1'b1;
						end
						`EXE_XOR: begin		//xor指令
							alu_op <= `EXE_XOR_OP;
							rd_en <= `WriteEnable;
							instvalid <= `InstValid;
							reg1_rden <= 1'b1;
							reg2_rden <= 1'b1;
						end
						`EXE_NOR: begin		//nor指令
							alu_op <= `EXE_NOR_OP;
							rd_en <= `WriteEnable;
							instvalid <= `InstValid;
							reg1_rden <= 1'b1;
							reg2_rden <= 1'b1;
						end
						`EXE_SLLV: begin		//sllv指令
							alu_op <= `EXE_SLL_OP;
							rd_en <= `WriteEnable;
							instvalid <= `InstValid;
							reg1_rden <= 1'b1;
							reg2_rden <= 1'b1;
						end
						`EXE_SRLV: begin		//srlv指令
							alu_op <= `EXE_SRL_OP;
							rd_en <= `WriteEnable;
							instvalid <= `InstValid;
							reg1_rden <= 1'b1;
							reg2_rden <= 1'b1;
						end
						`EXE_SRAV: begin		//srav指令
							alu_op <= `EXE_SRA_OP;
							rd_en <= `WriteEnable;
							instvalid <= `InstValid;
							reg1_rden <= 1'b1;
							reg2_rden <= 1'b1;
						end
						`EXE_ADD: begin		//进行add指令 rd ← rs + rt
							alu_op <= `EXE_ADD_OP;
							rd_en <= `WriteEnable;
							instvalid <= `InstValid;
							reg1_rden <= 1'b1;
							reg2_rden <= 1'b1;
						end
						`EXE_ADDU: begin		//addu指令
							alu_op <= `EXE_ADDU_OP;
							rd_en <= `WriteEnable;
							instvalid <= `InstValid;
							reg1_rden <= 1'b1;
							reg2_rden <= 1'b1;
						end
						`EXE_SUB: begin		//sub指令
							alu_op <= `EXE_SUB_OP;
							rd_en <= `WriteEnable;
							instvalid <= `InstValid;
							reg1_rden <= 1'b1;
							reg2_rden <= 1'b1;
						end
						`EXE_SUBU: begin		//subu指令
							alu_op <= `EXE_SUBU_OP;
							rd_en <= `WriteEnable;
							instvalid <= `InstValid;
							reg1_rden <= 1'b1;
							reg2_rden <= 1'b1;
						end
						`EXE_MULT: begin		//mult指令
							alu_op <= `EXE_MULT_OP;
							rd_en <= `WriteEnable;
							instvalid <= `InstValid;
							reg1_rden <= 1'b1;
							reg2_rden <= 1'b1;
						end
						`EXE_MULTU: begin		//multu指令
							alu_op <= `EXE_MULTU_OP;
							rd_en <= `WriteEnable;
							instvalid <= `InstValid;
							reg1_rden <= 1'b1;
							reg2_rden <= 1'b1;
						end
						`EXE_SLT: begin		//slt指令
							alu_op <= `EXE_SLT_OP;
							rd_en <= `WriteEnable;
							instvalid <= `InstValid;
							reg1_rden <= 1'b1;
							reg2_rden <= 1'b1;
						end
						`EXE_SLTU: begin		//sltu指令
							alu_op <= `EXE_SLTU_OP;
							rd_en <= `WriteEnable;
							instvalid <= `InstValid;
							reg1_rden <= 1'b1;
							reg2_rden <= 1'b1;
						end
						`EXE_JR: begin				//jr指令， 将rs的值赋给pc
							alu_op <= `EXE_JR_OP;
							rd_en <= `WriteDisable;
							instvalid <= `InstValid;
							reg1_rden <= 1'b1;
							reg2_rden <= 1'b0;
							link_addr_o <= `ZeroWord;		//不需要保存返回地址
							target_pc <= rs_o;				//将rs寄存器的值赋给target_pc
							if_branch <= 1'b1;
							next_is_in_delay_slot <= 1'b1;
						end
						`EXE_JALR: begin			//jalr指令， 将rs的值赋给pc， 将该指令的后面第二条指令地址赋给rd
							alu_op <= `EXE_JALR_OP;
							rd_en <= `WriteDisable;
							instvalid <= `InstValid;
							reg1_rden <= 1'b1;
							reg2_rden <= 1'b0;
							link_addr_o <= pc_8;			//将后面的第二条指令保存
							rd_o <= id_inst[15:11];		//写入rd寄存器的地址
							target_pc <= rs_o;			//将rs寄存器的值赋给target_pc
							if_branch <= 1'b1;
							next_is_in_delay_slot <= 1'b1;
						end
						`EXE_MULT: begin						//有符号数乘法
							alu_op <= `EXE_MULT_OP;
							rd_en <= `WriteDisable;
							instvalid <= `InstValid;
							reg1_rden <= 1'b1;
							reg2_rden <= 1'b1;
						end	
						`EXE_MULTU: begin						//无符号数乘法
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
				//否则则是I或者J类指令
				//I类指令
				`EXE_ORI: begin				//GPR[rt] ← GPR[rs] or zero_extend(immediate)
					rd_en <= `WriteEnable; //由于ori需要将结果写入目的寄存器，故写使能可以
					alu_op <= `EXE_OR_OP; //alu进行or操作
					reg1_rden <= 1'b1; 	//需要从端口1读取数据
					reg2_rden <= 1'b0;	//不需要从端口2读取数据
					imm <= {16'h0, id_inst[15:0]}; 
					rd_o <= id_inst[20:16];
					instvalid <= `InstValid;
				 end
				`EXE_ANDI: begin				//andi指令
					rd_en <= `WriteEnable;
					instvalid <= `InstValid;
					reg1_rden <= 1'b1;
					reg2_rden <= 1'b0;
					imm <= {16'h0, id_inst[15:0]};
					rd_o <= id_inst[20:16];
					alu_op <= `EXE_AND_OP;
				end
				`EXE_XORI: begin				//xori指令 GPR[rt] ← GPR[rs] xor zero_extend(immediate)
					rd_en <= `WriteEnable;
					instvalid <= `InstValid;
					reg1_rden <= 1'b1;
					reg2_rden <= 1'b0;
					imm <= {16'h0, id_inst[15:0]};
					rd_o <= id_inst[20:16];
					alu_op <= `EXE_XOR_OP;
				end
				`EXE_LUI: begin				//lui指令
					rd_en <= `WriteEnable;
					instvalid <= `InstValid;
					reg1_rden <= 1'b1;
					reg2_rden <= 1'b0;
					imm <= {id_inst[15:0], 16'h0};
					rd_o <= id_inst[20:16];
					alu_op <= `EXE_OR_OP;
				end
				`EXE_ADDI: begin			
				/*addi指令
				  temp ← (GPR[rs]31||GPR[rs]31..0) + sign_extend(immediate) if temp32 =? temp31 then
				  SignalException(IntegerOverflow)
				  else
				  GPR[rt] ← temp endif*/
					rd_en <= `WriteEnable;
					instvalid <= `InstValid;
					reg1_rden <= 1'b1;
					reg2_rden <= 1'b0;
					imm <= {{16{id_inst[15]}}, id_inst[15:0]}; //进行符号位拓展，即续写最高位16次
					rd_o <= id_inst[20:16];
					alu_op <= `EXE_ADDI_OP;
				end
				`EXE_ADDIU: begin			//addiu指令
					rd_en <= `WriteEnable;
					instvalid <= `InstValid;
					reg1_rden <= 1'b1;
					reg2_rden <= 1'b0;
					imm <= {{16{id_inst[15]}}, id_inst[15:0]};
					rd_o <= id_inst[20:16];
					alu_op <= `EXE_ADDIU_OP;
				end
				`EXE_SLTI: begin			//slti指令   rt ← (rs < immediate)
					rd_en <= `WriteEnable;
					instvalid <= `InstValid;
					reg1_rden <= 1'b1;
					reg2_rden <= 1'b0;
					imm <= {{16{id_inst[15]}}, id_inst[15:0]};
					rd_o <= id_inst[20:16];
					alu_op <= `EXE_SLTI_OP;
				end
				`EXE_SLTIU: begin			//sltiu指令  rt ← (unsigned rs < unsigned immediate)
					rd_en <= `WriteEnable;
					instvalid <= `InstValid;
					reg1_rden <= 1'b1;
					reg2_rden <= 1'b0;
					imm <= {{16{id_inst[15]}}, id_inst[15:0]};
					rd_o <= id_inst[20:16];
					alu_op <= `EXE_SLTIU_OP;
				end
				//J类指令
				`EXE_J: begin					//直接跳转J指令 新的地址是需要将pc+4后的前4位加上target低28位左移两位的值
					rd_en <= `WriteDisable;
					alu_op <= `EXE_J_OP;
					reg1_rden <= 1'b0;		//直接跳转，不需要进行寄存器的读操作
					reg2_rden <= 1'b0;
					link_addr_o <= `ZeroWord;    //不需要保存返回地址
					if_branch <= 1'b1;
					next_is_in_delay_slot <= 1'b1;
					instvalid <= `InstValid;
					target_pc <= {pc_4[31:28], id_inst[25:0], 2'b00};
				end
				`EXE_JAL: begin				//直接跳转jal指令， 同j指令但是同样要将跳转指令后的第二条指令地址返回给31号寄存器
					rd_en <= `WriteDisable; 
					alu_op <= `EXE_J_OP;
					reg1_rden <= 1'b0;
					reg2_rden <= 1'b0;
					link_addr_o <= pc_8;		//将下面的第二条指令的地址保存
					rd_o <= 5'b11111;			//目标寄存器地址
					if_branch <= 1'b1;
					next_is_in_delay_slot <= 1'b1;
					instvalid <= `InstValid;
					target_pc <= {pc_4[31:28], id_inst[25:0], 2'b00}; 
				end
				
				//lw、sw类指令
				`EXE_LW: begin						//rt ← memory[base+offset]
					rd_en <= `WriteEnable;
					alu_op <= `EXE_LW_OP;		
					reg1_rden <= 1'b1;			//将rs的寄存器的值作为基值进行地址计算
					reg2_rden <= 1'b0;		   //由于是将数据写入到rt寄存器，故不需要进行读操作
					rd_o <= id_inst[20:16];
					instvalid <= `InstValid;
				end
				`EXE_SW: begin						//memory[base+offset] ← rt  base = [rs]
					rd_en <= `WriteDisable;
					alu_op <= `EXE_SW_OP;
					reg1_rden <= 1'b1;
					reg2_rden <= 1'b1;
					instvalid <= `InstValid;
				end
				
				//I类跳转指令
				`EXE_BEQ: begin			//分支指令，branch if equal，如果两个寄存器的值相同，则跳转
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
				`EXE_BGTZ: begin			//分支指令，如果第一个寄存器的值大于0，则跳转
					rd_en <= `WriteDisable;
					alu_op <= `EXE_BGTZ_OP;
					reg1_rden <= 1'b1;
					reg2_rden <= 1'b0;
					instvalid <= `InstValid;
					if((rs_o[31] == 1'b0) && (rs_o != `ZeroWord)) begin		//用最高位判断
						target_pc <= pc_4 + offset_extended;
						if_branch <= 1'b1;
						next_is_in_delay_slot <= 1'b1;
					end
				end
				`EXE_BLEZ: begin			//分支指令，如果第一个寄存器的值小于等于0，则跳转
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
				`EXE_BNE: begin		//分支指令，如果两个寄存器的数不一样，则跳转
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
				`EXE_REGIMM_INST: begin			//一类特殊的分支指令
					case(op4)			//根据指令的16-20位进行判断区分
						`EXE_BGEZ: begin			//如果寄存器1的值大于等于0，则跳转
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
						`EXE_BGEZAL: begin		//同bgez， 但是需要将跳转后的第二条指令的地址发送给31号寄存器
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
						`EXE_BLTZ: begin			//如果rs位置寄存器的值小于0，则跳转
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
			if((id_inst[31:21] == 11'b00000000000))begin //sll指令 逻辑左移
				if(op3 == `EXE_SLL)begin
					rd_en <= `WriteEnable;
					instvalid <= `InstValid;
					reg1_rden <= 1'b0;
					reg2_rden <= 1'b1;
					imm[4:0] <= id_inst[10:6];
					rd_o <= id_inst[15:11];
					alu_op <= `EXE_SLL_OP;
				end else if(op3 == `EXE_SRL)begin		//srl指令 逻辑右移
					rd_en <= `WriteEnable;
					instvalid <= `InstValid;
					reg1_rden <= 1'b0;
					reg2_rden <= 1'b1;
					imm[4:0] <= id_inst[10:6];
					rd_o <= id_inst[15:11];
					alu_op <= `EXE_SRL_OP;
				end else if(op3 == `EXE_SRA)begin		//sra指令 算数右移
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
		
		
		//确定alu的源操作数1
		//使用dataforwarding解决数据相关
		always@(*)begin
		 stall_reg1_load <= 1'b0;
		 if(rst == `RstEnable) begin
				rs_o <= `ZeroWord;  
		 end else if(pre_inst_if_load == 1'b1 && ex_waddr == reg1_addr && reg1_rden == 1'b1) begin
				stall_reg1_load <= 1'b1;
		 end else if((reg1_rden == 1'b1) && (ex_wreg_en == 1'b1) //解决相邻指令的数据冲突
						&& ex_waddr == reg1_addr)begin
				rs_o <= ex_wdata_i;
		 end else if((reg1_rden == 1'b1) && (mem_wreg_en == 1'b1) //解决相隔一条指令的数据冲突
						&& mem_waddr == reg1_addr) begin
				rs_o <= mem_wdata_i;
		 end else if(reg1_rden == 1'b0)begin				//如果不需要访问寄存器则用立即数赋值
				rs_o <= imm;
		 end else if(reg1_rden == 1'b1)begin
				rs_o <= reg1_data_i;
		 end else begin
				rs_o <= `ZeroWord;
			end
		end
		//确定alu的源操作数2
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
		//将是否处在延迟槽中的信号进行输出
		always@(*) begin
			if(rst == `RstEnable) begin
				is_in_delay_slot_o <= 1'b0;
			end else begin
				is_in_delay_slot_o <= is_in_delay_slot;
			end
		end
		
		assign stall_req_id = stall_reg1_load | stall_reg2_load;    //只要有一个寄存器发生load型数据相关，就发出stall申请

endmodule
