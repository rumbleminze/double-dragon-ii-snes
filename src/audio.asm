mute_apu_control:
  LDA #$00
  jsr WriteAPUControl
  jslb SnesUpdateAudio, $a0
  jslb disable_nmi_no_store, $a0
  LDA RDNMI
: LDA RDNMI 
  BPL :-
  LDA RDNMI
  jslb enable_nmi, $a0

  LDA #$00
  rtl

play_audio_track:    
    STA $07FF
    bne :+
        jsr stop_2a03_audio
    :

    ; check for MSU-1

            ; ; is this a brr?
            ; CMP #$1E
            ; bra :+

            ; STZ $07FF
            ; LDX #$00
            ; jsr WriteAPUDMCCounter

            ; LDA #$0f
            ; jsr WriteAPUDMCFreq

            ; LDA #$1E
            ; jsr WriteAPUDMCAddr

            ; LDA #$0A
            ; jsr WriteAPUDMCLength

            ; LDA #$0f
            ; ; STA $4015

            ; LDA #$1f
            ; jsr WriteAPUDMCPlay

            ; PLA
            ; PLA
            ; PLA
            ; PLA
            ; LDA #$32
            ; PHA
            ; LDA #$A3
            ; PHA
            ; LDA #$FF
            ; PHA
            ; LDA #$4E
            ; PHA
    rtl
    ; funge the stack to skip the playing of the audio
    ; the stack should look like
    ; $4E $FF $A3 $22 $FC
    ; since we jsl'd from a3ff4e, and prior to that jsr'd from fc22
    ;
    ; we want to return to fc32 to skip over the audio portion


:   
    LDA $07FF
    rtl

stop_2a03_audio:
    PHA
    PHX
    PHY

    
  LDA #$00  
  
  LDX #$17
: DEX
  STA SOUND_EMULATOR_BUFFER_START, X
  BNE :-
    jslb SnesUpdateAudio, $a0
    PLY
    PLX
    PLA
    rts

brr_samples:
.byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
.byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $01, $00
.byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
.byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
.byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
.byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
.byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
.byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
.byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
.byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
.byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
.byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
.byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
.byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
.byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
.byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00