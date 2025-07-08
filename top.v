module top;

`include "header_def.inc"

reg clk = 0, rst = 0;
wire frame, serial, suspend;

// Generate clock (10ns period)
always #5 clk <= !clk;

// DUT and Testbench instantiation
spi_test tb 
    (.frame(frame), .serial(serial), .suspend(suspend), .clk(clk), .rst(rst));
spi dut
    (.frame(frame), .serial(serial), .suspend(suspend), .clk(clk), .rst(rst));

// Initialization and VCD dump for EDA Playground
initial begin
  #10 rst = 1'b1;
  #10 rst = 1'b0;


end



////////////////////////////////////////////////////////////////////
//                  SystemVerilog Assertions                       //
////////////////////////////////////////////////////////////////////

sequence framestart;
  $rose(frame);
endsequence

sequence capturehead(frame_sig, data_sig, num_cycles, logic [7:0] the_header );
  logic [7:0] seq_header = 8'hAA;
  int i = 0;
   ( framestart ##1 (frame_sig, seq_header[i] = data_sig, i++)[*num_cycles] ##0 (1, the_header = seq_header) ); 
endsequence

sequence startcomplete(dat);
  (!frame && (dat == start));
endsequence 

sequence configcomplete(dat);
  frame[*8] ##1 (!frame && (dat == cfg), $display("dat is %x", dat) );
endsequence 

sequence readcomplete(dat);
  frame[*10] ##1 (!frame && (dat == read));
endsequence

property framecheck;
  logic [7:0] head = 0;
  int i = 0;
  @(posedge clk iff !suspend)
    (framestart, i=0) |=>  
    ( frame , head[i] = serial, i++, $display("Time is %t, Head is %b, Head[i] is %x, Serial is %x, i is %d", $time, head, head[i], serial, i) )[*8] ##1
    ( (configcomplete(head) or startcomplete(head) or readcomplete(head)) , $display("Head is %x, i is %d", head, i) ) ;
endproperty

FRMCHK : assert property(framecheck)
   $display("Assertion FRMCHK passed!");
 else
   $display("Assertion FRMCHK failed!");

property framecheck_best;
  logic [7:0] a_header = 0;
  @(posedge clk iff !suspend)
     framestart |-> capturehead(frame, serial, 8, a_header) ##1 
           (configcomplete(a_header) or startcomplete(a_header) or readcomplete(a_header));
endproperty  

FRMCHK_BEST : assert property(framecheck_best);

property SIG_NOT_HIGH_FOR_X_CYCLES(a_sig, num_cycles);
   @(posedge clk) not a_sig[*num_cycles];
endproperty

CHK_SUS_NOT_HIGH_4_CYCLES: assert property(SIG_NOT_HIGH_FOR_X_CYCLES(suspend, 4));

// ======================== Coverage ============================

sequence num_starts_best(num_head_cycles);
  logic [7:0] head = 0;
  @(posedge clk iff !suspend)
  ( capturehead(frame, serial, num_head_cycles, head) ##1 startcomplete(head) );
endsequence

COV_START_BEST: cover property(num_starts_best(8));

sequence num_starts;
  logic [7:0] head = 0;
  int i = 0;
  @(posedge clk iff !suspend)
  framestart ##1 (frame, head[i] = serial, i++)[*8] ##1 startcomplete(head);
endsequence

sequence num_configs;
  logic [7:0] head = 0; 
  int i = 0;
  @(posedge clk iff !suspend)
  framestart ##1 (frame, head[i] = serial, i++)[*8] ##1 configcomplete(head);
endsequence

sequence num_reads;
  logic [7:0] head = 0;
  int i = 0;
  @(posedge clk iff !suspend)
  framestart ##1 (frame, head[i] = serial, i++)[*8] ##1 readcomplete(head);
endsequence

sequence illegal_txn;
  logic [7:0] head = 0;
  int i = 0;
  @(posedge clk iff !suspend)
  framestart ##1 (frame, head[i] = serial, i++)[*8] ##1 
    (head != start) && (head != cfg) && (head != read);
endsequence

COV_START        : cover property(num_starts);
COV_CONFIG       : cover property(num_configs);
COV_READS        : cover property(num_reads);
COV_ILLEGAL_HEAD : cover property(illegal_txn);

endmodule : top
