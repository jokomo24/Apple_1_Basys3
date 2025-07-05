; echo.asm - 6502 echo test for Apple 1 core
UART_RX      = $D000     ; read from here to get received byte
UART_TX      = $D001     ; write here to send byte

    .segment "CODE"
    .org $E000

reset:
    lda UART_RX
    beq reset         ; wait until nonzero byte (ready)
wait_tx:
    lda UART_TX
    bne wait_tx       ; wait until TX is not busy (0 = ready)
    lda UART_RX
    sta UART_TX       ; echo the character back
    jmp reset         ; repeat forever

    ; Vectors (must be at $FFFC and $FFFE)
    .segment "VECTORS"
    .org $FFFC
    .word reset   ; Reset vector ($FFFC/$FFFD) = $E000
    .word 0       ; NMI vector ($FFFE/$FFFF) = $0000