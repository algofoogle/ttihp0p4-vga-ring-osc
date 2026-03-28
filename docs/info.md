<!---

This file is used to generate your project datasheet. Please fill in the information below and delete any unused
sections.

You can also include images in this folder and reference them in the markdown. Each image must be less than
512 kb in size, and the combined size of all images must be less than 1 MB.
-->

## How it works

This is a TTIHP0p4 experimental resubmission of the TTGF0p2 version: [ttgf0p2-vga-ring-osc](https://github.com/algofoogle/ttgf0p2-vga-ring-osc)

Manually-instantiated ihp-sg13cmos5l inverter cells form a chain out of chain segments of varying lengths, allowing the user to select given points in the overall chain to loop back to produce a ring oscillator. This makes a configurable ring oscillator that is expected to be able to oscillate from about 20MHz up to ~850MHz (theoretically 3.7GHz but this probably won't work).

This (or an external clock) then can be selected to drive a "worker" module: a counter which counts up to 3000.

Alongside this is a VGA sync generator which takes its pixel colour from whatever is in the upper 6 bits of the worker's counter at the time. The worker is reset during HBLANK of each VGA line.

It's expected that at the faster ring oscillator speeds, the counter will reach its target of 3000 sooner than the width of the VGA line but with some jitter... or the counter/compare logic will break down because it's too fast.


## How to test

Set `clksel2[1:0]` to 0.

Set `clksel[3:0]` to (say) 10, or anything greater than 1.

Set `mode[1:0]` to 0 (though these are unused at the time of writing; TBA).

Set `vga_mode` to 0.

Attach a Tiny VGA PMOD to `uo_out`.

Supply a 25MHz clock to the system `clk`, and assert reset for at least 2 clocks.

Expect to see vertical coloured bars on screen, but expect some jitter. Their width should increase as you increase `clksel`.

Measure the ring oscillator (or rather, the selected clock source) on `uio_out[7:4]`: `uio_out[4]` is the raw oscillator output, and the higher bits are the oscillator divided by powers of 2.

More testing notes:

*   When `vga_mode==1`, `clk` should be 26.6175MHz ([106.47 MHz](http://www.tinyvga.com/vga-timing/1440x900@60Hz) &div; 4) to drive a 1440x900 60Hz VGA display.

*   When `clksel2` is:

    *   0: Just rely on `clksel`.
    *   1: Use fixed 25-deep inv_2 ring oscillator.
    *   2: Use fixed 25-deep inv_4 ring oscillator.
    *   3: Use inverted `clk`.
    *   NOTE: options 1 and 2 require `clksel > 1` (any value will do) to enable the rings.

*   When `clksel2==0` and `clksel` is:

    *   0: Use `clk`.
    *   1: Use `altclk`.
    *   For values 2 and above, use an inv_1-based ring oscillator tapped at...
    *   2: => 3   => 3.70 GHz
    *   3: => 5   => 2.22 GHz
    *   4: => 9   => 1.23 GHz
    *   5: => 13  => 855 MHz
    *   6: => 19  => 585 MHz
    *   7: => 25  => 444 MHz
    *   8: => 33  => 337 MHz
    *   9: => 41  => 271 MHz
    *   10: => 57  => 195 MHz
    *   11: => 65  => 171 MHz
    *   12: => 97  => 115 MHz
    *   13: => 161 => 69.0 MHz
    *   14: => 289 => 38.4 MHz
    *   15: => 545 => 20.4 MHz

(NOTE: Frequencies are ROUGHLY estimated, and it's expected that going above 855MHz internally probably won't work).

## External hardware

Tiny VGA PMOD and a VGA monitor.

