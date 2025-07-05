#!/bin/bash
set -e

if [ $# -ne 1 ]; then
  echo "Usage: $0 <basename>"
  exit 1
fi

BASENAME="$1"
ASM="$HOME/Storage/Dev/Vivado/Apple_I/programs/${BASENAME}.asm"
BIN="$HOME/Storage/Dev/Vivado/Apple_I/programs/${BASENAME}.bin"
MEM="$HOME/Storage/Dev/Vivado/Apple_I/programs/${BASENAME}.mem"
DEST="$HOME/Storage/Dev/Vivado/Apple_I/apple_1/apple_1.srcs/sources_1/new/apple1_rom.mem"

# Assemble
ca65 $ASM -o "${BASENAME}.o"
ld65 -C apple1.cfg -o $BIN "${BASENAME}.o"

# Convert binary to mem file (one byte per line, hex)
xxd -p -c 1 $BIN | tr '[:lower:]' '[:upper:]' > $MEM

echo "Built $MEM from $ASM"

# 4. Copy to Vivado source location
mkdir -p "$(dirname "$DEST")"
cp "$MEM" "$DEST"

echo "Build complete. ROM saved to $DEST"