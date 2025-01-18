totals_audio:

SoundEmulateLengthCounters:
    setAXY8
    lda $0A15
    ora #$04
    tay

    bit #$01
    beq sq1

    lda $0A00
    and #$20
    bne :++
    ldx APUSq0Length
    bne :+
    tya
    and #$fe
    tay
    bra sq1
:
    dex
    stx APUSq0Length
:
    tya

sq1:
    bit #$02
    beq noise

    lda $0A04
    and #$20
    bne :++
    ldx APUSq1Length
    bne :+
    tya
    and #$fd
    tay
    bra sq1
:
    dex
    stx APUSq1Length
:
    tya

noise:
    bit #$08
    beq tri

    lda $0A0c
    and #$20
    bne :++
    ldx APUNoiLength
    bne :+
    tya
    and #$f7
    tay
    bra sq1
:
    dex
    stx APUNoiLength
:
    tya

tri:
    ldx $0A08
    bpl :++

    ldx APUTriLength
    bne :+
    and #$fb
    bra end
:
    dex
    stx APUTriLength
:
end:
    sta $0A15
    rts

SnesUpdateAudio:
    PHX
    PHY
    PHA
    PHP
    setAXY8

    ; This isn't great but fixes some SFX
    ; but makes the triangle channel never stop
    ; LDA $A08
    ; ORA #$80
    ; STA $A08

    JSR SoundEmulateLengthCounters

    LDA $A15
    BNE :++
    ; Silence everything
    LDX #$00
:
    STZ $A00, x
    INX
    CPX #$17
    BNE :-
:
    LDA $2140
    CMP #$7D
    BEQ :+
    JMP End
:
    
    LDA #$D7
    STA $2140

:
    LDA $2140
    CMP #$D7
    BNE :-

    LDX #$00

:
    LDA $0A00, X
    STA $2141
    STX $2140

    INX

:   CPX $2141
    BNE :-

    CPX #$17
    BNE :--

    ; LDA #$0F
    ; STA $A15

    stz $0A16

End:
    PLP
    PLA
    PLY
    PLX
    RTL


store_a_to_register_y:
  PHA
    TYA
    AND #$0F
    TAY
  PLA
  CPY #$00
  bne :+
  jsr WriteAPUSq0Ctrl0
  rtl

: CPY #$01
  bne :+
  jsr WriteAPUSq0Ctrl1
  rtl   

: CPY #$02
  bne :+
  jsr WriteAPUSq0Ctrl2
  rtl

: CPY #$03
  bne :+
  jsr WriteAPUSq0Ctrl3
  rtl

: CPY #$04
  bne :+
  jsr WriteAPUSq1Ctrl0
  rtl

: CPY #$05
  bne :+
  jsr WriteAPUSq1Ctrl1
  rtl   

: CPY #$06
  bne :+
  jsr WriteAPUSq1Ctrl2
  rtl

: CPY #$07
  bne :+
  jsr WriteAPUSq1Ctrl3
  rtl

: CPY #$08
  bne :+
  jsr WriteAPUTriCtrl0
  rtl

: CPY #$09
  bne :+
  jsr WriteAPUTriCtrl1
  rtl   

: CPY #$0A
  bne :+
  jsr WriteAPUTriCtrl2
  rtl

: CPY #$0B
  bne :+
  jsr WriteAPUTriCtrl3
  rtl

: CPY #$0C
  bne :+
  jsr WriteAPUNoiseCtrl0
  rtl

: CPY #$0D
  bne :+
  jsr WriteAPUNoiseCtrl1
  rtl   

: CPY #$0E
  bne :+
  jsr WriteAPUNoiseCtrl2
  rtl
  
: CPY #$0F
  bne :+
  jsr WriteAPUNoiseCtrl3
  rtl 
: BRK
  rtl

convert_audio:
  jslb SnesUpdateAudio, $a0
  STZ $2142
  rtl 
