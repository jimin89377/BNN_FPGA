//////////////////////////////////////////////////////////////////////////////////
// Company: Personal
// Engineer: Jimin
//
// Create Date:
// Design Name: bnn_top
// Module Name: bnn_top
// Project Name:
// Target Devices:
// Tool Versions:
// Description: Data Mover BRAM
//				
// Dependencies:
//
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////


module multi_bnn_layer#
(
	// (lab10) Users to add parameters here
	parameter CNT_BIT = 31,

	// 
	parameter integer MEM0_DATA_WIDTH = 28,
	parameter integer MEM0_ADDR_WIDTH = 7,
	parameter integer MEM0_MEM_DEPTH  = 84,

	// 
	parameter integer MEM1_DATA_WIDTH = 27,
	parameter integer MEM1_ADDR_WIDTH = 2,
	parameter integer MEM1_MEM_DEPTH  = 3,
	
	// 
	parameter integer MEM2_DATA_WIDTH = 26,
	parameter integer MEM2_ADDR_WIDTH = 7,
	parameter integer MEM2_MEM_DEPTH  = 78,
	
	// 
	parameter integer MEM3_DATA_WIDTH = 27,
	parameter integer MEM3_ADDR_WIDTH = 3,
	parameter integer MEM3_MEM_DEPTH  = 5,
	
	// 
	parameter integer MEM4_DATA_WIDTH = 24,
	parameter integer MEM4_ADDR_WIDTH = 7,
	parameter integer MEM4_MEM_DEPTH  = 120,

    // BNN L1
    parameter  STRIDE_0 = 1,
    parameter  IN_CHANNEL_0 = 3,
    parameter  OUT_CHANNEL_0 = 3,
    parameter  WEGT_WIDTH_0 = 3,
    parameter  IN_DATA_WIDTH_0 = 28,
    
    parameter  IN_DATA_1CH_0 = IN_DATA_WIDTH_0 ** 2,
    parameter  IN_DATA_SIZE_0 = IN_DATA_1CH_0 * IN_CHANNEL_0,
    
    parameter  WEGT_1CH_0 = WEGT_WIDTH_0 ** 2,
    parameter  WEGT_SIZE_0 = WEGT_1CH_0 * IN_CHANNEL_0,
    parameter  WEGTS_SIZE_0 = OUT_CHANNEL_0 * WEGT_SIZE_0,
    
    parameter  OUT_DATA_WIDTH_0 = (IN_DATA_WIDTH_0 - WEGT_WIDTH_0) / STRIDE_0 +1,
    parameter  OUT_DATA_1CH_0 = OUT_DATA_WIDTH_0 ** 2,
    parameter  OUT_DATA_SIZE_0 = OUT_CHANNEL_0 * OUT_DATA_1CH_0,
    
    // BNN L2
    parameter  STRIDE_1 = 1,
    parameter  IN_CHANNEL_1 = 3,
    parameter  OUT_CHANNEL_1 = 3,
    parameter  WEGT_WIDTH_1 = 3,
    parameter  IN_DATA_WIDTH_1 = 26,
    
    parameter  IN_DATA_1CH_1 = IN_DATA_WIDTH_1 ** 2,
    parameter  IN_DATA_SIZE_1 = IN_DATA_1CH_1 * IN_CHANNEL_1,
    
    parameter  WEGT_1CH_1 = WEGT_WIDTH_1 ** 2,
    parameter  WEGT_SIZE_1 = WEGT_1CH_1 * IN_CHANNEL_1,
    parameter  WEGTS_SIZE_1 = OUT_CHANNEL_1 * WEGT_SIZE_1,
    
    parameter  OUT_DATA_WIDTH_1 = (IN_DATA_WIDTH_1 - WEGT_WIDTH_1) / STRIDE_1 +1,
    parameter  OUT_DATA_1CH_1 = OUT_DATA_WIDTH_1 ** 2,
    parameter  OUT_DATA_SIZE_1 = OUT_CHANNEL_1 * OUT_DATA_1CH_1,
	// User parameters ends
	// Do not modify the parameters beyond this line
	
	// Parameters of Axi Slave Bus Interface S00_AXI
	parameter integer C_S00_AXI_DATA_WIDTH	= 32,
	parameter integer C_S00_AXI_ADDR_WIDTH	= 6 // (lab16) used #16 reg
)
(
	// Users to add ports here

	// User ports ends
	// Do not modify the ports beyond this line


	// Ports of Axi Slave Bus Interface S00_AXI
	input wire  s00_axi_aclk,
	input wire  s00_axi_aresetn,
	input wire [C_S00_AXI_ADDR_WIDTH-1 : 0] s00_axi_awaddr,
	input wire [2 : 0] s00_axi_awprot,
	input wire  s00_axi_awvalid,
	output wire  s00_axi_awready,
	input wire [C_S00_AXI_DATA_WIDTH-1 : 0] s00_axi_wdata,
	input wire [(C_S00_AXI_DATA_WIDTH/8)-1 : 0] s00_axi_wstrb,
	input wire  s00_axi_wvalid,
	output wire  s00_axi_wready,
	output wire [1 : 0] s00_axi_bresp,
	output wire  s00_axi_bvalid,
	input wire  s00_axi_bready,
	input wire [C_S00_AXI_ADDR_WIDTH-1 : 0] s00_axi_araddr,
	input wire [2 : 0] s00_axi_arprot,
	input wire  s00_axi_arvalid,
	output wire  s00_axi_arready,
	output wire [C_S00_AXI_DATA_WIDTH-1 : 0] s00_axi_rdata,
	output wire [1 : 0] s00_axi_rresp,
	output wire  s00_axi_rvalid,
	input wire  s00_axi_rready
);

    // bnn_layer_0
	wire  				w_run_0;
	wire [CNT_BIT-1:0]	w_num_cnt_0;
	wire   				w_idle_0;
	wire   				w_running_0;
	wire    			w_done_0;

	wire				w_read_0;
	wire				w_write_0;
    assign w_running_0 = w_read_0 | w_write_0;
    
    // bnn_layer_1
	wire  				w_run_1;
	wire [CNT_BIT-1:0]	w_num_cnt_1;
	wire   				w_idle_1;
	wire   				w_running_1;
	wire    			w_done_1;

	wire				w_read_1;
	wire				w_write_1;
    assign w_running_1 = w_read_1 | w_write_1;


// Memory I/F BRMA0~4 (Port0, Port1)
	//
	wire		[MEM0_ADDR_WIDTH-1:0] 	mem0_addr1	;  // BRAM0
	wire		 						mem0_ce1	;
	wire		 						mem0_we1	;
	wire		[MEM0_DATA_WIDTH-1:0]  	mem0_q1		;
	wire		[MEM0_DATA_WIDTH-1:0] 	mem0_d1		;

	wire		[MEM1_ADDR_WIDTH-1:0] 	mem1_addr1	;  // BRAM1
	wire		 						mem1_ce1	;
	wire		 						mem1_we1	;
	wire		[MEM1_DATA_WIDTH-1:0]  	mem1_q1		;
	wire		[MEM1_DATA_WIDTH-1:0] 	mem1_d1		;
	
	wire		[MEM2_ADDR_WIDTH-1:0] 	mem2_addr1	;  // BRAM2
	wire		 						mem2_ce1	;
	wire		 						mem2_we1	;
	wire		[MEM2_DATA_WIDTH-1:0]  	mem2_q1		;
	wire		[MEM2_DATA_WIDTH-1:0] 	mem2_d1		;
	
	wire		[MEM3_ADDR_WIDTH-1:0] 	mem3_addr1	;  // BRAM3
	wire		 						mem3_ce1	;
	wire		 						mem3_we1	;
	wire		[MEM3_DATA_WIDTH-1:0]  	mem3_q1		;
	wire		[MEM3_DATA_WIDTH-1:0] 	mem3_d1		;
	
	wire		[MEM4_ADDR_WIDTH-1:0] 	mem4_addr1	;  // BRAM4
	wire		 						mem4_ce1	;
	wire		 						mem4_we1	;
	wire		[MEM4_DATA_WIDTH-1:0]  	mem4_q1		;
	wire		[MEM4_DATA_WIDTH-1:0] 	mem4_d1		;

	// Core Side
	wire		[MEM0_ADDR_WIDTH-1:0] 	mem0_addr0	;  // BRAM0
	wire		 						mem0_ce0	;
	wire		 						mem0_we0	;
	wire		[MEM0_DATA_WIDTH-1:0]  	mem0_q0		;
	wire		[MEM0_DATA_WIDTH-1:0] 	mem0_d0		;

	wire		[MEM1_ADDR_WIDTH-1:0] 	mem1_addr0	;  // BRAM1
	wire		 						mem1_ce0	;
	wire		 						mem1_we0	;
	wire		[MEM1_DATA_WIDTH-1:0]  	mem1_q0		;
	wire		[MEM1_DATA_WIDTH-1:0] 	mem1_d0		;
	
	wire		[MEM2_ADDR_WIDTH-1:0] 	mem2_addr0	;  // BRAM2
	wire		 						mem2_ce0	;
	wire		 						mem2_we0	;
	wire		[MEM2_DATA_WIDTH-1:0]  	mem2_q0		;
	wire		[MEM2_DATA_WIDTH-1:0] 	mem2_d0		;
	
	wire		[MEM3_ADDR_WIDTH-1:0] 	mem3_addr0	;  // BRAM3
	wire		 						mem3_ce0	;
	wire		 						mem3_we0	;
	wire		[MEM3_DATA_WIDTH-1:0]  	mem3_q0		;
	wire		[MEM3_DATA_WIDTH-1:0] 	mem3_d0		;
	
	wire		[MEM4_ADDR_WIDTH-1:0] 	mem4_addr0	;  // BRAM4
	wire		 						mem4_ce0	;
	wire		 						mem4_we0	;
	wire		[MEM4_DATA_WIDTH-1:0]  	mem4_q0		;
	wire		[MEM4_DATA_WIDTH-1:0] 	mem4_d0		;


// Instantiation of Axi Bus Interface S00_AXI
	myip_v1_0 # ( 
		.CNT_BIT(CNT_BIT),
		
		.MEM0_DATA_WIDTH	(MEM0_DATA_WIDTH	),
		.MEM0_ADDR_WIDTH	(MEM0_ADDR_WIDTH	),
		.MEM0_MEM_DEPTH 	(MEM0_MEM_DEPTH 	),

		.MEM1_DATA_WIDTH	(MEM1_DATA_WIDTH	),
		.MEM1_ADDR_WIDTH	(MEM1_ADDR_WIDTH	),
		.MEM1_MEM_DEPTH 	(MEM1_MEM_DEPTH 	),

		.MEM2_DATA_WIDTH	(MEM2_DATA_WIDTH	),
		.MEM2_ADDR_WIDTH	(MEM2_ADDR_WIDTH	),
		.MEM2_MEM_DEPTH 	(MEM2_MEM_DEPTH 	),
				
		.MEM3_DATA_WIDTH	(MEM3_DATA_WIDTH	),
		.MEM3_ADDR_WIDTH	(MEM3_ADDR_WIDTH	),
		.MEM3_MEM_DEPTH 	(MEM3_MEM_DEPTH 	),
		
		.MEM4_DATA_WIDTH	(MEM4_DATA_WIDTH	),
		.MEM4_ADDR_WIDTH	(MEM4_ADDR_WIDTH	),
		.MEM4_MEM_DEPTH 	(MEM4_MEM_DEPTH 	),
		
		.C_S00_AXI_DATA_WIDTH(C_S00_AXI_DATA_WIDTH),
		.C_S00_AXI_ADDR_WIDTH(C_S00_AXI_ADDR_WIDTH)
	) myip_v1_0_inst (
		// (lab10) Users to add ports here
		.o_run_0		(w_run_0),
		.o_num_cnt_0	(w_num_cnt_0),
		.i_idle_0		(w_idle_0),
		.i_running_0	(w_running_0),
		.i_done_0		(w_done_0),
		
		.o_run_1		(w_run_1),
		.o_num_cnt_1	(w_num_cnt_1),
		.i_idle_1		(w_idle_1),
		.i_running_1	(w_running_1),
		.i_done_1		(w_done_1),

		.mem0_addr1			(mem0_addr1	),
		.mem0_ce1			(mem0_ce1	),
		.mem0_we1			(mem0_we1	),
		.mem0_q1			(mem0_q1	),
		.mem0_d1			(mem0_d1	),

		.mem1_addr1			(mem1_addr1	),
		.mem1_ce1			(mem1_ce1	),
		.mem1_we1			(mem1_we1	),
		.mem1_q1			(mem1_q1	),
		.mem1_d1			(mem1_d1	),
		
		.mem3_addr1			(mem3_addr1	),
		.mem3_ce1			(mem3_ce1	),
		.mem3_we1			(mem3_we1	),
		.mem3_q1			(mem3_q1	),
		.mem3_d1			(mem3_d1	),
		
		.mem4_addr0			(mem4_addr0	),
		.mem4_ce0			(mem4_ce0	),
		.mem4_we0			(mem4_we0	),
		.mem4_q0			(mem4_q0	),
		.mem4_d0			(mem4_d0	),

		.s00_axi_aclk	(s00_axi_aclk	),
		.s00_axi_aresetn(s00_axi_aresetn),
		.s00_axi_awaddr	(s00_axi_awaddr	),
		.s00_axi_awprot	(s00_axi_awprot	),
		.s00_axi_awvalid(s00_axi_awvalid),
		.s00_axi_awready(s00_axi_awready),
		.s00_axi_wdata	(s00_axi_wdata	),
		.s00_axi_wstrb	(s00_axi_wstrb	),
		.s00_axi_wvalid	(s00_axi_wvalid	),
		.s00_axi_wready	(s00_axi_wready	),
		.s00_axi_bresp	(s00_axi_bresp	),
		.s00_axi_bvalid	(s00_axi_bvalid	),
		.s00_axi_bready	(s00_axi_bready	),
		.s00_axi_araddr	(s00_axi_araddr	),
		.s00_axi_arprot	(s00_axi_arprot	),
		.s00_axi_arvalid(s00_axi_arvalid),
		.s00_axi_arready(s00_axi_arready),
		.s00_axi_rdata	(s00_axi_rdata	),
		.s00_axi_rresp	(s00_axi_rresp	),
		.s00_axi_rvalid	(s00_axi_rvalid	),
		.s00_axi_rready	(s00_axi_rready	)
	);

	bnn_layer # (
		.CNT_BIT(CNT_BIT),
	// BRAM
		.IN_MEM_DWIDTH 	 (MEM0_DATA_WIDTH),
		.IN_MEM_AWIDTH   (MEM0_ADDR_WIDTH),
		.IN_MEM_DEPTH  	 (MEM0_MEM_DEPTH ),
		
		.WEGT_MEM_DWIDTH (MEM1_DATA_WIDTH),
		.WEGT_MEM_AWIDTH (MEM1_ADDR_WIDTH),
		.WEGT_MEM_DEPTH  (MEM1_MEM_DEPTH ),
		
		.OUT_MEM_DWIDTH  (MEM2_DATA_WIDTH),
		.OUT_MEM_AWIDTH  (MEM2_ADDR_WIDTH),
		.OUT_MEM_DEPTH   (MEM2_MEM_DEPTH ),

        .WEGT_WIDTH      (WEGT_WIDTH_0),
        .IN_DATA_WIDTH   (IN_DATA_WIDTH_0),
        .STRIDE          (STRIDE_0),
        .IN_CHANNEL      (IN_CHANNEL_0),
        .OUT_CHANNEL     (OUT_CHANNEL_0)
	) bnn_layer_0(
	    .clk		     (s00_axi_aclk	),
	    .reset_n	     (s00_axi_aresetn),
	    
		.i_run		     (w_run_0		),
		.i_num_cnt	     (w_num_cnt_0	),
		.o_idle		     (w_idle_0		),
		.o_read		     (w_read_0		),
		.o_write	     (w_write_0		),
		.o_done		     (w_done_0		),
	
		.addr_input	     (mem0_addr0	),
		.ce_input		 (mem0_ce0		),
		.we_input		 (mem0_we0		),
		.q_input		 (mem0_q0		),
		.d_input		 (mem0_d0		),
	
		.addr_weight	 (mem1_addr0	),
		.ce_weight		 (mem1_ce0		),
		.we_weight		 (mem1_we0		),
		.q_weight		 (mem1_q0		),
		.d_weight		 (mem1_d0		),
		
		.addr_output	 (mem2_addr1	),
		.ce_output		 (mem2_ce1		),
		.we_output		 (mem2_we1		),
		.q_output		 (mem2_q1		),
		.d_output		 (mem2_d1		)
	);

	bnn_layer # (
		.CNT_BIT(CNT_BIT),
	// BRAM
		.IN_MEM_DWIDTH 	 (MEM2_DATA_WIDTH),
		.IN_MEM_AWIDTH   (MEM2_ADDR_WIDTH),
		.IN_MEM_DEPTH  	 (MEM2_MEM_DEPTH ),
		
		.WEGT_MEM_DWIDTH (MEM3_DATA_WIDTH),
		.WEGT_MEM_AWIDTH (MEM3_ADDR_WIDTH),
		.WEGT_MEM_DEPTH  (MEM3_MEM_DEPTH ),
		
		.OUT_MEM_DWIDTH  (MEM4_DATA_WIDTH),
		.OUT_MEM_AWIDTH  (MEM4_ADDR_WIDTH),
		.OUT_MEM_DEPTH   (MEM4_MEM_DEPTH ),

        .WEGT_WIDTH      (WEGT_WIDTH_1),
        .IN_DATA_WIDTH   (IN_DATA_WIDTH_1),
        .STRIDE          (STRIDE_1),
        .IN_CHANNEL      (IN_CHANNEL_1),
        .OUT_CHANNEL     (OUT_CHANNEL_1)
	) bnn_layer_1(
	    .clk		     (s00_axi_aclk	),
	    .reset_n         (s00_axi_aresetn),
	    
		.i_run		     (w_run_1		),
		.i_num_cnt	     (w_num_cnt_1	),
		.o_idle		     (w_idle_1		),
		.o_read		     (w_read_1		),
		.o_write	     (w_write_1		),
		.o_done		     (w_done_1		),
	
		.addr_input	     (mem2_addr0	),
		.ce_input		 (mem2_ce0		),
		.we_input		 (mem2_we0		),
		.q_input		 (mem2_q0		),
		.d_input		 (mem2_d0		),
	
		.addr_weight	 (mem3_addr0	),
		.ce_weight		 (mem3_ce0		),
		.we_weight		 (mem3_we0		),
		.q_weight		 (mem3_q0		),
		.d_weight		 (mem3_d0		),
		
		.addr_output	 (mem4_addr1	),
		.ce_output		 (mem4_ce1		),
		.we_output		 (mem4_we1		),
		.q_output		 (mem4_q1		),
		.d_output		 (mem4_d1		)
	);
	
	// input_0
	true_sync_dpbram           
	#(	.DWIDTH   (MEM0_DATA_WIDTH), 
		.AWIDTH   (MEM0_ADDR_WIDTH), 
		.MEM_SIZE (MEM0_MEM_DEPTH)) 
	u_bram0(
		.clk		(s00_axi_aclk	), 
	
	// USE Core 
		.addr0		(mem0_addr0		), 
		.ce0		(mem0_ce0		), 
		.we0		(mem0_we0		), 
		.q0			(mem0_q0		), 
		.d0			(mem0_d0		), 
	
	// USE AXI4LITE
		.addr1 		(mem0_addr1 	), 
		.ce1		(mem0_ce1		), 
		.we1		(mem0_we1		),
		.q1			(mem0_q1		), 
		.d1			(mem0_d1		)
	);
	
	// weight_0
	true_sync_dpbram 
	#(	.DWIDTH   (MEM1_DATA_WIDTH), 
		.AWIDTH   (MEM1_ADDR_WIDTH), 
		.MEM_SIZE (MEM1_MEM_DEPTH)) 
	u_bram1(
		.clk		(s00_axi_aclk), 
	
	// USE Core 
		.addr0		(mem1_addr0		), 
		.ce0		(mem1_ce0  		), 
		.we0		(mem1_we0  		), 
		.q0			(mem1_q0   		), 
		.d0			(mem1_d0   		), 
	
	// USE AXI4LITE
		.addr1 		(mem1_addr1 	), 
		.ce1		(mem1_ce1		), 
		.we1		(mem1_we1		),
		.q1			(mem1_q1		), 
		.d1			(mem1_d1		)
	);
	
	// output_0 (input_1)
	true_sync_dpbram 
	#(	.DWIDTH   (MEM2_DATA_WIDTH), 
		.AWIDTH   (MEM2_ADDR_WIDTH), 
		.MEM_SIZE (MEM2_MEM_DEPTH)) 
	u_bram2(
		.clk		(s00_axi_aclk), 
	
	// USE Core 
		.addr0		(mem2_addr0		), 
		.ce0		(mem2_ce0  		), 
		.we0		(mem2_we0  		), 
		.q0			(mem2_q0   		), 
		.d0			(mem2_d0   		), 
	
	// USE AXI4LITE
		.addr1 		(mem2_addr1 	), 
		.ce1		(mem2_ce1		), 
		.we1		(mem2_we1		),
		.q1			(mem2_q1		), 
		.d1			(mem2_d1		)
	);
	
	// weight_1
	true_sync_dpbram 
	#(	.DWIDTH   (MEM3_DATA_WIDTH), 
		.AWIDTH   (MEM3_ADDR_WIDTH), 
		.MEM_SIZE (MEM3_MEM_DEPTH)) 
	u_bram3(
		.clk		(s00_axi_aclk), 
	
	// USE Core 
		.addr0		(mem3_addr0		), 
		.ce0		(mem3_ce0  		), 
		.we0		(mem3_we0  		), 
		.q0			(mem3_q0   		), 
		.d0			(mem3_d0   		), 
	
	// USE AXI4LITE
		.addr1 		(mem3_addr1 	), 
		.ce1		(mem3_ce1		), 
		.we1		(mem3_we1		),
		.q1			(mem3_q1		), 
		.d1			(mem3_d1		)
	);
	
	// output_1
	true_sync_dpbram 
	#(	.DWIDTH   (MEM4_DATA_WIDTH), 
		.AWIDTH   (MEM4_ADDR_WIDTH), 
		.MEM_SIZE (MEM4_MEM_DEPTH)) 
	u_bram4(
		.clk		(s00_axi_aclk), 
	
	// USE Core 
		.addr0		(mem4_addr0		), 
		.ce0		(mem4_ce0  		), 
		.we0		(mem4_we0  		), 
		.q0			(mem4_q0   		), 
		.d0			(mem4_d0   		), 
	
	// USE AXI4LITE
		.addr1 		(mem4_addr1 	), 
		.ce1		(mem4_ce1		), 
		.we1		(mem4_we1		),
		.q1			(mem4_q1		), 
		.d1			(mem4_d1		)
	);

endmodule