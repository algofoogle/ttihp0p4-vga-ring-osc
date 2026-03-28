#NOTE: This is a copy of LibreLane's own scripts/base.sdc,
# with some minor modifications as noted with "#ANTON:" comments.

set clock_port __VIRTUAL_CLK__
if { [info exists ::env(CLOCK_PORT)] } {
    set port_count [llength $::env(CLOCK_PORT)]

    if { $port_count == "0" } {
        puts "\[WARNING] No CLOCK_PORT found. A dummy clock will be used."
    } elseif { $port_count != "1" } {
        puts "\[WARNING] Multi-clock files are not currently supported by the base SDC file. Only the first clock will be constrained."
    }

    if { $port_count > "0" } {
        set ::clock_port [lindex $::env(CLOCK_PORT) 0]
    }
}
set port_args [get_ports $clock_port]
puts "\[INFO] Using clock $clock_port…"
create_clock {*}$port_args -name $clock_port -period $::env(CLOCK_PERIOD)

set input_delay_value [expr $::env(CLOCK_PERIOD) * $::env(IO_DELAY_CONSTRAINT) / 100]
set output_delay_value [expr $::env(CLOCK_PERIOD) * $::env(IO_DELAY_CONSTRAINT) / 100]
puts "\[INFO] Setting output delay to: $output_delay_value"
puts "\[INFO] Setting input delay to: $input_delay_value"

set_max_fanout $::env(MAX_FANOUT_CONSTRAINT) [current_design]
if { [info exists ::env(MAX_TRANSITION_CONSTRAINT)] } {
    set_max_transition $::env(MAX_TRANSITION_CONSTRAINT) [current_design]
}
if { [info exists ::env(MAX_CAPACITANCE_CONSTRAINT)] } {
    set_max_capacitance $::env(MAX_CAPACITANCE_CONSTRAINT) [current_design]
} 

set clk_input [get_port $clock_port]
set clk_indx [lsearch [all_inputs] $clk_input]
set all_inputs_wo_clk [lreplace [all_inputs] $clk_indx $clk_indx ""]

#set rst_input [get_port resetn]
#set rst_indx [lsearch [all_inputs] $rst_input]
#set all_inputs_wo_clk_rst [lreplace $all_inputs_wo_clk $rst_indx $rst_indx ""]
set all_inputs_wo_clk_rst $all_inputs_wo_clk

# correct resetn
set clocks [get_clocks $clock_port]

set_input_delay $input_delay_value -clock $clocks $all_inputs_wo_clk_rst
set_output_delay $output_delay_value -clock $clocks [all_outputs]

if { ![info exists ::env(SYNTH_CLK_DRIVING_CELL)] } {
    set ::env(SYNTH_CLK_DRIVING_CELL) $::env(SYNTH_DRIVING_CELL)
}

set_driving_cell \
    -lib_cell [lindex [split $::env(SYNTH_DRIVING_CELL) "/"] 0] \
    -pin [lindex [split $::env(SYNTH_DRIVING_CELL) "/"] 1] \
    $all_inputs_wo_clk_rst

set_driving_cell \
    -lib_cell [lindex [split $::env(SYNTH_CLK_DRIVING_CELL) "/"] 0] \
    -pin [lindex [split $::env(SYNTH_CLK_DRIVING_CELL) "/"] 1] \
    $clk_input

set cap_load [expr $::env(OUTPUT_CAP_LOAD) / 1000.0]
puts "\[INFO] Setting load to: $cap_load"
set_load $cap_load [all_outputs]

puts "\[INFO] Setting clock uncertainty to: $::env(CLOCK_UNCERTAINTY_CONSTRAINT)"
set_clock_uncertainty $::env(CLOCK_UNCERTAINTY_CONSTRAINT) $clocks

puts "\[INFO] Setting clock transition to: $::env(CLOCK_TRANSITION_CONSTRAINT)"
set_clock_transition $::env(CLOCK_TRANSITION_CONSTRAINT) $clocks

puts "\[INFO] Setting timing derate to: $::env(TIME_DERATING_CONSTRAINT)%"
set_timing_derate -early [expr 1-[expr $::env(TIME_DERATING_CONSTRAINT) / 100]]
set_timing_derate -late [expr 1+[expr $::env(TIME_DERATING_CONSTRAINT) / 100]]

if { [info exists ::env(OPENLANE_SDC_IDEAL_CLOCKS)] && $::env(OPENLANE_SDC_IDEAL_CLOCKS) } {
    unset_propagated_clock [all_clocks]
} else {
    set_propagated_clock [all_clocks]
}

# ANTON:
# Declare internal_clock as a primary clock at ~400 MHz.
# Note that it is normally derived from a ring oscillator,
# but could also come from a mux that selects the Tiny Tapeout "clk" input instead,
# but we don't care about that for our constraints.
create_clock -name internal_clk -period 2.5 [get_pins tt_um_algofoogle_vgaringosc/vgaringosc/workerclkbuff_notouch_/X]
# Set clock uncertainty and transition estimates:
set_clock_uncertainty 0.5 [get_clocks internal_clk]
set_clock_transition 0.1 [get_clocks internal_clk]
# Prevent false timing paths from external clk to internal_clk, if both exist
set_clock_groups -asynchronous -group [get_clocks clk] -group [get_clocks internal_clk]
# Ignore timing related to internal_clk selection mux options:
set_false_path -from [get_ports {ui_in[0]}]     ;# clksel[0]
set_false_path -from [get_ports {ui_in[1]}]     ;# clksel[1]
set_false_path -from [get_ports {ui_in[2]}]     ;# clksel[2]
set_false_path -from [get_ports {ui_in[3]}]     ;# clksel[3]
set_false_path -from [get_ports {ui_in[5]}]     ;# mode[0]
set_false_path -from [get_ports {ui_in[6]}]     ;# mode[1]
set_false_path -from [get_ports {ui_in[7]}]     ;# vga_mode
set_false_path -from [get_ports {uio_in[0]}]    ;# clksel2[0]
set_false_path -from [get_ports {uio_in[1]}]    ;# clksel2[1]
set_false_path -from [get_ports {ena}]
# Bit of a hack to avoid the fast ring-osc-based logic worrying about rst_n:
set_multicycle_path 3 -from [get_ports rst_n] -setup
set_multicycle_path 2 -from [get_ports rst_n] -hold
