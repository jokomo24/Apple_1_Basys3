; Minimal demo ROM for Apple 1 core debug
; Writes 0xAA to UART TX ($D001) in a loop
; Reset vector points to $E000

    .segment "CODE"
    .org $E000
start:
    lda #$AA
    sta $D001
    jmp start

    .segment "VECTORS"
    .org $FFFC
    .word start   ; Reset vector ($FFFC/$FFFD) = $E000
    .word 0       ; NMI vector ($FFFE/$FFFF) = $0000