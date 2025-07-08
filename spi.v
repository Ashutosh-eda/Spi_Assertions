module spi(
  input reg frame,
  inout wire serial,
  output wire suspend,
  input wire clk,
  input wire rst);

`include "header_def.inc"

int suspend_on = 0;
reg [7:0] header, indata, outdata;
reg tri_en;
reg suspend_reg;
reg serial_reg;
//reg serial_proc;


////////////////////////////////////////////////
assign serial = (tri_en ? serial_reg : 1'bz);


assign suspend = suspend_reg;

initial begin
  tri_en = 0;
  suspend_reg = 0;

end

//Always block for randomly driving suspend signal
always @(posedge frame)
begin : suspend_gen
  repeat ($urandom_range(5,2))
    @(negedge clk);
  while ((suspend_on >= 1) & (frame)) begin
    @(negedge clk) suspend_reg = 1'b1;
    repeat ($urandom_range(2,1))
      @(negedge clk);
    @(negedge clk) suspend_reg= 1'b0;
    repeat ($urandom_range(6,1))
      @(negedge clk);
  end
  //Need to set suspend back to zero to allow assertions and 
  //covers to complete evalaution. Otherwise suspend can get 
  //stuck at 1 and we never see the final cycle of assertions and covers
  suspend_reg = 1'b0 ;
end

always @(posedge frame)
  begin
  @(negedge clk); //Burn a cycle to get passed reset
  collectheader(header);
  case (header)
        start  : begin
                 $display("---------------------------------------------");
                 $display("start frame received");
                 $display("---------------------------------------------");
		 end
	cfg : begin
	         collectconfig(indata);
                 $display("---------------------------------------------");
		 $display("config frame received : %h", indata);
                 $display("---------------------------------------------");
	         end
	read   : begin
                 outdata = 9'b101101101; //$urandom;
                 $display("------------------------------------------------");
	         $display("read header received, sending data : %h", outdata);
                 $display("------------------------------------------------");
		 @(negedge clk); //to fix read bus turnaround issue
		 @(posedge clk) //to fix read bus turnaround issue
	         tri_en = 1;
		 senddata(outdata);
                 @(negedge clk) tri_en = 0;
	         end
	default: begin
                 $display("---------------------------------------------");
	         $display("unknown frame header received %b", header);
                 $display("---------------------------------------------");
		 end
  endcase
  @(negedge frame);
  end			 

//Tasks which perform the variious transactions    
task collectheader (output logic [7:0] head);
  for (int i = 0;i<=7;i++) begin
    @(posedge clk iff !suspend)
      head[i] = serial;

  end
endtask

task collectconfig (output logic [7:0] conf);
  for (int i = 0;i<=7;i++) begin
    @(posedge clk iff !suspend)
      conf[i] = serial;
    
  end
endtask

task senddata (input logic [8:0] wdata);
  for (int i = 0;i<=8;i++) 
    @(negedge clk iff !suspend)
      serial_reg = wdata[i];
endtask

endmodule 






