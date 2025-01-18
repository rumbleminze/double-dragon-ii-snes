augment_input:

    ; origingal code
    LDX $e5
    INX
    STX JOYSER0
    DEX
    STX JOYSER0
    LDX #$08
:   LDA JOYSER0
    LSR
    ROL $e0
    LSR
    ROL $04
    LDA JOYSER1
    LSR
    ROL $e1
    LSR
    ROL $05
    DEX
    BNE :-
    ; we also ready the next bit, which is the SNES "A" button
    ; and if it's on, treat it as if they've hit both Y and B
    lda JOYSER0
    AND #$01
    BEQ :+
    LDA $04
    ORA #$C0
    STA $04

:   lda JOYSER1
    AND #$01
    BEQ :+
    LDA $05
    ORA #$C0
    STA $05

    ; X
    ; lda JOYSER0
    ; lda JOYSER0
    ; AND #$01
    ; BEQ :+
    

    ; this checks for the komani code by looking at where the game stores input.
 :   
    jsr check_for_code_input_from_ram_values

    RTL