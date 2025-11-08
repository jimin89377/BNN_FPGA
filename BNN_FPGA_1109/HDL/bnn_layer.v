//////////////////////////////////////////////////////////////////////////////////
// Company: Personal
// Engineer: Matbi / Austin
//
// Create Date: 2021.01.31
// Design Name: 
// Module Name: data_mover_bram
// Project Name:
// Target Devices:
// Tool Versions:
// Description: To study ctrl sram. (WRITE / READ)
//				FSM + mem I/F
// Dependencies:
//
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////
 
`timescale 1ns / 1ps
module bnn_layer
// Param
#(
	parameter CNT_BIT = 31,
// BRAM
	parameter IN_MEM_DWIDTH = 28,
	parameter IN_MEM_AWIDTH = 7,
	parameter IN_MEM_DEPTH  = 84,
	
	parameter WEGT_MEM_DWIDTH = 27,
	parameter WEGT_MEM_AWIDTH = 2,
	parameter WEGT_MEM_DEPTH  = 3,
	
	parameter OUT_MEM_DWIDTH = 26,
	parameter OUT_MEM_AWIDTH = 5,
	parameter OUT_MEM_DEPTH  = 78,
	
	//------------------------------------------------------------
    parameter  STRIDE = 1,
    parameter  IN_CHANNEL = 3,
    parameter  OUT_CHANNEL = 3,
    parameter  WEGT_WIDTH = 3,
    parameter  IN_DATA_WIDTH = 28,
    
    parameter  IN_DATA_1CH = IN_DATA_WIDTH ** 2,
    parameter  IN_DATA_SIZE = IN_DATA_1CH * IN_CHANNEL, // 2352
    
    parameter  WEGT_1CH = WEGT_WIDTH ** 2,
    parameter  WEGT_SIZE = WEGT_1CH * IN_CHANNEL,
    parameter  WEGTS_SIZE = OUT_CHANNEL * WEGT_SIZE,
    
    parameter  OUT_DATA_WIDTH = (IN_DATA_WIDTH - WEGT_WIDTH) / STRIDE +1,
    parameter  OUT_DATA_1CH = OUT_DATA_WIDTH ** 2,
    parameter  OUT_DATA_SIZE = OUT_CHANNEL * OUT_DATA_1CH,
    
    parameter  NUM_BUF = WEGT_WIDTH * IN_CHANNEL,
    parameter  STATE_WIDTH = 3,
    
    parameter  CORE_DELAY = 5
)

(
    input 				        clk,
    input 				        reset_n,
	input 				        i_run,
	input  [CNT_BIT-1:0]	    i_num_cnt,
	output   			        o_idle,
	output   			        o_read,
	output                      o_write,
	output  			        o_done,

// Memory I/F
// read from input node
	output[IN_MEM_AWIDTH-1:0] 	addr_input,
	output 				        ce_input,
	output 				        we_input,
	input [IN_MEM_DWIDTH-1:0]   q_input,
	output[IN_MEM_DWIDTH-1:0] 	d_input,

// read from weight
	output[WEGT_MEM_AWIDTH-1:0] addr_weight,
	output 				        ce_weight,
	output 				        we_weight,
	input [WEGT_MEM_DWIDTH-1:0] q_weight,
	output[WEGT_MEM_DWIDTH-1:0] d_weight,
	
// write output
    output[OUT_MEM_AWIDTH-1:0] 	addr_output,
	output 				        ce_output,
	output 				        we_output,
	input [OUT_MEM_DWIDTH-1:0]  q_output,
	output[OUT_MEM_DWIDTH-1:0] 	d_output
    );

/////// Local Param. to define state ////////
localparam S_IDLE	= 2'b00;
localparam S_RUN	= 2'b01;
localparam S_DONE  	= 2'b10;

/////// Type ////////
reg [1:0] c_state_read; // Current state  (F/F)
reg [1:0] n_state_read; // Next state (Variable in Combinational Logic)
reg [1:0] c_state_write; // Current state  (F/F)
reg [1:0] n_state_write; // Next state (Variable in Combinational Logic)

wire      is_write_start;
wire	  is_write_done;
wire	  is_read_done;

/////// Main ////////
// Step 1. always block to update state 
always @(posedge clk or negedge reset_n) begin
    if(!reset_n) begin
		c_state_read <= S_IDLE;
    end else begin
		c_state_read <= n_state_read;
    end
end

always @(posedge clk or negedge reset_n) begin
    if(!reset_n) begin
		c_state_write <= S_IDLE;
    end else begin
		c_state_write <= n_state_write;
    end
end

// Step 2. always block to compute n_state_read
always @(*) 
begin
	n_state_read = c_state_read; // To prevent Latch.
	case(c_state_read)
	S_IDLE	: if(i_run)
				n_state_read = S_RUN;
	S_RUN   : if(is_read_done)
				n_state_read = S_DONE;
	S_DONE	: n_state_read 	 = S_IDLE;
	endcase
end 

always @(*) 
begin
	n_state_write = c_state_write; // To prevent Latch.
	case(c_state_write)
	S_IDLE	: if(is_write_start)
				n_state_write = S_RUN;
	S_RUN   : if(is_write_done)
				n_state_write = S_DONE;
	S_DONE	: n_state_write   = S_IDLE;
	endcase
end 

assign o_idle 		= (c_state_read == S_IDLE) && (c_state_write == S_IDLE);
assign o_read 		= (c_state_read == S_RUN);
assign o_write 		= (c_state_write == S_RUN);
assign o_done 		= (c_state_write == S_DONE); // The write state is slower than the read state.

// Step 4. Registering (Capture) number of Count
reg [CNT_BIT-1:0] num_cnt;
reg [3:0] o_write_cnt;
 
always @(posedge clk or negedge reset_n) begin
    if(!reset_n) begin
        num_cnt <= 0;  
    end else if (i_run) begin
        num_cnt <= i_num_cnt;
	end else if (o_done) begin
		num_cnt <= 0;
	end
end
//--add----------------------------------------------------------------------

reg [1:0] in_channel_cnt;
always @(posedge clk or negedge reset_n) begin	// CH0, CH1, CH2 roop
	if(!reset_n) begin
		in_channel_cnt <= 1;
	end
	else if(in_channel_cnt >= 2) begin
		in_channel_cnt <= 0;
	end
	else if(o_read) begin
		in_channel_cnt <= in_channel_cnt + 1;
	end
end

reg [2 : 0] out_channel_cnt;
always @(posedge clk or negedge reset_n) begin
	if(!reset_n) begin
		out_channel_cnt <= 0;
	end
	else if(out_channel_end) begin
		out_channel_cnt <= out_channel_cnt + 1;
	end
	else if(out_channel_cnt == OUT_CHANNEL) begin
		out_channel_cnt <= 0;
	end
end

reg [IN_DATA_WIDTH - 1 : 0] row_cnt;
always @(posedge clk or negedge reset_n) begin	//
	if(!reset_n) begin
		row_cnt <= 0;
	end
	else if(row_cnt >= IN_DATA_WIDTH) begin
		row_cnt <= 0;
	end
	else if(o_read && in_channel_cnt == 2) begin
		row_cnt <= row_cnt + 1;
	end
end

reg [CORE_DELAY - 1 : 0] r_calc_valid;
always @(posedge clk or negedge reset_n) begin
	if(!reset_n) begin
		r_calc_valid <= {CORE_DELAY{1'b0}};
	end
	else begin
		r_calc_valid <= {r_calc_valid[CORE_DELAY - 2 : 0],{calc_valid}};
	end
end
//-----------------------------------------------------------------------------------
// Step 5. increased addr_cnt
reg [CNT_BIT-1:0] addr_cnt_read_input;
reg [CNT_BIT-1:0] addr_cnt_read_weight; 
reg [CNT_BIT-1:0] addr_cnt_write;

assign is_read_done  = o_read  && (out_channel_cnt == OUT_CHANNEL - 1) && out_channel_end ;
assign is_write_done = o_write && (addr_cnt_write == OUT_MEM_DEPTH - 1) && (|r_calc_valid == 0);

assign calc_valid	= o_read && (in_channel_cnt == 0) && (row_cnt > 2);
assign out_channel_end = (addr_cnt_read_input == IN_MEM_DEPTH - 1); 
assign wegt_read    = o_read && (out_channel_cnt > 0) && (in_channel_cnt == 0) &&(row_cnt == 2);

always @(posedge clk or negedge reset_n) begin
    if(!reset_n) begin
        addr_cnt_read_input <= 0;  
    end else if (is_read_done | out_channel_end) begin
        addr_cnt_read_input <= 0; 
    end else if (o_read) begin
        addr_cnt_read_input <= IN_DATA_WIDTH * in_channel_cnt + row_cnt;
	end
end

always @(posedge clk or negedge reset_n) begin
    if(!reset_n) begin
        addr_cnt_read_weight <= 0;  
    end else if (is_read_done) begin
        addr_cnt_read_weight <= 0; 
    end else if (wegt_read) begin
        addr_cnt_read_weight <= addr_cnt_read_weight + 1;
	end
end

always @(posedge clk or negedge reset_n) begin
    if(!reset_n) begin
        addr_cnt_write <= 0;  
    end else if (is_write_done) begin
        addr_cnt_write <= 0; 
    end else if (o_write && result_valid ) begin
        addr_cnt_write <= addr_cnt_write + 1;
	end
end

reg  r_valid;
// 1 cycle latency to sync mem output
always @(posedge clk or negedge reset_n) begin
    if(!reset_n) begin
        r_valid <= {IN_MEM_DWIDTH{1'b0}};  
    end else begin
	    r_valid <= o_read; // read data
    end
end

// Assign Memory I/F. Read from BRAM input
assign addr_input 	= addr_cnt_read_input;
assign ce_input 	= o_read;
assign we_input 	= 1'b0; // read only
assign d_input		= {IN_MEM_DWIDTH{1'b0}}; // no use

wire [IN_MEM_DWIDTH - 1 : 0]    input_mem_data;
assign input_mem_data = q_input;


// Assign Memory I/F. Read from BRAM weight
assign addr_weight 	= addr_cnt_read_weight;
assign ce_weight 	= o_read;   //o_read && (addr_cnt_read_input == 0)
assign we_weight 	= 1'b0; // read only
assign d_weight		= {IN_MEM_DWIDTH{1'b0}}; // no use

wire [WEGT_MEM_DWIDTH - 1:0] 	weight_mem_data;
assign weight_mem_data = q_weight; 

//----------------------------------------------------------------------------------

wire [OUT_MEM_DWIDTH-1:0] w_result;

bnn_core #(
.WEGT_WIDTH     (WEGT_WIDTH),
.IN_DATA_WIDTH  (IN_DATA_WIDTH),
.STRIDE         (STRIDE),
.IN_CHANNEL     (IN_CHANNEL),
.OUT_CHANNEL    (OUT_CHANNEL)
) u_bnn_core (
.clk            (clk),
.reset_n        (reset_n),

.i_weight       (weight_mem_data),
.i_data         (input_mem_data),
.i_valid	    (r_valid),
.i_calc_valid   (r_calc_valid),

.o_valid        (result_valid),
.o_result       (w_result)
);


assign is_write_start = r_calc_valid[4];

// core result to output_Bram

//// Step 8. Write Data to BRAM1
assign addr_output 	= addr_cnt_write;
assign ce_output 	= o_write && result_valid;
assign we_output 	= o_write;
assign d_output		= w_result;

assign q_output = 0; // no use

endmodule
