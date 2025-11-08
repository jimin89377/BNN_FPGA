`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/07/2025 10:34:45 AM
// Design Name: 
// Module Name: bnn
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module bnn_core #(
    // A_i: 28x28x3, W_i: 3x3x3, 
    // CHANNEL: 3, STRIDE: 2
    parameter  STRIDE = 1,
    parameter  IN_CHANNEL = 3,
    parameter  OUT_CHANNEL = 3,
    parameter  WEGT_WIDTH = 3,
    parameter  IN_DATA_WIDTH = 28,
    
    parameter  IN_DATA_1CH = IN_DATA_WIDTH ** 2,
    parameter  IN_DATA_SIZE = IN_DATA_1CH * IN_CHANNEL,
    
    parameter  WEGT_1CH = WEGT_WIDTH ** 2,
    parameter  WEGT_SIZE = WEGT_1CH * IN_CHANNEL,
    parameter  WEGTS_SIZE = OUT_CHANNEL * WEGT_SIZE,
    
    parameter  OUT_DATA_WIDTH = (IN_DATA_WIDTH - WEGT_WIDTH) / STRIDE +1,
    parameter  OUT_DATA_1CH = OUT_DATA_WIDTH ** 2,
    parameter  OUT_DATA_SIZE = OUT_CHANNEL * OUT_DATA_1CH,
    
    parameter  NUM_BUF = WEGT_WIDTH * IN_CHANNEL,
    
    parameter CORE_DELAY = 5
)(
	input	wire	                    clk,
	input	wire	                    reset_n,
	
    input   wire [WEGT_SIZE -1: 0]      i_weight,      //  weight
    input   wire [IN_DATA_WIDTH -1:0]   i_data,        //  input data
    input   wire                        i_valid,
    input   wire [CORE_DELAY - 1 : 0]   i_calc_valid,
    
	output  reg                         o_valid,
	output  reg  [OUT_DATA_WIDTH -1: 0] o_result       //  output data
    );
//-------------------------------------------------------------

reg [1 : 0] core_channel_cnt;
always @(posedge clk or negedge reset_n) begin
    if(!reset_n) begin
        core_channel_cnt <= 0;
    end
    else if(i_valid) begin
        if(core_channel_cnt == 2) begin
            core_channel_cnt <= 0;
        end
        else begin
            core_channel_cnt <= core_channel_cnt + 1;
        end
    end
    else begin
        core_channel_cnt <= 0;
    end
end

integer i, j;
reg [IN_DATA_WIDTH - 1 : 0] r_input_mem_data [NUM_BUF - 1 : 0];
always @(posedge clk or negedge reset_n) begin
	if(!reset_n) begin
		for(i = 0; i < NUM_BUF; i = i + 1) begin
			r_input_mem_data[i] <= {IN_DATA_WIDTH{1'b0}};
		end
	end
	else if(i_valid && core_channel_cnt == 0) begin		// timing check
		for(i = 0; i < IN_CHANNEL; i = i + 1) begin
			r_input_mem_data[i * WEGT_WIDTH] 	    <= r_input_mem_data[i * WEGT_WIDTH + 1];
			r_input_mem_data[i * WEGT_WIDTH + 1] 	<= r_input_mem_data[i * WEGT_WIDTH + 2];
		end
		r_input_mem_data[2] <= i_data;
		r_input_mem_data[5] <= 0;
		r_input_mem_data[8] <= 0;
	end
	else if(i_valid) begin
		r_input_mem_data[core_channel_cnt * WEGT_WIDTH + 2] <= i_data;
	end
end
// line_buf 0~8 CH0(0, 1, 2), CH1(3, 4, 5), CH2(6, 7, 8) index 클 수록 row+

reg [WEGT_SIZE - 1 : 0] r_weight;
always @(posedge clk or negedge reset_n) begin
    if(!reset_n) begin
        r_weight <= {WEGT_SIZE{1'b0}};
    end
    else if(i_valid) begin
        r_weight <= i_weight;
    end
end

wire [WEGT_SIZE - 1 : 0] sliced_input [OUT_DATA_WIDTH - 1 : 0];
genvar a,b,c;
generate
	for(a = 0; a < OUT_DATA_WIDTH; a = a + 1) begin
		for(b = 0; b < IN_CHANNEL; b = b + 1) begin
			for(c = 0; c < WEGT_WIDTH; c = c + 1) begin
				assign sliced_input[a][(WEGT_SIZE - 1) - b * WEGT_1CH - c * WEGT_WIDTH -: WEGT_WIDTH] 
				= r_input_mem_data[b * WEGT_WIDTH + c][(IN_DATA_WIDTH - 1) - a -: WEGT_WIDTH];
			end
		end
	end
endgenerate

reg [WEGT_SIZE - 1 : 0 ] r_sliced_input [OUT_DATA_WIDTH - 1 : 0];
always @(posedge clk or negedge reset_n) begin
	if(!reset_n) begin
		for(i = 0; i < OUT_DATA_WIDTH; i = i + 1) begin
			r_sliced_input[i] <= {WEGT_SIZE{1'b0}};
		end
	end
	else if(i_calc_valid[1]) begin
		for(i = 0; i < OUT_DATA_WIDTH; i = i + 1) begin
			r_sliced_input[i] <= sliced_input[i];
		end
	end
end

wire [WEGT_SIZE - 1 : 0] xnor_result [OUT_DATA_WIDTH - 1 : 0];
genvar d;
generate
	for(d = 0; d < OUT_DATA_WIDTH; d = d + 1) begin
		assign xnor_result[d] = ~ (r_sliced_input[d] ^ r_weight);
	end
endgenerate

reg [WEGT_SIZE - 1 : 0] r_xnor_result [OUT_DATA_WIDTH - 1 : 0];
always @(posedge clk or negedge reset_n) begin
	if(!reset_n) begin
		for(i = 0; i < OUT_DATA_WIDTH; i = i + 1) begin
			r_xnor_result[i] <= {WEGT_SIZE{1'b0}};
		end
	end
	else if(i_calc_valid[2]) begin
		for(i = 0; i < OUT_DATA_WIDTH; i = i + 1) begin
			r_xnor_result[i] <= xnor_result[i];
		end
	end
end

reg [4 : 0] popcnt_result [OUT_DATA_WIDTH - 1 : 0];
always @(*) begin
	for(i = 0; i < OUT_DATA_WIDTH; i = i + 1) begin
		popcnt_result[i] = 0;
		for(j = 0; j < WEGT_SIZE; j = j + 1) begin
			popcnt_result[i] = popcnt_result[i] + r_xnor_result[i][j];
		end
	end
end

reg [4 : 0] r_popcnt_result [OUT_DATA_WIDTH - 1 : 0];
always @(posedge clk or negedge reset_n) begin
	if(!reset_n) begin
		for(i = 0; i < OUT_DATA_WIDTH; i = i + 1) begin
			r_popcnt_result[i] <= {WEGT_SIZE{1'b0}};
		end
	end
	else if(i_calc_valid[3]) begin
		for(i = 0; i < OUT_DATA_WIDTH; i = i + 1) begin
			r_popcnt_result[i] <= popcnt_result[i];
		end
	end
end

wire [OUT_DATA_WIDTH - 1 : 0] result;
genvar e;
generate
	for(e = 0; e < OUT_DATA_WIDTH; e = e + 1) begin
		assign result[(OUT_DATA_WIDTH - 1) - e] = (r_popcnt_result[e] << 1) > WEGT_SIZE ? 1 : 0;
	end
endgenerate

always @(posedge clk or negedge reset_n) begin
	if(!reset_n) begin
		o_result <= {WEGT_SIZE{1'b0}};
	end
	else if(i_calc_valid[4]) begin
		o_result <= result;
	end
end

//assign o_valid = (i_calc_valid[4] == 1);
always @(posedge clk or negedge reset_n) begin
    if(!reset_n) begin
        o_valid <= 0;
    end
    else begin
        o_valid <= i_calc_valid[4];
    end
end

endmodule
