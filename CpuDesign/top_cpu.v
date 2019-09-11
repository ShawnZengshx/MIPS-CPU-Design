`timescale 1ns / 1ps

`include "defines.v"
module top_cpu(
		input wire clk,
		input wire rst,
		
		input wire[`RegBus] rom_data_inst, //从指令寄存器取出的指令
		input wire[`RegBus] rom_data, //从数据存储器中取出的数据
		output wire[`RegBus] rom_addr_out, //输出到指令寄存器的地址
		output wire[`RegBus] rom_data_addr_out, //输出到数据存储器的地址
		output wire rom_data_ce_o, //数据存储器的使能信号
		output wire rom_ce_o //指令寄存器使能信号
		
    );
	 
		//分支相关的一些中间变量
		wire id_if_branch;    //表示id段是否是分支指令
		wire[`RegBus] pc_target_address;  //pc的目标地址
		wire id_if_branch_o;
		wire ex_if_branch;
		wire next_is_in_delay_slot_o;  //表明 下一条指令是否处在分支延迟槽里
		wire[`RegBus] link_addr_o;  //保存返回的地址（需要写入寄存器的）
		wire is_in_delay_slot_o;
		wire ex_is_in_delay_slot_O;  //表示ex段是否处在分支延迟槽
		wire ex_link_address_o;  //ex段得到的保存返回的地址
		wire is_in_delay_slot_o_ex;  //ex段传出的是否处在分支延迟槽
		//进行if->id段的连接
		wire[`InstAddrBus] pc; //需要读取的指令的地址
		wire[`InstAddrBus] id_pc_inst; //输出到id段的指令的地址
		wire[`InstBus] id_inst_i; //id段得到的指令
		
		//进行id段输出以及进行id->ex段的输入连接
		wire[`AluOpBus] id_aluop_o; //id段取得的alu操作符
		wire[`RegBus] id_reg1_o; //id段取得的源操作数1
		wire[`RegBus] id_reg2_o; //id段取得的源操作数2
		wire id_wreg_en; //id段取得的是否需要将结果写入到目的寄存器
		wire[`RegAddrBus] id_waddr; //id段取得的将结果写入到目的寄存器的地址
		
		//进行id/ex段输出以及ex段的输入连接
		wire[`AluOpBus] ex_aluop; //ex段采用的alu的操作符
		wire[`RegBus] ex_reg1_i; //ex段采用的alu的源操作数1
		wire[`RegBus] ex_reg2_i; //ex段采用的alu的源操作数2
		wire ex_wreg_eni; //ex段是否需要将结果写入到目的寄存器
		wire[`RegAddrBus] ex_waddri; //ex段最终写入寄存器的地址
		
		//进行ex段的输出以及ex/mem段的输入的连接
		wire	ex_wreg_eno; 
		wire[`RegAddrBus] ex_waddro;
		wire[`RegBus] ex_wdata_o;  //ex段最终计算的结果
		
		//进行ex/mem段的输出以及mem段的输入连接
		wire mem_wreg_eni; //mem段的是否需要将结果送到目的寄存器
		wire[`RegAddrBus] mem_waddri; //mem段将结果送到目的寄存器的地址
		wire[`RegBus] mem_wdata_i; //mem段的最终结果
		
		//进行mem段的输出以及mem/wb段的输入连接
		wire mem_wreg_eno;
		wire[`RegAddrBus] mem_waddro;
		wire[`RegBus] mem_wdata_o;
		 
		//进行mem/wb的输出以及wb段的输入的连接
		wire wb_wreg_eni;
		wire[`RegAddrBus] wb_waddri;
		wire[`RegBus] wb_wdata_i;
		
		//将id段与regfile连接
		wire reg1_read;	//reg端口1的读使能
		wire reg2_read; 	//reg端口2的读使能
		wire[`RegBus] reg1_data; //从reg端口1读出的数据
		wire[`RegBus] reg2_data; //从reg端口2读出的数据
		wire[`RegAddrBus] reg1_addr; //读取reg端口1的地址
		wire[`RegAddrBus] reg2_addr; //读取reg端口2的地址
		
		//表示各段的stall以及stall的请求
		wire stall_req_id;
		wire stall_req_ex;
		wire pc_stall;
		wire if_stall;
		wire id_stall;
		wire ex_stall;
		wire mem_stall;
		wire wb_stall;
		
		//用于实现乘法除法的
		wire ex_hilo_we_o;  //ex段输出的是否需要写入hilo寄存器
		wire[`RegBus] ex_hi_o;  //ex段输出的hi的值
		wire[`RegBus] ex_lo_o;  //ex段输出的lo的值
		wire mem_hilo_we_o;
		wire[`RegBus] mem_hi_o;
		wire[`RegBus] mem_lo_o;
		wire mem_wb_hilo_we_o;
		wire[`RegBus] mem_wb_hi_o;
		wire[`RegBus] mem_wb_lo_o;
		wire wb_hilo_we;
		wire[`RegBus] wb_hi_o;
		wire[`RegBus] wb_lo_o;
		
		//lw、sw相关
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
		//pc实例化
		pc pc0( .clk(clk), .pc(pc), .rst(rst), .ce(rom_ce_o), .pc_stall(pc_stall),
				  .target_pc(pc_target_address), .if_branch(id_if_branch_o)
				);
		
		assign rom_addr_out = pc; //指令寄存器的输入地址就是pc的值
		
		//if/id的实例化
		if_id if_id0(
					.clk(clk), .if_pc(pc), .rst(rst),
					.if_stall(if_stall), .id_stall(id_stall),
					.if_inst(rom_data_inst), .id_pc(id_pc_inst),
					.id_inst(id_inst_i)
						);
		
		//进行id段的模块化
		id id0(
			  .id_pc(id_pc_inst), .id_inst(id_inst_i), .rst(rst),
			  
			  //来自regfile的输入
			  .reg1_data_i(reg1_data), .reg2_data_i(reg2_data),
			  
			  //送到regfile模块的信息
			  .reg1_rden(reg1_read), .reg2_rden(reg2_read),
			  .reg1_addr(reg1_addr), .reg2_addr(reg2_addr),
			  
			  //送到id段的信息
			  .alu_op(id_aluop_o), .rs_o(id_reg1_o),
			  .rt_o(id_reg2_o), .rd_en(id_wreg_en), .rd_o(id_waddr),
			  
			  //来自ex段的输入
			  .ex_wreg_en(ex_wreg_eno), .ex_wdata_i(ex_wdata_o),
			  .ex_waddr(ex_waddro),
			  
			  //来自mem段的输入
			  .mem_wreg_en(mem_wreg_eno), .mem_wdata_i(mem_wdata_o),
			  .mem_waddr(mem_waddro), 
			  
			  //将stall请求输出
			  .stall_req_id(stall_req_id),
			  
			  //分支相关
			  .target_pc(pc_target_address),
			  .if_branch(id_if_branch_o), 
			  .is_in_delay_slot_o(is_in_delay_slot_o),
			  .link_addr_o(link_addr_o),
			  .next_is_in_delay_slot(next_is_in_delay_slot_o),
			  .is_in_delay_slot(is_in_delay_slot_o_ex),
			  
			  //lw、sw相关
			  .id_inst_out(inst_o),
			  .ex_aluop_i(ex_aluop_o)
				);
				
		//进行regfile的模块实例化
		regfile regfile1(
						.clk(clk), .we(wb_wreg_eni), .waddr(wb_waddri),
						.rst(rst),
						.wdata(wb_wdata_i), .re1(reg1_read), .re2(reg2_read),
						.raddr1(reg1_addr), .raddr2(reg2_addr),
						.rdata1(reg1_data), .rdata2(reg2_data)
							 );
		//进行id/ex模块的实例化
		id_ex id_ex0(
					.clk(clk),
					.rst(rst),
					.id_stall(id_stall), .ex_stall(ex_stall),
					//从id段传来的信息
					.id_aluop(id_aluop_o), .id_reg1(id_reg1_o), .id_reg2(id_reg2_o),
					.id_wen(id_wreg_en), .id_waddr(id_waddr),
					
					//传送到ex段的信息
					.ex_aluop(ex_aluop), .ex_reg1(ex_reg1_i), .ex_reg2(ex_reg2_i),
					.ex_wen(ex_wreg_eni), .ex_waddr(ex_waddri),
					
					//分支相关
					.id_is_in_delay_slot(is_in_delay_slot_o),
					.id_link_address(link_addro),
					.id_if_branch(id_if_branch_o),
					.next_is_in_delay_slot(next_is_in_delay_slot_o),
					.ex_is_in_delay_slot(ex_is_in_delay_slot_o),
					.ex_link_address(ex_link_address_o),
					.is_in_delay_slot_o(is_in_delay_slot_o_ex),
					.ex_if_branch(ex_if_branch),
					
					//lw、sw相关
					.id_inst(inst_o),
					.ex_inst(ex_inst_i)
						);
		//ex段的模块实例化
		ex ex0(
			  .rst(rst),
			  //从id/ex段传来的信息
			  .id_aluop(ex_aluop), .id_reg1(ex_reg1_i), .id_reg2(ex_reg2_i),
			  .id_wen(ex_wreg_eni), .id_waddr(ex_waddri),
			  
			  //输出到ex/mem模块的信息
			  .wd_wen(ex_wreg_eno), .wd_waddr(ex_waddro), .wdata(ex_wdata_o),
			  
			  //将ex段的stall请求输出
			  .stall_req_ex(stall_req_ex),
			  
			  //分支相关
			  .is_in_delay_slot_i(ex_is_in_delay_slot_o),
			  .link_address_i(ex_link_address_o),
			  .ex_if_branch(ex_if_branch),
				
			  //乘法相关
			  .hilo_we(ex_hilo_we_o),
			  .hi_o(ex_hi_o),
			  .lo_o(ex_lo_o),
			  //有符号乘法
			  .mult_finished(mult_is_done),
			  .mult_start(mult_start),
			  .signed_mult_result(signed_mult_result),
			  .signed_mult_op1(signed_mult_op1),
			  .signed_mult_op2(signed_mult_op2),
			  
			  //lw、sw相关
			  .id_inst(ex_inst_i),
			  .aluop_o(ex_aluop_o),
			  .mem_waddr_o(mem_addr_i),
			  .id_reg2_o(reg2_i)
				);
		//ex/mem模块实例化
		ex_mem ex_mem0(
						 .clk(clk),
						 .rst(rst),
						 .ex_stall(ex_stall), .mem_stall(mem_stall),
						 //来自ex段的信息
						 .ex_wen(ex_wreg_eno), .ex_waddr(ex_waddro), .ex_wdata(ex_wdata_o),
						 
						 //送到mem段的信息
						 .mem_wen(mem_wreg_eni), .mem_waddr(mem_waddri), .mem_wdata(mem_wdata_i),
						 
						 //乘法相关
						 .ex_hilo_wen(ex_hilo_we_o), .ex_hi_i(ex_hi_o), .ex_lo_i(ex_lo_o),
						 .mem_hilo_wen(mem_hilo_we_o), .mem_hi(mem_hi_o), .mem_lo(mem_lo_o),

						 //lw、sw相关
						 .ex_aluop(ex_aluop_o),
						 .ex_mem_addr(mem_addr_i),
						 .ex_reg2(reg2_i),
						 .mem_aluop(mem_aluop_o),
						 .mem_mem_addr(mem_addr_o),
						 .mem_reg2(mem_reg2)
						  );
		//mem模块实例化
		mem mem0(
				  .rst(rst),
				  //来自ex/mem的信息
				  .mem_wen(mem_wreg_eni), .mem_waddr(mem_waddri), .mem_data(mem_wdata_i),
				  
				  //送到mem/wb段的信息
				  .mem_weno(mem_wreg_eno), .mem_waddro(mem_waddro), .mem_datao(mem_wdata_o),
				  
				  //乘法相关
				  .mem_hilo_wen(mem_hilo_we_o), .mem_hi_i(mem_hi_o), .mem_lo_i(mem_lo_o),
				  .mem_hilo_wen_o(mem_wb_hilo_we_o), .mem_hi_o(mem_wb_hi_o), .mem_lo_o(mem_wb_lo_o),
				  
				  //lw、sw相关
				  .aluop_i(mem_aluop_o),
				  .mem_addr_i(mem_addr_o),
				  .reg2_i(mem_reg2),
				  .mem_data_i(data_rom_o),
				  .mem_addr_o(mem_addro),
				  .mem_we_o(mem_we_o),
				  .mem_data_o(mem_data_o),
				  .mem_ce_o(mem_ce_o)
				  );
		//mem/wb模块实例化
		mem_wb mem_wb0(
					.clk(clk),
					.rst(rst),
					.mem_stall(mem_stall), .wb_stall(wb_stall),
					//来自mem段的信息
					.mem_wen(mem_wreg_eno), .mem_waddr(mem_waddro), .mem_wdata(mem_wdata_o),
					
					//输出到wb段的信息
					.wb_wen(wb_wreg_eni), .wb_waddr(wb_waddri), .wb_wdata(wb_wdata_i),
					
					//乘法相关的操作
					.mem_hilo_wen(mem_wb_hilo_we_o), .mem_hi_i(mem_wb_hi_o), .mem_lo_i(mem_wb_lo_o),
					.wb_hilo_wen(wb_hilo_we_o), .wb_hi_o(wb_hi_o), .wb_lo_o(wb_lo_o)
						  );
		//将stall_control模块实例化
		stall_control sc(
					.rst(rst),
					.stall_req_id(stall_req_id), .stall_req_ex(stall_req_ex),
					.pc_stall(pc_stall), .if_stall(if_stall),
					.id_stall(id_stall), .ex_stall(ex_stall),
					.mem_stall(mem_stall), .wb_stall(wb_stall)
							 );
		//将hilo寄存器实例化
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
