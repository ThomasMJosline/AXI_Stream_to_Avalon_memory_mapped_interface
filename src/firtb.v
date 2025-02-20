`timescale 1ns / 1ps
module firtb;
parameter N=20,K=148; //constants declaration
parameter W_in=37;
parameter W_in_F =28;
parameter W_coef=16;
parameter W_out=W_in+N;
parameter xL=148;


reg clk;
wire signed [W_out-1:0] out_data;

reg resetn_,resetn_fir;
wire m_tvalid;
wire signed [36:0] m_tdata;

fir #(
  .N(N),.W_in(W_in),.W_in_F(14),.W_out(W_out),.W_coef(W_coef)) fir_dut 
(.clk(clk),.resetn(resetn_fir),.t_data_in(m_tdata),.t_valid_in(m_tvalid),.t_ready(tready),.out_data(out_data),
  .out_valid(out_valid)  );

datasrc #(.xL(xL)) src_dut(.clk(clk),.resetn(resetn_),.tready(tready),.tvalid(m_tvalid),.tdata(m_tdata));
//clock generation
always #3 clk=~clk;

integer fp_write_out;
initial  
begin
  clk=0;
  resetn_fir=0;
  fp_write_out = $fopen("D:/Academics/Sem8/signal_processing_algorithms_to_DSP_arch/filter_codes/outdata.dat","w");      
  resetn_=0;
  #5 resetn_fir=1; resetn_=1;
  #1000 resetn_fir=0;
  #20 resetn_fir=1;
  #10000 $fclose(fp_write_out);
end
always @(posedge clk ) begin
  if (out_valid) begin
   $fwrite(fp_write_out,"%b\n",out_data);
	//$display("Output Written %d",out_data); 
end
end


endmodule
