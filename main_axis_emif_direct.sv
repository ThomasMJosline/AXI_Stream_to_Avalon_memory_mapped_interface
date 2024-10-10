module main_axis_emif_direct (

   
    output local_reset_done,

    input clock,                    //********* pll ref clock ************
    input reset_n,
    input oct_rzqin,


    output [0:0]    mem_ck,               //                mem.mem_ck,               CK clock
    output [0:0]    mem_ck_n,             //                   .mem_ck_n,             CK clock (negative leg)
    output [16:0]   mem_a,                //                   .mem_a,                Address
    output [0:0]    mem_act_n,            //                   .mem_act_n,            Activation command
    output [1:0]    mem_ba,               //                   .mem_ba,               Bank address
    output [0:0]    mem_bg,               //                   .mem_bg,               Bank group
    output [0:0]    mem_cke,              //                   .mem_cke,              Clock enable
    output [0:0]    mem_cs_n,             //                   .mem_cs_n,             Chip select
    output [0:0]    mem_odt,              //                   .mem_odt,              On-die termination
    output [0:0]    mem_reset_n,          //                   .mem_reset_n,          Asynchronous reset
    output [0:0]    mem_par,              //                   .mem_par,              Command and address parity
    input [0:0]    mem_alert_n,          //                   .mem_alert_n,          Alert flag
    inout [1:0]    mem_dqs,              //                   .mem_dqs,              Data strobe
    inout [1:0]    mem_dqs_n,            //                   .mem_dqs_n,            Data strobe (negative leg)
    inout [15:0]    mem_dq,               //                   .mem_dq,               Read/write data
    inout [1:0]    mem_dbi_n, 

    output local_cal_success,
    output local_cal_fail,
	 output [7:0] latency_counter

);

localparam data_width = 128;
localparam  address_width = 27;
localparam burstcount_width = 7;
localparam byte_enable_width = data_width/8;


//latency count

reg [7:0] latency_count;

//fifo for reading data from EMIF IP
reg [127:0] amm_readdata_fifo [0:4095];   
reg [11:0] fifo_ptr;
reg fifo_full; //  
////////////////

assign latency_counter = latency_count;

//******wires b/w axis_avmm_dut and emif_module*******
wire user_clk;
wire user_resetn;
wire ninit_done;

wire amm_ready;
wire [address_width-1:0]amm_address;
wire [data_width-1:0] amm_readdata;
wire amm_readdatavalid;
wire amm_read;
wire amm_write;
wire [data_width-1:0] amm_writedata;
wire [burstcount_width-1:0] amm_burstcount;
wire [byte_enable_width-1:0] amm_byteenable;


wire s_axis_tready;
wire [127:0]s_axis_tdata;
wire s_axis_tvalid;


wire system_resetn;
wire local_reset_req;
wire s_axis_tvalid_in_sys;

wire [1:0] source;

assign system_resetn = ~ninit_done & user_resetn;

//in_system ip
in_system_ip in_sys_mod(
	.source(source)
);

assign s_axis_tvalid_in_sys = source[0];
assign local_reset_req = source[1] ;


assign s_axis_tvalid = s_axis_tvalid_in_sys;
	

//counter for generating AXI-stream data
reg [10:0] inp_data_counter;

always @ (posedge user_clk) begin
if (!system_resetn)
	inp_data_counter <= 0;
else begin
	if (s_axis_tready && s_axis_tvalid) begin    /// add amm_write into the if condition
		inp_data_counter <= inp_data_counter + 11'd1;
		end
	else begin
		inp_data_counter <= inp_data_counter;
		end
	end
end

// reg for counting b/w read_enable and readdatavalid
always @ (posedge user_clk) begin
	if (amm_read == 1'b1)
		latency_count = 0;
	else begin
		if (amm_readdatavalid == 0) 
			latency_count = latency_count + 8'b1;
		else
			latency_count = latency_count;
	end
end



//******reset_rel_module to axis_avmm************


reset_rel reset_rel_module(
		.ninit_done(ninit_done)  // ninit_done.reset
	);


axis_avmm_direct #(
    .data_width(data_width), 
    .address_width(address_width), 
    .burstcount_width(burstcount_width), 
    .byte_enable_width(byte_enable_width)
    )
axis_avmm_dut (
    .amm_ready(amm_ready), 
    .user_clk(user_clk), 
    .user_resetn(system_resetn), 
    .amm_address(amm_address),
    .amm_readdata(amm_readdata), 
    .amm_readdatavalid(amm_readdatavalid), 
    .amm_read(amm_read), 
    .amm_write(amm_write), 
    .amm_writedata(amm_writedata),
    .amm_burstcount(amm_burstcount), 
    .amm_byteenable(amm_byteenable), 
    .s_axis_tvalid(s_axis_tvalid),        
    .s_axis_tdata(inp_data_counter),      
    .s_axis_tready(s_axis_tready)                              
    );
    

    qsys_fpga_emif u0 (
                .clk_clk                                       (clock),                                       //   input,    width = 1,                          clk.clk
                .emif_fm_0_local_reset_req_local_reset_req     (local_reset_req),     //   input,    width = 1,    emif_fm_0_local_reset_req.local_reset_req
                .emif_fm_0_local_reset_status_local_reset_done (local_reset_done), //  output,    width = 1, emif_fm_0_local_reset_status.local_reset_done
                .emif_fm_0_oct_oct_rzqin                       (oct_rzqin),                       //   input,    width = 1,                emif_fm_0_oct.oct_rzqin
                .emif_fm_0_mem_mem_ck                          (mem_ck),                          //  output,    width = 1,                emif_fm_0_mem.mem_ck
                .emif_fm_0_mem_mem_ck_n                        (mem_ck_n),                        //  output,    width = 1,                             .mem_ck_n
                .emif_fm_0_mem_mem_a                           (mem_a),                           //  output,   width = 17,                             .mem_a
                .emif_fm_0_mem_mem_act_n                       (mem_act_n),                       //  output,    width = 1,                             .mem_act_n
                .emif_fm_0_mem_mem_ba                          (mem_ba),                          //  output,    width = 2,                             .mem_ba
                .emif_fm_0_mem_mem_bg                          (mem_bg),                          //  output,    width = 2,                             .mem_bg
                .emif_fm_0_mem_mem_cke                         (mem_cke),                         //  output,    width = 1,                             .mem_cke
                .emif_fm_0_mem_mem_cs_n                        (mem_cs_n),                        //  output,    width = 1,                             .mem_cs_n
                .emif_fm_0_mem_mem_odt                         (mem_odt),                         //  output,    width = 1,                             .mem_odt
                .emif_fm_0_mem_mem_reset_n                     (mem_reset_n),                     //  output,    width = 1,                             .mem_reset_n
                .emif_fm_0_mem_mem_par                         (mem_par),                         //  output,    width = 1,                             .mem_par
                .emif_fm_0_mem_mem_alert_n                     (mem_alert_n),                     //   input,    width = 1,                             .mem_alert_n
                .emif_fm_0_mem_mem_dqs                         (mem_dqs),                         //   inout,    width = 9,                             .mem_dqs
                .emif_fm_0_mem_mem_dqs_n                       (mem_dqs_n),                       //   inout,    width = 9,                             .mem_dqs_n
                .emif_fm_0_mem_mem_dq                          (mem_dq),                          //   inout,   width = 72,                             .mem_dq
                .emif_fm_0_mem_mem_dbi_n                       (mem_dbi_n),                       //   inout,    width = 9,                             .mem_dbi_n
                .emif_fm_0_status_local_cal_success            (local_cal_success),            //  output,    width = 1,             emif_fm_0_status.local_cal_success
                .emif_fm_0_status_local_cal_fail               (local_cal_fail),               //  output,    width = 1,                             .local_cal_fail
                .emif_fm_0_emif_usr_reset_n_reset_n            (user_resetn),            //  output,    width = 1,   emif_fm_0_emif_usr_reset_n.reset_n
                .emif_fm_0_emif_usr_clk_clk                    (user_clk),                    //  output,    width = 1,       emif_fm_0_emif_usr_clk.clk
                .emif_fm_0_ctrl_amm_0_waitrequest_n            (amm_ready),            //  output,    width = 1,         emif_fm_0_ctrl_amm_0.waitrequest_n
                .emif_fm_0_ctrl_amm_0_read                     (amm_read),                     //   input,    width = 1,                             .read
                .emif_fm_0_ctrl_amm_0_write                    (amm_write),                    //   input,    width = 1,                             .write
                .emif_fm_0_ctrl_amm_0_address                  (amm_address),                  //   input,   width = 26,                             .address
                .emif_fm_0_ctrl_amm_0_readdata                 (amm_readdata),                 //  output,  width = 576,                             .readdata
                .emif_fm_0_ctrl_amm_0_writedata                (amm_writedata),                //   input,  width = 576,                             .writedata
                .emif_fm_0_ctrl_amm_0_burstcount               (amm_burstcount),               //   input,    width = 7,                             .burstcount
                .emif_fm_0_ctrl_amm_0_byteenable               (amm_byteenable),               //   input,   width = 72,                             .byteenable
                .emif_fm_0_ctrl_amm_0_readdatavalid            (amm_readdatavalid),            //  output,    width = 1,                             .readdatavalid
                .reset_reset_n                                 (reset_n)                                    //   input,    width = 1,                        reset.reset
        );

		  
always @ (posedge user_clk) begin
	if (!system_resetn) begin
//        amm_readdata_fifo <= 0;
        fifo_ptr <= 0;   
    end
    else begin
	    if (amm_readdatavalid) begin
            amm_readdata_fifo[fifo_ptr] <= amm_readdata;
            fifo_ptr <= fifo_ptr + 12'd1;
	    end
    end 
end		  

   
assign fifo_full = (fifo_ptr == 12'd4095) ? 1 : 0;

endmodule
