`default_nettype none
//`timescale 1ns / 1ps

module ring_worker(
  input reset,
  input clk,
  input [1:0] mode,
  output [3:0] oscdiv,
  output reg [11:0] raw_data,
  output [5:0] computed
);
  wire reset_sync;
  sync resetsync (.clk(clk), .in(reset), .out(reset_sync));
  // .......
  reg [2:0] counter;
  always @(posedge clk) begin
    counter <= reset_sync ? 0 : counter+1;
  end
  assign oscdiv = {counter,clk};

  // Counts up to 3000 (if it has enough time) and then pauses there until reset:
  always @(posedge clk) begin
    if (reset_sync)
      raw_data <= 0;
    else if (raw_data<3000)
      raw_data <= raw_data+1;
  end
  assign computed = raw_data[11:6];
  // .......
endmodule

