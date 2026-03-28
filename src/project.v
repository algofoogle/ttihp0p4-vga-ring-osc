/*
 * Copyright (c) 2026 Anton Maurovic
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none
//`timescale 1ns / 1ps

module tt_um_algofoogle_vgaringosc (
    input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs
    input  wire [7:0] uio_in,   // IOs: Input path
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // always 1 when the design is powered, so you can ignore it
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
);

  // List all unused inputs to prevent warnings
  wire _unused = &{uio_in[7:2], 1'b0};

  vgaringosc vgaringosc(
    .ena          (ena),
    .clk          (clk),
    .reset_n      (rst_n),
    .vga_mode     (ui_in[7]),
    .worker_mode  (ui_in[6:5]),
    .altclk       (ui_in[4]),
    .clksel       (ui_in[3:0]),
    .clksel2      (uio_in[1:0]),
    .oscdiv       (uio_out[7:4]),
    .hsync_n      (uo_out[7]),
    .vsync_n      (uo_out[3]),
    .rgb          ({
                    uo_out[0],uo_out[4],  // Rr.
                    uo_out[1],uo_out[5],  // Gg.
                    uo_out[2],uo_out[6]   // Bb.
                  })
  );

  assign uio_oe[7:4] = 4'b1111; // OUT: oscdiv[3:0]
  assign uio_oe[3:0] = 4'b0000;
  assign uio_out[3:0] = 0;

endmodule


