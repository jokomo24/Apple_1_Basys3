    .segment "CODE"
    .org $E000

start:
    lda #$55
    sta $D001
    jmp start

    ; Vectors (must be at $FFFC and $FFFE)
    .segment "VECTORS"
    .org $FFFC
    .word start   ; Reset vector ($FFFC/$FFFD) = $E000
    .word 0       ; NMI vector ($FFFE/$FFFF) = $0000