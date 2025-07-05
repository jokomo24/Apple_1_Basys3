# flash.tcl - Program the Basys 3 board with the generated bitstream
# Usage: vivado -mode batch -source flash.tcl

set project "apple_1"
# set top_module "stopwatch_unit"
# set top_module "top_ps2_seven_seg"
# set top_module "transmit_debouncing"
# set top_module "top_uart_seven_seg"
set top_module "apple1_core"
# set top_module "top"
set bitstream "./${project}.runs/impl_1/${top_module}.bit"

# Check if the bitstream file exists
if { ![file exists $bitstream] } {
    puts "ERROR: Bitstream file not found: $bitstream"
    exit 1
}

# Open hardware manager and connect to the Digilent cable
open_hw_manager
connect_hw_server

# Refresh the device list
open_hw_target

# Get the first available Xilinx device on the target
set device [lindex [get_hw_devices] 0]
if { $device eq "" } {
    puts "ERROR: No hardware device found!"
    close_hw_manager
    exit 1
}

# Prepare and refresh the device
puts "INFO: Found device: $device"
refresh_hw_device $device

# Program the FPGA
puts "INFO: Programming device with bitstream: $bitstream"
set_property PROGRAM.FILE $bitstream $device
program_hw_devices $device
puts "INFO: Programming complete."

# Close everything
close_hw_manager
exit