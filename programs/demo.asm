; Simple 65C02 demo for Basys3
; Reads switches ($FF20), writes to LEDs ($FF00) and 7-segment ($FF10)
; 7-seg shows hex value of switches on digit 0 (anode 0)
        * = $E000
RESET:  LDA $FF20      ; Read switches
        STA $FF00      ; Write to LEDs
        LDA $FF20      ; Read switches again
        JSR HEX2SEG    ; Convert to 7-seg pattern in A
        STA $FF10      ; Write to 7-seg (seg pattern)
        LDA #$0E       ; Anode 0 active (bit 0 low, others high)
        STA $FF11      ; Write to anode register (if needed)
        JMP RESET

; HEX2SEG: Convert A (0-15) to 7-seg pattern in A
HEX2SEG:
        AND #$0F
        TAX
        LDA segtab,X
        RTS

; 7-segment patterns for 0-F (abcdefg, active high)
segtab:  .byte $3F,$06,$5B,$4F,$66,$6D,$7D,$07
        .byte $7F,$6F,$77,$7C,$39,$5E,$79,$71

        * = $FFFC
        .word RESET     ; Reset vector
        .word RESET     ; IRQ/BRK vector 