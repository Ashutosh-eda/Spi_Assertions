// Code your design here
module spi_test(
  output reg frame,
  inout wire serial,
  input wire suspend,
  input wire clk,
  input wire rst);

`include "header_def.inc"

localparam CT = 1, ST = 2, RT = 3, 
           SF = 4, LF = 5, BH = 6, AD = 7; 

reg [7:0] senddata, rdata;
reg tri_en;

//reg serial_proc;

int txno = 8;

////////////////////////////////////////////////
assign serial = (tri_en ? senddata : 1'bz);
//assign serial = serial_proc;
//always @(senddata or tri_en)
// begin
//   if (tri_en)
//      serial_proc <= senddata;
//   else
//      serial_proc <= 1'bz;
// end
////////////////////////////////////////////////

initial begin
  frame = 0; 
  @(posedge rst);
  senddata = 0;
  frame = 0;
  tri_en = 0;
  @(negedge rst);
  while (1) begin
    txno = 8;
    while (txno >BH) begin      
      $display("\n#################################################################################################");
      $display("#################################################################################################");
      $display("\n=================================================================================================");
      $display("\n   Select LEGAL txn: config = 1; start = 2, read = 3");
      $display("OR Select ILLEGAL txn: short = 4; long = 5, unknown = 6");
      $display("OR Select Instructions for lab part 2 - allowing suspend = 7");
      $display("Your properties should pass all legal and fail all illegal transactions.");
      $display("Remember to check your cover statements for each transaction in part 2 of the lab.");      
      $display("=================================================================================================");
      $display("\n ############ HOW TO RUN THE TESTS #####################   ");           
      $display(" Add the desired signals to the waveform window.");      
      $display(" Enter your transaction number choice from the menu above.");
      $display("\n At xmsim> prompt enter:- reset; run; deposit txno = n; run;");
      $display("\n For example, to send a read transaction then enter :- ");
      $display("     xmsim> reset; run; deposit txno = 3; run;"); 
      $display("\n ***IMPORTANT*** - To select another test without leaving the simulator, enter again  :- ");
      $display("     xmsim> reset; run; deposit txno = n; run;");
      $stop;
      if (txno > BH) begin
	  $display("\n \n deposit top.dut.suspend_on = 1 to enable randomised suspend");
          $display("\n For example, to send a read transaction with suspend enabled then enter :- ");
          $display("  xmsim> reset; run; deposit top.dut.suspend_on = 1; deposit txno = 3; run;"); 	  
          $stop;
	  end
    end

    repeat (2) @(negedge clk);
    frame = 1;
    tri_en = 1;
    case (txno)
      CT: begin
          $display("+++++++++++++++++++++++++++++++++++++++++++++");
          $display("LEGAL txn: config txn sent");
          $display("+++++++++++++++++++++++++++++++++++++++++++++");
          sendheader(cfg);
          sendconfig(8'h02);
          end
      ST: begin
          $display("+++++++++++++++++++++++++++++++++++++++++++++");
          $display("LEGAL txn: start txn sent");
          $display("+++++++++++++++++++++++++++++++++++++++++++++");
          sendheader(start);
          end
      RT: begin 
          sendheader(read);
          @(negedge clk iff !suspend) tri_en = 0;
          @(negedge clk); //to fix read bus turnaround issue
          readdata(rdata);
          $display("++++++++++++++++++++++++++++++++++++++++++++++++");
          $display("LEGAL txn: read txn rxed: test data read was %h",rdata);
          $display("++++++++++++++++++++++++++++++++++++++++++++++++");
	  end
      SF: begin
          $display("+++++++++++++++++++++++++++++++++++++++++++++");
          $display("ILLEGAL txn: short frame sent");
          $display("+++++++++++++++++++++++++++++++++++++++++++++");
          // send config without data
          sendheader(cfg);
          end 
      LF: begin
          $display("+++++++++++++++++++++++++++++++++++++++++++++");
          $display("ILLEGAL txn: long frame sent");
          $display("+++++++++++++++++++++++++++++++++++++++++++++");
          // send start with extra cycles at end
          sendheader(start);
          repeat(2) @(negedge clk iff !suspend);
          end
      BH: begin
          $display("+++++++++++++++++++++++++++++++++++++++++++++");
          $display("ILLEGAL txn: Invalid header");
          $display("+++++++++++++++++++++++++++++++++++++++++++++");
          // send config with inverted header
          sendheader(!cfg);
          sendconfig(8'h02);
          end
    endcase
    @(negedge clk iff !suspend);
    frame = 0;
    senddata = 0;
    tri_en = 0;
    repeat(2) @(negedge clk);
  
    while (suspend) begin
      @(negedge clk);
    end
  end 
  $stop;
end


//Tasks which perform the variious transactions 
task sendheader (input logic [7:0] head);
  for (int i = 0;i<=7;i++) 
    @(negedge clk iff !suspend)
    senddata = head[i];
endtask

task sendconfig (input logic [7:0] conf);
  for (int i = 0;i<=7;i++)
    @(negedge clk iff !suspend)
      senddata = conf[i];
endtask

task readdata (output logic [8:0] rdata);
  for (int i = 0;i<=8;i++) begin
    @(posedge clk iff !suspend)
    $display("Sampling read data at %t", $time);
      rdata[i] = serial;
      // uncomment for debug
      //$display("sample %0d data %b",i,serial);
  end
endtask

endmodule 
