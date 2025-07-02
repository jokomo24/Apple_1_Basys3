# build.tcl - Run with: vivado -mode batch -source build.tcl

# Project settings
set project "apple_1"
# set top_module "stopwatch_unit"
# set top_module "top_ps2_seven_seg"
# set top_module "transmit_debouncing"
set top_module "top_uart_seven_seg"
set part xc7a35tcpg236-1

set verilog_dir "${project}.srcs/sources_1/new"
if { ![file exists $verilog_dir] } {
    puts "ERROR: RTL directory not found at: $verilog_dir"
    exit 1
}

# Add the source files to the project
set src_files [glob -nocomplain "$verilog_dir/*.v"]
if {[llength $src_files] == 0} {
    puts "ERROR: No Verilog source files found in $verilog_dir"
    exit 1
}
add_files $src_files

# Update the project
update_compile_order -fileset sources_1

# Synthesis and implementation
synth_design -top $top_module -part $part
opt_design
place_design
route_design

# Output bitstream
set bitstream_dir "./${project}.runs/impl_1"
if { ![file exists $bitstream_dir] } {
    puts "ERROR: Implementation directory not found at: $bitstream_dir"
    exit 1
}
set bitstream_out "${bitstream_dir}/${top_module}.bit"
write_bitstream -force $bitstream_out

puts "INFO: Bitstream written to: $bitstream_out"