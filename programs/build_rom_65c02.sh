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

# Check ASM file exists
if [ ! -f "$ASM" ]; then
  echo "Error: ASM file '$ASM' not found."
  exit 1
fi

echo "Assembling $ASM to $BIN..."
64tass -b -o "$BIN" "$ASM"

# Pad the binary to 64K (65536 bytes) if needed
BIN_SIZE=$(stat -c%s "$BIN" 2>/dev/null || stat -f%z "$BIN")
if [ "$BIN_SIZE" -lt 65536 ]; then
  PADDING=$((65536 - BIN_SIZE))
  echo "Padding $BIN with $PADDING zero bytes..."
  dd if=/dev/zero bs=1 count=$PADDING 2>/dev/null | cat - "$BIN" > "$BIN.padded"
  mv "$BIN.padded" "$BIN"
fi

echo "Converting $BIN to $MEM (one byte per line hex)..."
hexdump -v -e '1/1 "%02x\n"' "$BIN" > "$MEM.tmp"

mv "$MEM.tmp" "$MEM"

echo "Copying $MEM to $DEST..."
cp "$MEM" "$DEST"

echo "Build complete."