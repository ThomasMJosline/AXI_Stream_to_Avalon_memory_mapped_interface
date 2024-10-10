module axis_avmm_direct #(
    parameter  data_width = 128,
    parameter  address_width = 27,
    parameter burstcount_width = 7,
    parameter byte_enable_width = data_width/8 
 
 
 ) (
    input user_resetn,
    input user_clk,
 
    input amm_ready,
    input [data_width-1:0] amm_readdata,
    input amm_readdatavalid,
 
 
    output amm_read,
    output amm_write,
    output [address_width-1:0] amm_address,
    output [data_width-1:0] amm_writedata,
    output [burstcount_width-1:0] amm_burstcount,
    output [byte_enable_width-1:0] amm_byteenable,
     
     
      input [data_width-1:0] s_axis_tdata,
     input s_axis_tvalid,
     output s_axis_tready
 );
  
 
 localparam transfers_burst = 28;
 
 assign amm_byteenable = 16'b1111111111111111;
 assign amm_burstcount = 7'd28;
 
 
 reg amm_read_i, amm_write_i;
 reg [address_width-1:0] amm_address_i;
 
 
 //***********states************
 localparam RESET  = 2'b00;
 localparam WRITE = 2'b01;
 localparam READ  = 2'b10;
 
 reg [1:0] current_state, next_state;
 
  

 //***********counter for counting transfers in write bursts*********
 logic [burstcount_width-1:0] burst_count;
 logic burst_done;
 
 always @(posedge user_clk or negedge user_resetn) begin
     if (!user_resetn)
         burst_count <= 0;
     else begin
         if ((current_state != WRITE) && (next_state == WRITE))
             burst_count <= 0;
         else if ((current_state == WRITE) && (amm_ready == 1'b1) && (s_axis_tvalid==1'b1)) 
             burst_count <= burst_count + 7'd1;
     end
 end
 
 assign burst_done = (burst_count == transfers_burst-1)? 1'b1 : 1'b0;
 
 
 //**********State machine***************
 always @(posedge user_clk or negedge user_resetn ) begin
    if (!user_resetn) begin
        current_state <= RESET;
        end
    else
        current_state <= next_state;
 end
 
 
 //*********State transition logic************
 always @(*) begin
 
    case (current_state)
 
        RESET: next_state = WRITE;
            
        WRITE:begin
            if (amm_ready) begin
                if ( burst_done == 1) begin
                    next_state = READ;
                end
                else begin
                    next_state = WRITE;
                end
            end
            else begin
                next_state = WRITE;
            end
            end
 
        READ:begin
            if (amm_ready) begin
                next_state = WRITE;
            end
            else begin
                next_state = READ;
            end
 
            end
    endcase
 end
 
 
 //*********write enable(amm_write_i)***************
 always @(*) begin
    if ((current_state == WRITE) && s_axis_tvalid)
        amm_write_i = 1;
    else 
        amm_write_i = 1'b0;
  end
 
 
 assign amm_write = amm_write_i;
 
 //*********read enable(amm_read_i)***************
 always @(*) begin 
       if (current_state == READ) 
             amm_read_i = 1'b1;
       else 
             amm_read_i = 1'b0;
  end
 
 
 assign amm_read = amm_read_i;
 
////
 
 assign amm_writedata = s_axis_tdata ;
 
 
 //******address updation after burst*******
 always @(posedge user_clk or negedge user_resetn) begin
     if (!user_resetn)
         amm_address_i <= 0; 
     else begin 
         if ((current_state == READ) && (next_state == WRITE))
             amm_address_i <= amm_address_i + (16*amm_burstcount);
             else 
                 amm_address_i <= amm_address;
     end
 end
             
 assign amm_address = amm_address_i;
 

  
 assign s_axis_tready = amm_ready && amm_write;

       
       
 endmodule
