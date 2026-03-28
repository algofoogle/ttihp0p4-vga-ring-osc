`default_nettype none
//`timescale 1ns / 1ps

`define PDK_INVERTER_CELL   sg13cmos5l_inv_1
//NOTE: If you change this cell, the port names may need to be altered in any instances.

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

module inverter_cell (
    input   wire a,
    output  wire y
);

    `LINT_OFF_PINMISSING_POWER_PINS
    (* keep_hierarchy *) `PDK_INVERTER_CELL pdkinv_notouch_ (
        .A  (a),
        .Y  (y)
    );
    `LINT_ON_PINMISSING_POWER_PINS

endmodule


// A chain of inverters (not a ring, itself)
module inv_chain #(
    parameter N = 10 // SHOULD BE EVEN.
) (
    input a,
    output y
);

    wire [N-1:0] ins;
    wire [N-1:0] outs;
    assign ins[0] = a;
    assign ins[N-1:1] = outs[N-2:0];
    assign y = outs[N-1];
    (* keep_hierarchy *) inverter_cell inv_array [N-1:0] ( .a(ins), .y(outs) );

endmodule


// A ring where the point of loopback is selectable:
module tapped_ring #(
    //NOTE: These parameters must be even-numbered since
    // there is a final baked-in inverter that makes the ring odd.
    //NOTE: These are deltas, i.e. each in turn is added to those before it.
    parameter TAP00 = 2,   // => 3   => 3.70 GHz
    parameter TAP01 = 2,   // => 5   => 2.22 GHz
    parameter TAP02 = 4,   // => 9   => 1.23 GHz
    parameter TAP03 = 4,   // => 13  => 855 MHz
    parameter TAP04 = 6,   // => 19  => 585 MHz
    parameter TAP05 = 6,   // => 25  => 444 MHz
    parameter TAP06 = 8,   // => 33  => 337 MHz
    parameter TAP07 = 8,   // => 41  => 271 MHz
    parameter TAP08 = 16,  // => 57  => 195 MHz
    parameter TAP09 = 16,  // => 65  => 171 MHz
    parameter TAP10 = 32,  // => 97  => 115 MHz
    parameter TAP11 = 64,  // => 161 => 69.0 MHz
    parameter TAP12 = 128, // => 289 => 38.4 MHz
    parameter TAP13 = 256, // => 545 => 20.4 MHz
    // Spares (not normally used by this design):
    parameter TAP14 = 2,   // => 547
    parameter TAP15 = 2    // => 549
) (
    input ena,
    input [3:0] tap,
    output y
);
    wire ring_head;
    wire [15:0] chain;

    assign y = ena && chain[tap];

    inverter_cell         head ( .a(y),         .y(ring_head) ); // If all the counts below are even, this makes it odd.
    inv_chain #(.N(TAP00)) c00 ( .a(ring_head), .y(chain[ 0]) );
    inv_chain #(.N(TAP01)) c01 ( .a(chain[ 0]), .y(chain[ 1]) );
    inv_chain #(.N(TAP02)) c02 ( .a(chain[ 1]), .y(chain[ 2]) );
    inv_chain #(.N(TAP03)) c03 ( .a(chain[ 2]), .y(chain[ 3]) );
    inv_chain #(.N(TAP04)) c04 ( .a(chain[ 3]), .y(chain[ 4]) );
    inv_chain #(.N(TAP05)) c05 ( .a(chain[ 4]), .y(chain[ 5]) );
    inv_chain #(.N(TAP06)) c06 ( .a(chain[ 5]), .y(chain[ 6]) );
    inv_chain #(.N(TAP07)) c07 ( .a(chain[ 6]), .y(chain[ 7]) );
    inv_chain #(.N(TAP08)) c08 ( .a(chain[ 7]), .y(chain[ 8]) );
    inv_chain #(.N(TAP09)) c09 ( .a(chain[ 8]), .y(chain[ 9]) );
    inv_chain #(.N(TAP10)) c10 ( .a(chain[ 9]), .y(chain[10]) );
    inv_chain #(.N(TAP11)) c11 ( .a(chain[10]), .y(chain[11]) );
    inv_chain #(.N(TAP12)) c12 ( .a(chain[11]), .y(chain[12]) );
    inv_chain #(.N(TAP13)) c13 ( .a(chain[12]), .y(chain[13]) );
    inv_chain #(.N(TAP14)) c14 ( .a(chain[13]), .y(chain[14]) );
    inv_chain #(.N(TAP15)) c15 ( .a(chain[14]), .y(chain[15]) );
endmodule

// Just a short, fixed ring: by default, 25 instances of inv_2:
module ringosc_inv2 #(
    parameter N = 25 // Must be odd-numbered!
) (
    input ena,
    output y
);
    wire [N-1:0] ins;
    wire [N-1:0] outs;
    assign ins[N-1:1] = outs[N-2:0];
    assign ins[0] = outs[N-1] & ena; // ena==0 will break the loop (stop the oscillator ring, hence flush it out too).
    assign y = ins[0];
    `LINT_OFF_PINMISSING_POWER_PINS
    (* keep_hierarchy *) sg13cmos5l_inv_2 inv_array_notouch_ [N-1:0] (.A(ins), .Y(outs));
    `LINT_ON_PINMISSING_POWER_PINS
endmodule

// Another short, fixed ring: by default, 25 instances of inv_4:
module ringosc_inv4 #(
    parameter N = 25 // Must be odd-numbered!
) (
    input ena,
    output y
);
    wire [N-1:0] ins;
    wire [N-1:0] outs;
    assign ins[N-1:1] = outs[N-2:0];
    assign ins[0] = outs[N-1] & ena; // ena==0 will break the loop (stop the oscillator ring, hence flush it out too).
    assign y = ins[0];
    `LINT_OFF_PINMISSING_POWER_PINS
    (* keep_hierarchy *) sg13cmos5l_inv_4 inv_array_notouch_ [N-1:0] (.A(ins), .Y(outs));
    `LINT_ON_PINMISSING_POWER_PINS
endmodule
