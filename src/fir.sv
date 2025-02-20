module fir #(
  parameter N=20,                 // tap length
  parameter infile="D:/Academics/Sem8/signal_processing_algorithms_to_DSP_arch/filter_codes/rc_filter_binary_20.txt",   // coefficient
  parameter W_in=37,              // input word length
  parameter W_in_F=28,
  parameter W_coef=16,             // coefficient width
  parameter W_out=W_in+N             // output word length
) (
  input clk,
  input resetn,
  input signed [W_in-1:0] t_data_in,
  input t_valid_in,
  output t_ready,  
  output signed [W_out-1:0] out_data,
  output out_valid
  );

reg signed [W_coef-1:0] h_tap[0:N-1];
initial $readmemb(infile, h_tap);   // initialize filter coefficient

reg signed [W_in-1:0] x_buff[0:N-1];
reg dout_valid_reg;


// FSM for buffering registers
localparam S0 = 'd0;    // reset state
localparam S1 = 'd1;    // reading mode
reg [2:0] state, n_state;
reg n_s_tready,s_tready;

assign t_ready=s_tready;

// multiplications and rounding
reg signed[W_in+W_coef:0] temp;
reg signed[W_in-1:0] prod[N>>1-1:0];
reg signed[W_out-1:0] sum;

// Buffering input
generate
genvar iin;
for (iin = 0; iin < N; iin++) begin:gen1
    always @(posedge clk) begin
        if (!resetn)
        begin 
            x_buff[iin]<=0;
        end
        else if (t_valid_in) 
        begin
            if (iin == 0)  
            begin
                x_buff[iin] <= t_data_in;
            end
            else  
            begin        
                x_buff[iin] <= x_buff[iin - 1]; 
            end
        end
    end
end    
endgenerate

always @(posedge clk) begin
    if (~resetn) begin
        state <= S0;
        s_tready<=0;
        //dout_valid_reg<=0;
    end else if (t_valid_in) begin
        state <= n_state;
        s_tready <= n_s_tready;
    end
end

always @(*) begin
    // Defaults
    //n_s_tready = s_tready                   ;
    // Conditional:
    case (state)
        S0: begin   // reset
            if (t_valid_in) begin n_state = S1; n_s_tready=1;end
            else begin n_state = S0; n_s_tready=0; end
        end
        S1: begin    // filtering mode
            n_state = S1; 
            n_s_tready=1; 
            end                
        default: begin
            n_state = S0;n_s_tready=0;
        end
    endcase
end


always@(posedge clk)
begin
    if (!resetn) begin
        for (integer ip = 0; ip < N; ip++)  
            begin prod[ip]=0;  end
        end
    else begin
        dout_valid_reg=0;
        for (integer ip = 0; ip < N>>1; ip++) begin 
        temp=(x_buff[ip]+x_buff[N-1-ip])*h_tap[ip];                 // fp Q(W_in+W_coe).(W_in_F+W_coe_F) Full width required
        prod[ip]=temp[W_in_F+W_in-1:W_in_F];       // fp Q(W_in).W_in_F truncating
        //$display("Loop 1 ip=%d prod=%p x-buff=%p h-tap=%p",ip,temp,x_buff,h_tap);                
                        end        
        sum=0;
        for (integer isum = 0; isum < N>>1; isum++) begin  
            sum=sum+prod[isum];                           // fp Q(W_in+N).W_in_F full width 
        end
        dout_valid_reg=1;
        //$display("Loop sum=%d x-buff=%p h-tap=%p",sum,x_buff,h_tap);
        end
end
     



assign out_data=sum;
assign out_valid=resetn&dout_valid_reg;
endmodule
