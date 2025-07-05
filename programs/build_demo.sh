#!/bin/bash
# Build script for minimal Apple 1 demo ROM (test_led.asm)
# Assembles to test_led.mem for use in simulation/hardware

set -e

ASM=test_led.asm
BIN=test_led.bin
MEM=test_led.mem

# Assemble
ca65 $ASM -o test_led.o
ld65 -C apple1.cfg -o $BIN test_led.o

# Convert binary to mem file (one byte per line, hex)
xxd -p -c 1 $BIN | tr '[:lower:]' '[:upper:]' > $MEM

echo "Built $MEM from $ASM"