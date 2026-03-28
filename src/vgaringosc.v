`default_nettype none
//`timescale 1ns / 1ps

`define PDK_CLKBUFF_CELL    sg13cmos5l_buf_8
//NOTE: If you change this cell, the port names may need to be altered in any instance.


// This is to manage lint checking to not report about unconnected power pins.
// Thanks https://github.com/dlmiles/ttgf0p2-ringosc-5inv/blob/main/src/project.v
`ifndef LINT_OFF_PINMISSING_POWER_PINS
`ifdef USE_POWER_PINS
`define LINT_OFF_PINMISSING_POWER_PINS /* verilator lint_off PINMISSING */
`define LINT_ON_PINMISSING_POWER_PINS /* verilator lint_on PINMISSING */
`else
`define LINT_OFF_PINMISSING_POWER_PINS /* */
`define LINT_ON_PINMISSING_POWER_PINS /* */
`endif
`endif


module vgaringosc(
    input ena,
    input clk,
    input reset_n,
    input vga_mode, // 0=normal, 1=1440x900
    input [1:0] worker_mode, // Selects what 'work' the ring oscillator drives.
    input [3:0] clksel, // Selects clock source or ring length. 0=clk, 1=altclk, 2+ goes to RO.
    input [1:0] clksel2, // 0=normal. 1=use ring_clk2x5, 2=use ring_clk4x5, 3=use !clk
    input altclk,
    output [3:0] oscdiv, // [0]=raw oscillator, [1]=div2, [2]=div4, [3]=div8
    output hsync_n,
    output vsync_n,
    output [5:0] rgb // RRGGBB
);

    wire hblank;
    wire vblank;
    wire visible;
    wire [9:0] h;
    wire [9:0] v;
    wire hmax;
    wire vmax;
    wire [5:0] rgb_raw;

    wire reset = !reset_n;

    // VGA sync generator:
    vga_sync vga_sync(
      .clk        (clk),
      .reset      (reset),
      .mode       (vga_mode),
      .o_hsync    (hsync_n),
      .o_vsync    (vsync_n),
      .o_hblank   (hblank),
      .o_vblank   (vblank),
      .o_hpos     (h),
      .o_vpos     (v),
      .o_hmax     (hmax),
      .o_vmax     (vmax),
      .o_visible  (visible)
    );

    //DECIDE: Should ring_ena always be on while system 'ena' is on?
    // Should there be an explicit ring reset, or just worker reset?
    // MAYBE not ring reset (as this is just holding ring_ena low for a while),
    // but should the ring be allowed to be free-running while the WORKER is being reset?
    wire ring_ena = ena && (clksel>=2) && !reset;
    //^^NOTE: Including reset means the ring can be flushed while the design remains selected.
    // Also, we don't want the ring running if we're trying to use a "debug" clock source.
    wire ring_clk;
    wire ring_clk2x5;
    wire ring_clk4x5;
    wire altring1 = clksel2==1;
    wire altring4 = clksel2==2;

    // Clock mux; not a proper glitch-free mux, but good enough for this case:
    wire worker_clock_unbuffered =
        reset       ?   clk :     // During reset, let CLK thru to the worker to help its sync. reset.
        altring1    ?   ring_clk2x5 :
        altring4    ?   ring_clk4x5 :
        clksel2==3  ?   (!clk) :
        clksel==0   ?   clk :
        clksel==1   ?   altclk :
        /*clksel>=2*/   ring_clk;
    // Buffered clock, to help CTS/SDC find the 'internal_clock' source pin:
    wire worker_clock;
    `LINT_OFF_PINMISSING_POWER_PINS
    (* keep_hierarchy *) `PDK_CLKBUFF_CELL workerclkbuff_notouch_ (.A(worker_clock_unbuffered), .X(worker_clock));
    `LINT_ON_PINMISSING_POWER_PINS

    wire worker_reset = reset || hblank; // Hold the worker in (a nice long) reset during VGA HBLANK period.

    tapped_ring tapped_ring(
        .ena        (ring_ena),
        .tap        (clksel-4'd2), // clksel==2 => TAP00 ... clksel==15 => TAP13
        .y          (ring_clk)
    );

    // Alternate fixed ring oscillator of 25x inv1:
    ringosc_inv2 #(.N(25)) ro_inv2(
        .ena        (ring_ena && altring1),
        .y          (ring_clk2x5)
    );

    // Alternate fixed ring oscillator of 25x inv4:
    ringosc_inv4 #(.N(25)) ro_inv4(
        .ena        (ring_ena && altring4),
        .y          (ring_clk4x5)
    );

    ring_worker ring_worker(
        .reset      (worker_reset),
        .clk        (worker_clock),
        .mode       (worker_mode),
        .oscdiv     (oscdiv),
        .computed   (rgb_raw)
    );

    wire checkerboard = (h[0]^v[0]);

    wire border = ((v==0) || (v==479) || (h==0) || (h==639)) && checkerboard;

    assign rgb = ( {6{border}} | rgb_raw ) & {6{visible}};

endmodule
