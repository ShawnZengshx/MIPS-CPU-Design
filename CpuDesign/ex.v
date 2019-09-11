`timescale 1ns / 1ps

`include "defines.v"
module ex(
		input wire rst,
		
		input wire[`AluOpBus] id_aluop, //id段传入的alu的操作符
		input wire[`RegBus] id_reg1, //从id段传入的源操作数1
		input wire[`RegBus] id_reg2, //从id段传入的源操作数2
		input wire[`RegAddrBus] id_waddr, //id段传入的将结果写入到目的寄存器的地址
		input wire id_wen, //id段传入的是否要将结果写入到目的寄存器中
		
		//lw、sw类的指令的控制
		input wire [`RegBus] id_inst,    //ex段从id段得到的指令，用于获取offset
		output wire [`RegBus] mem_waddr_o, //要写入存储器的地址
		output wire [`RegBus] id_reg2_o,   //输出从存储器读取的数据
		output wire [`AluOpBus] aluop_o,   //输出的操作符
		//用于乘除法的寄存器输出
		output reg[`RegBus] hi_o,   //输出到hi寄存器的值
		output reg[`RegBus] lo_o,   //输出到lo寄存器的值
		output reg   hilo_we,       //是否需要写入到hi_lo寄存器
		
		//分支控制指令输入
		input wire [`RegBus] link_address_i,  //ex段保存的分支地址需要返回的地址
		input wire is_in_delay_slot_i, //表示是否位于分支延迟槽
		input wire ex_if_branch,   //表示当前指令是否是分支指令
		
		//有符号乘法的标志状态
		input wire mult_finished,    //表示乘法是否结束
		output reg mult_start,     //表示开始有符号乘法
		//有符号乘法的输入输出
		input wire[63:0] signed_mult_result,    //表示有符号乘法的结果的输入
		output reg[31:0] signed_mult_op1,    //有符号乘法的操作数1
		output reg[31:0] signed_mult_op2,    //有符号乘法的操作数2
		
		output reg[`RegAddrBus] wd_waddr, //判断最终将结果写入到目的寄存器的地址
		output reg wd_wen, //判断最终是否需要将结果写入到目的寄存器
		output reg[`RegBus] wdata,  //最终得到的结果
		output reg stall_req_ex  //ex段是否申请stall
    );
	 
		reg[`RegBus] logicout; //用于保存alu计算的结果
		
		//进行乘法操作时的输出
		reg[63:0] mult_result; //保存32位乘法的结果
		wire[`RegBus] mult_op1; //保存乘法操作数1
		wire[`RegBus] mult_op2; //保存乘法操作数2
		 
		wire overflow; //表示结果是否溢出
		wire reg1_eq_reg2; //表示两个源操作数是否相同
		wire reg1_ls_reg2; //表示第一个操作数小于第二个操作数
		wire [`RegBus] id_reg2_comp; //第二个操作数的补码
		wire [`RegBus] id_reg1_comp; //第一个操作数的补码
		wire [`RegBus] id_reg1_not;  //第一个操作数取反后的数
		wire [`RegBus] id_reg2_not;  //第二个操作数的反码
		wire [`RegBus] id_reg2_not_comp; //第二个操作数的反码的补码
		wire [`RegBus] temp; //保留加法的结果
		wire [`RegBus] stemp; //保留减法的结果
		wire [`RegBus] signed_sum_result; //有符号数的结果
		wire [`RegBus] signed_sub_result; //有符号数的结果
		wire [`RegBus] unsigned_sum_result; //无符号数的结果
		wire [`RegBus] unsigned_sub_result; //无符号数的减法
		wire [63:0] mul_temp;
		reg stall_for_mult;		//是否由于乘法导致流水线暂停
		//assign stall_req_ex = 1'b0; //默认ex段不申请stall
		
		//lw、sw类控制
		assign aluop_o = id_aluop;
		assign mem_waddr_o = id_reg1 + {{16{id_inst[15]}}, id_inst[15:0]};
		assign id_reg2_o = id_reg2; //将数据送出
		
		/*assign id_reg2_comp = ((id_aluop == `EXE_SUB_OP)||
									  (id_aluop == `EXE_SUBU_OP) ||
									  (id_aluop == `EXE_SLT_OP)
									 )? (~id_reg2) + 1 : id_reg2;  //如果是减法操作或者是比较操作的
																			 //话，则第二个操作数取其补码*/
		//加减法控制
		assign id_reg1_comp = (id_reg1[31] == 1'b1) ?
									 {id_reg1[31], ~id_reg1[30:0]} + 1 : id_reg1;   //操作数1的补码
		assign id_reg2_comp = (id_reg2[31] == 1'b1) ?
									 {id_reg2[31], ~id_reg2[30:0]} + 1 : id_reg2;   //操作数2的补码
		assign id_reg2_not = {~id_reg2[31], id_reg2[30:0]}; //操作数2的相反数
		assign id_reg2_not_comp = (id_reg2_not[31] == 1'b1) ?
										  {id_reg2_not[31], ~id_reg2_not[30:0]} + 1 : id_reg2_not;  //操作数2的相反数的补码
		assign stemp = id_reg1_comp + id_reg2_not_comp;   
		assign signed_sub_result = (stemp[31] == 1'b1) ?
										  {stemp[31], ~stemp[30:0]} + 1 : stemp;
		assign unsigned_sub_result = id_reg1 - id_reg2;								  
		assign temp = id_reg1_comp + id_reg2_comp;		//用于临时寄存加法操作的结果，用于判断是否溢出
		assign signed_sum_result = (temp[31] == 1'b1) ?
								  {temp[31], ~temp[30:0]} + 1 : temp;
		assign unsigned_sum_result = id_reg1 +id_reg2; //无符号数直接相加
		
		//判断是否溢出，如果两个操作数均为负而结果为正或是两个操作数均为正而结果为负则为溢出
		assign overflow = ((!id_reg1[31] && !id_reg2[31]) && signed_sum_result[31]) ||
								((id_reg1[31] && id_reg2[31]) && !signed_sum_result[31]) || 
								((id_reg1[31] && !id_reg2[31]) && !signed_sub_result[31]) ||
								((!id_reg1[31] && id_reg2[31]) && signed_sub_result[31]);
								
		/*assign reg1_ls_reg2 = ((id_aluop == `EXE_SLT_OP))?   //如果是有符号数的比较
									 ((id_reg1[31] && !id_reg2[31]) ||
									  (!id_reg1[31] && !id_reg2[31] && sum_result[31])||
									  (id_reg1[31] && id_reg2[31] && sum_result[31])) :
									  (id_reg1 < id_reg2);*/
		
		//乘除法
		assign id_reg1_not = ~id_reg1;
		
		/*assign mult_op1 = ((id_aluop == `EXE_MULT_OP) && id_reg1[31] == 1) ?
								(~id_reg1) + 1 : id_reg1;    //如果是有符号数乘法则取且为负则取补码
		assign mult_op2 = ((id_aluop == `EXE_MULT_OP) && id_reg2[31] == 1) ? 
								(~id_reg2) + 1 : id_reg2;    //同操作数1*/
		
		assign mult_op1 = {0, id_reg1[30:0]};
		assign mult_op2 = {0, id_reg2[30:0]};
		assign mul_temp = mult_op1 * mult_op2;
		
		
		
		always@(*) begin
		 if(rst == `RstEnable) begin
			mult_result <= 64'b0;
			stall_for_mult <= 1'b0;
			mult_start <= 1'b0;
		 end else if(id_aluop == `EXE_MULT_OP) begin		//如果是有符号乘法
			if(mult_finished == 1'b0)begin		//如果乘法未完成
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
			mult_result <= id_reg1 * id_reg2;    //输出无符号乘法的结果
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
					logicout <= id_reg1 | id_reg2; //进行按位或运算
				end
				`EXE_AND_OP: begin
					logicout <= id_reg1 & id_reg2; //进行按位与计算
				end
				`EXE_XOR_OP: begin
					logicout <= id_reg1 ^ id_reg2; //进行异或计算
				end
				`EXE_NOR_OP: begin
					logicout <= ~(id_reg1 | id_reg2); //进行或非计算
				end
				`EXE_SRL_OP: begin
					logicout <= id_reg2 >> id_reg1[4:0]; //进行逻辑右移
				end
				`EXE_SLL_OP: begin
					logicout <= id_reg2 << id_reg1[4:0]; //进行逻辑左移
				end
				`EXE_SRA_OP: begin //进行算术右移
				end
				`EXE_SLT_OP, `EXE_SLTU_OP: begin			//进行比较
					logicout <= reg1_ls_reg2;
				end
				`EXE_ADD_OP, `EXE_ADDI_OP: begin //进行加法
					logicout <= signed_sum_result;
				end
				`EXE_ADDU_OP, `EXE_ADDIU_OP: begin
					logicout <= unsigned_sum_result;
				end
				`EXE_SUB_OP: begin			//进行减法操作
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
					wd_wen <= `WriteDisable; //如果结果溢出则不写入寄存器
			end else begin
					wd_wen <= id_wen;
			end
			wd_waddr <= id_waddr;
			if(ex_if_branch == 1'b1) begin
				wdata <= link_address_i;				//如果是分支指令则将跳转的地址作为结果输出
			end else begin
				wdata <= logicout;
			end
		end
		
		always@(*) begin //对于乘除法的输出
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
