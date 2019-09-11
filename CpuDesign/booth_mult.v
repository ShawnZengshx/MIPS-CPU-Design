`timescale 1ns / 1ps

`include "defines.v"
module booth_mult(
		input wire clk,
		input wire rst,
		input wire[`RegBus] mult_op1,    //booth被乘数
		input wire[`RegBus] mult_op2,    //booth乘数
		input wire start,        //表示是否需要进行booth算法
		
		output reg is_done,     //表示算法已完成
		output reg[63:0] result   //输出计算结果
    ); 
		reg[5:0] index_i;
		reg[32:0] z;		//结果
		reg[32:0] x;		//被乘数
		reg[32:0] x_comp;
		reg[32:0] y;		//乘数
		reg finished;
		reg[1:0] current_state, next_state;
		wire[63:0] temp;
		reg[32:0] op1_opposite;    //op1的相反数
		parameter init = 1, ready = 2, acc = 3, done = 4;
		
		always@(posedge clk or negedge start) begin
			if(rst == `RstEnable) begin
				current_state <= init;
				is_done <= 1'b0;
			end else if(start == 1'b0) begin
				current_state <= init;				//初始阶段
			end else begin
				current_state <= next_state; 
			end
		end
		
		always@(current_state or index_i) begin
			case(current_state)				
				init: begin
					next_state = ready;				//准备阶段
				end
				ready: begin
					next_state = acc;					//计算阶段
				end
				acc: begin
					if(index_i == 6'h1f) begin			//表示已经完成31次移位操作
						next_state = done;
					end
				end
			 endcase
		end
		
		always@(current_state or index_i) begin
			case(current_state)
				init: begin
					finished = 0;
				end
				ready: begin
					x = (mult_op1[31] == 1'b1) ?
						 {mult_op1[31],mult_op1[31], ~mult_op1[30:0]} + 1 : {mult_op1[31], mult_op1[31:0]};			//采用双符号位取补码
					op1_opposite = {~mult_op1[31], ~mult_op1[31], mult_op1[30:0]};
					x_comp = (op1_opposite[32] == 1'b1) ?
								{op1_opposite[32], op1_opposite[32], ~op1_opposite[30:0]} + 1 : op1_opposite;//~{mult_op1[31], mult_op1[31:0]} + 1;   //取相反数的补码
					y[32:0] = (mult_op2[31] == 1'b1) ?
						 {{{mult_op2[31], ~mult_op2[30:0]} + 1}, 1'b0 } : {mult_op2[31:0], 1'b0};	
					z = 0;
				end
				acc: begin
					case(y[1:0])
						2'b01: begin		//如果是01
							z = z + x;
							{z[32:0], y[32:0]} = {z[32], z[32:0], y[32:1]}; //结果和剩余乘数左移1位
						end
						2'b10: begin		//如果是10
							z = z + x_comp;
							{z[32:0], y[32:0]} = {z[32], z[32:0], y[32:1]};
						end
						default: begin     //如果是00或11
							{z[32:0], y[32:0]} = {z[32], z[32:0], y[32:1]}; //直接左移
						end
					endcase
				end
				default: begin
					finished = 1;
				end
			endcase
		end

		always@(posedge clk)begin
			if(current_state == acc)begin
				index_i <= index_i + 1'b1;
			end else begin 
				index_i <= 0;
			end
			is_done <= finished;
		end

		assign temp = {z[31:0], y[32:1]};

		always@(posedge is_done) begin
			result <= (temp[63] == 1'b1) ? 
						 {temp[63], ~temp[62:0]} + 1 : temp;
		end


endmodule
