; echo.asm - 6502 echo test (fixed for Verilog MMIO)
UART_RX      = $FF00     ; read from here to get received byte
UART_TX      = $FF01     ; write here to send byte

    * = $8000

reset:
    lda UART_RX
    beq reset         ; wait until nonzero byte (ready)
wait_tx:
    lda UART_TX            ; check if TX is busy? (skipped here, assumes ready)
    sta UART_TX            ; echo the character back
    jmp reset              ; repeat forever

    ; Vectors
    * = $FFFC
    .word reset
    .word 0