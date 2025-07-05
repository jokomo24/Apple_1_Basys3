# Vivado simulation script for apple1_core_tb
set_property target_language Verilog [current_project]

# Project settings
set project "apple_1"
set top_module "apple1_core_tb"

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


# Run simulation
launch_simulation
run 1ms
write_vcd apple1_sim.vcd
close_sim

puts "Simulation complete. Check apple1_sim.vcd for waveforms." 