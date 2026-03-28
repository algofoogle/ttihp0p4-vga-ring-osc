`default_nettype none
//`timescale 1ns / 1ps

module sync (
  input clk,
  input in,
  output out
);
  reg [1:0] buff;
  always @(posedge clk) begin
    buff <= {buff[0], in};
  end
  assign out = buff[1];
endmodule
