nsf_track_lookup:
.byte $00, $01, $0e, $03, $08, $0a, $02, $0f, $10, $04, $09, $07, $06, $05, $0d, $0c
.byte $11, $13, $14, $12

P0 = $00
P1 = $04
P2 = $08
P3 = $0C
P4 = $10
P5 = $14
P6 = $18
P7 = $1C
FIRST_OPTION  = $77
SECOND_OPTION = $B7 
NEEDS_OAM_DMA = $11
CURR_OPTION = $10

show_msu_track_screen:

    LDX #$20
    LDA RDNMI
    : LDA RDNMI
    BPL :-
    DEX
    BPL :-
    
    JSR write_option_palette

    LDA #$00
    STA CURR_OPTION

    LDA VMAIN_STATE
    AND #$0F
    STA VMAIN
    LDA #$80
    STA INIDISP

    JSR clearvm
    jsr write_heart_sprite
    jsr clear_sprites
    ; jsr dma_oam_table

    LDA #$00
    STA CHR_BANK_BANK_TO_LOAD
    LDA #$00
    STA CHR_BANK_TARGET_BANK
    JSL load_chr_table_to_vm

    LDA #$20
    STA CHR_BANK_BANK_TO_LOAD
    LDA #$01
    STA CHR_BANK_TARGET_BANK
    JSL load_chr_table_to_vm

    jsr write_msu_option_tiles
    
    JSR load_msu_options_sprites
    JSR dma_oam_table

    LDY #$00
    LDA nsf_track_lookup, Y

    jslb msu_check, $b2

    LDA #$0F
    STA INIDISP

@input_loop:
    LDA RDNMI
    BPL :+
    
    jslb msu_nmi_check, $b2
    LDA NEEDS_OAM_DMA
    BEQ :+
    JSR dma_oam_table
    STZ NEEDS_OAM_DMA
:   
    jsr read_input
    LDA JOYTRIGGER1

    CMP #RIGHT_BUTTON
    BNE :+
        jsr toggle_current_msu_option
        jsr play_current_option_msu_if_enabled
        bra @input_loop
    :
    CMP #LEFT_BUTTON
    BNE :+
        jsr toggle_current_msu_option
        jsr play_current_option_msu_if_enabled
        bra @input_loop
    :
    CMP #DOWN_BUTTON
    BNE :+        
        jsr @next_option     
        jsr play_current_option_msu_if_enabled
        BRA @input_loop
    :

    CMP #UP_BUTTON
    BNE :+
        jsr @prev_option
        jsr play_current_option_msu_if_enabled
        bra @input_loop
    :

    CMP #SELECT_BUTTON
    BEQ @exit_options
    BRA @input_loop

@exit_options:
    jsr zero_oam
    jslb stop_msu_only, $b2
    rts


@next_option:
    INC CURR_OPTION
    LDA CURR_OPTION
    CMP #(NUM_MSU_OPTIONS + 1)
    BNE :+
    STZ CURR_OPTION
:   jsr update_msu_option_pos
    rts

@prev_option:
    DEC CURR_OPTION
    BPL :+
    LDA #NUM_MSU_OPTIONS
    STA CURR_OPTION
:   jsr update_msu_option_pos
    rts



update_msu_option_pos:
    LDA CURR_OPTION
    ASL
    ASL
    ASL
    CLC
    ADC #$0e
    
    STA SNES_OAM_START + 1
    LDA #$01
    sta NEEDS_OAM_DMA
    rts


play_current_option_msu_if_enabled:
    LDA CURR_OPTION
    TAY
    LDA TRACKS_ENABLED-1, Y
    BEQ :+
    LDA nsf_track_lookup, Y
    jslb msu_check, $B2
    bra :++
:   jslb stop_msu_only, $b2   
:
    RTS


toggle_current_msu_option:
    LDA CURR_OPTION
    BEQ toggle_msu_1
    DEC A
    TAY    
    LDA #$01
    EOR TRACKS_ENABLED, Y
    STA TRACKS_ENABLED, Y
    jsr update_msu_track_enabled_pos
    rts

toggle_msu_1:
    LDA MSU_SELECTED
    EOR #$01
    STA MSU_SELECTED
    LDA MSU_SELECTED
    BNE :+
        LDA #SECOND_OPTION
        bra :++
    :   LDA #FIRST_OPTION
    :
    STA SNES_OAM_START + 4
    LDA #$01
    sta NEEDS_OAM_DMA
    rts

update_msu_track_enabled_pos:
    LDA CURR_OPTION
    DEC
    TAY
    LDA TRACKS_ENABLED,y
    BNE :+
        LDA #SECOND_OPTION
        bra :++
    :   LDA #FIRST_OPTION
    : PHA
    
    LDA CURR_OPTION
    INC A
    ASL
    ASL
    TAY
    PLA
    STA SNES_OAM_START, Y

    LDA #$01
    sta NEEDS_OAM_DMA
    rts

write_msu_option_tiles:
    setXY16
    LDY #$0000

next_msu_option_bg_line:
    ; get starting address
    LDA msu_option_tiles, Y
    CMP #$FF
    BEQ exit_msu_options_write

    PHA
    INY    
    LDA msu_option_tiles, Y
    STA VMADDH
    PLA
    STA VMADDL
    INY
    LDA msu_option_tiles, Y
    TAX
    INY

:   LDA msu_option_tiles, Y
    STA VMDATAH
    INY
    LDA msu_option_tiles, Y
    STA VMDATAL
    INY
    DEX
    BEQ next_msu_option_bg_line
    BRA :-

exit_msu_options_write:
    setAXY8
    RTS


load_msu_options_sprites:
    LDY #$00
:   LDA msu_options_sprites, Y
    CMP #$FF
    BEQ :+
    STA SNES_OAM_START, Y
    INY
    BRA :-
:
    rts

; :   
;     LDA MSU_UNAVAILABLE
;     BEQ :+
;         STZ MSU_SELECTED
;         LDA #SECOND_OPTION
;         STA MSU_OPTION
;         jsr disable_msu_option
    RTS

option_name_start = $2062
option1_start = $2070
option2_start = $2078
msu_option_tiles:
.byte $2B, $20, $0E, P6, $26, P6, $2c, P6, $2e, P6, $36, P6, $11, P6, $34, P6, $28, P6, $29, P6, $2d, P6, $22, P6, $28, P6, $27, P6, $2C, P6, $36    ; Options-

.word option_name_start + ($20 * -1)
.byte $05, P6, $26, P6, $2c, P6, $2e, P6, $36, P6, $11                                              ; msu1
.word option1_start + ($20 * -1)
.byte $03, P6, $32, P6, $1E, P6, $2C                                                                ; YES
.word option2_start + ($20 * -1)
.byte $02, P6, $27, P6, $28     

.word option_name_start + ($20 * 0)
.byte $05, P6, $2d, P6, $22, P6, $2d, P6, $25, P6, $1e                                              ; Title
.word option1_start + ($20 * 0)
.byte $03, P6, $32, P6, $1E, P6, $2C                                                                ; YES
.word option2_start + ($20 * 0)
.byte $02, P6, $27, P6, $28                                                                         ; NO
                  
.word option_name_start + ($20 * 1)
.byte $0A, P6, $25, P6, $1e, P6, $2f, P6, $1e, P6, $25, P6, $34, P6, $25, P6, $28, P6, $1a, P6, $1d                                  ; Level Load
.word option1_start + ($20 * 1)
.byte $03, P6, $32, P6, $1E, P6, $2C                                                                ; YES
.word option2_start + ($20 * 1)
.byte $02, P6, $27, P6, $28                                                                         ; NO
                  
.word option_name_start + ($20 * 2)
.byte $07, P6, $25, P6, $1e, P6, $2f, P6, $1e, P6, $25, P6, $34, P6, $11                                     ; LEVEL 1
.word option1_start + ($20 * 2)
.byte $03, P6, $32, P6, $1E, P6, $2C                                                                ; YES
.word option2_start + ($20 * 2)
.byte $02, P6, $27, P6, $28                                                                         ; NO
                  
.word option_name_start + ($20 * 3)
.byte $04, P6, $1b, P6, $28, P6, $2c, P6, $2c                                   ; Boss
.word option1_start + ($20 * 3)
.byte $03, P6, $32, P6, $1E, P6, $2C                                                                ; YES
.word option2_start + ($20 * 3)
.byte $02, P6, $27, P6, $28                                                                         ; NO
                  
.word option_name_start + ($20 * 4)
.byte $09, P6, $2c, P6, $2d, P6, $1a, P6, $20, P6, $1e, P6, $34, P6, $1e, P6, $27, P6, $1d                                   ; Stage End
.word option1_start + ($20 * 4)
.byte $03, P6, $32, P6, $1E, P6, $2C                                                                ; YES
.word option2_start + ($20 * 4)
.byte $02, P6, $27, P6, $28                                                                         ; NO
                  
.word option_name_start + ($20 * 5)
.byte $07, P6, $25, P6, $1e, P6, $2f, P6, $1e, P6, $25, P6, $34, P6, $12                                    ; Level 2
.word option1_start + ($20 * 5)
.byte $03, P6, $32, P6, $1E, P6, $2C                                                                ; YES
.word option2_start + ($20 * 5)
.byte $02, P6, $27, P6, $28                                                                         ; NO
                  
.word option_name_start + ($20 * 6)
.byte $07, P6, $25, P6, $1e, P6, $2f, P6, $1e, P6, $25, P6, $34, P6, $13                                      ; level 3
.word option1_start + ($20 * 6)
.byte $03, P6, $32, P6, $1E, P6, $2C                                                                ; YES
.word option2_start + ($20 * 6)
.byte $02, P6, $27, P6, $28                                                                         ; NO
                  
.word option_name_start + ($20 * 7)
.byte $07, P6, $25, P6, $1e, P6, $2f, P6, $1e, P6, $25, P6, $34, P6, $14                                      ; level 4                                   ; Area 7 
.word option1_start + ($20 * 7)
.byte $03, P6, $32, P6, $1E, P6, $2C                                                                ; YES
.word option2_start + ($20 * 7)
.byte $02, P6, $27, P6, $28                                                                         ; NO
                  
.word option_name_start + ($20 * 8)
.byte $07, P6, $25, P6, $1e, P6, $2f, P6, $1e, P6, $25, P6, $34, P6, $15                                      ; level 5                                     ; Area 8
.word option1_start + ($20 * 8)
.byte $03, P6, $32, P6, $1E, P6, $2C                                                                ; YES
.word option2_start + ($20 * 8)
.byte $02, P6, $27, P6, $28                                                                         ; NO
   
.word option_name_start + ($20 * 9)
.byte $0C, P6, $25, P6, $1e, P6, $2f, P6, $1e, P6, $25, P6, $34, P6, $15, P6, $34, P6, $1b, P6, $28, P6, $2c, P6, $2c                        ; Level 5 Boss
.word option1_start + ($20 * 9)
.byte $03, P6, $32, P6, $1E, P6, $2C                                                                ; YES
.word option2_start + ($20 * 9)
.byte $02, P6, $27, P6, $28                                                                         ; NO
                  
.word option_name_start + ($20 * 10)
.byte $07, P6, $25, P6, $1e, P6, $2f, P6, $1e, P6, $25, P6, $34, P6, $16                                     ; Level 6
.word option1_start + ($20 * 10)
.byte $03, P6, $32, P6, $1E, P6, $2C                                                                ; YES
.word option2_start + ($20 * 10)
.byte $02, P6, $27, P6, $28                                                                         ; NO


.word option_name_start + ($20 * 11)
.byte $07, P6, $25, P6, $1e, P6, $2f, P6, $1e, P6, $25, P6, $34, P6, $17 ; Level 7
.word option1_start + ($20 * 11)
.byte $03, P6, $32, P6, $1E, P6, $2C                                                                ; YES
.word option2_start + ($20 * 11)
.byte $02, P6, $27, P6, $28                                                                         ; NO
               

.word option_name_start + ($20 * 12)
.byte $07, P6, $25, P6, $1e, P6, $2f, P6, $1e, P6, $25, P6, $34, P6, $18                                     ; Level 8
.word option1_start + ($20 * 12)
.byte $03, P6, $32, P6, $1E, P6, $2C                                                                ; YES
.word option2_start + ($20 * 12)
.byte $02, P6, $27, P6, $28                                                                         ; NO
                  
.word option_name_start + ($20 * 13)
.byte $06, P6, $2c, P6, $21, P6, $1a, P6, $1d, P6, $28, P6, $30          ; Shadow
.word option1_start + ($20 * 13)
.byte $03, P6, $32, P6, $1E, P6, $2C                                                                ; YES
.word option2_start + ($20 * 13)
.byte $02, P6, $27, P6, $28       ; NO

.word option_name_start + ($20 * 14)
.byte $0C, P6, $1f, P6, $22, P6, $27, P6, $1a, P6, $25, P6, $34, P6, $1b, P6, $28, P6, $2c, P6, $2c, P6, $34, P6, $11          ; Final Boss 1
.word option1_start + ($20 * 14)
.byte $03, P6, $32, P6, $1E, P6, $2C                                                                ; YES
.word option2_start + ($20 * 14)
.byte $02, P6, $27, P6, $28       ; NO
     
.word option_name_start + ($20 * 15)
.byte $0C, P6, $1f, P6, $22, P6, $27, P6, $1a, P6, $25, P6, $34, P6, $1b, P6, $28, P6, $2c, P6, $2c, P6, $34, P6, $12          ; Final Boss 2
.word option1_start + ($20 * 15)
.byte $03, P6, $32, P6, $1E, P6, $2C                                                                ; YES
.word option2_start + ($20 * 15)
.byte $02, P6, $27, P6, $28       ; NO  
     
.word option_name_start + ($20 * 16)
.byte $06, P6, $1e, P6, $27, P6, $1d, P6, $22, P6, $27, P6, $20          ; Ending
.word option1_start + ($20 * 16)
.byte $03, P6, $32, P6, $1E, P6, $2C                                                                ; YES
.word option2_start + ($20 * 16)
.byte $02, P6, $27, P6, $28       ; NO  

.word option_name_start + ($20 * 17)
.byte $07, P6, $1c, P6, $2b, P6, $1e, P6, $1d, P6, $22, P6, $2d, P6, $2c          ; Credits
.word option1_start + ($20 * 17)
.byte $03, P6, $32, P6, $1E, P6, $2C                                                                ; YES
.word option2_start + ($20 * 17)
.byte $02, P6, $27, P6, $28       ; NO  

.word option_name_start + ($20 * 18)
.byte $09, P6, $20, P6, $1a, P6, $26, P6, $1e, P6, $34, P6, $28, P6, $2f, P6, $1e, P6, $2b          ; game over
.word option1_start + ($20 * 18)
.byte $03, P6, $32, P6, $1E, P6, $2C                                                                ; YES
.word option2_start + ($20 * 18)
.byte $02, P6, $27, P6, $28       ; NO  

.addr $2324
.byte $14, P6, $29, P6, $2b, P6, $1e, P6, $2c, P6, $2c, P6, $34 ; PRESS 
.byte P6, $2c, P6, $1e, P6, $25, P6, $1e, P6, $1c, P6, $2d, P6, $34 ; SELECT
.byte P6, $2d, P6, $28, P6, $34, P6, $1e, P6, $31, P6, $22, P6, $2d ; TO EXIT                                                     
.byte $FF
; Track Option Graphics
; MSU - TRACK SELECTION
; TRACK      AVAILABLE      ON  OFF
; AREA1         x          >ON  OFF
; ....
; PRESS START TO RETURN TO OPTIONS

NUM_MSU_OPTIONS = 19
; X, Y, Tile, attributes

msu_options_sprites:
.byte $04, $0E, $00, $00   ; Option Selection
.byte $77, $0E, $00, $00   ; MSU-1
.byte $77, $16, $00, $00   ; 01
.byte $77, $1E, $00, $00   ; 02
.byte $77, $26, $00, $00   ; 03
.byte $77, $2E, $00, $00   ; 04
.byte $77, $36, $00, $00   ; 05
.byte $77, $3E, $00, $00   ; 06
.byte $77, $46, $00, $00   ; 07
.byte $77, $4E, $00, $00   ; 08
.byte $77, $56, $00, $00   ; 09
.byte $77, $5E, $00, $00   ; 0a
.byte $77, $66, $00, $00   ; 0b
.byte $77, $6E, $00, $00   ; 0c
.byte $77, $76, $00, $00   ; 0d
.byte $77, $7E, $00, $00   ; 0e
.byte $77, $86, $00, $00   ; 0f
.byte $77, $8E, $00, $00   ; 10
.byte $77, $96, $00, $00   ; 11
.byte $77, $9E, $00, $00   ; 12
.byte $77, $A6, $00, $00   ; 13
.byte $FF

clear_sprites:
    LDA #$F0
    LDY #$00
:   STA SNES_OAM_START+1, Y
    INY
    INY
    INY
    INY
    BNE :-
    rts


read_input:
    lda #$01
    STA JOYSER0
    STA buttons
    LSR A
    sta JOYSER0
@loop:
    lda JOYSER0
    lsr a
    rol buttons
    bcc @loop

    lda buttons
    ldy JOYPAD1
    sta JOYPAD1
    tya
    eor JOYPAD1
    and JOYPAD1
    sta JOYTRIGGER1
    beq :+ 

    tya
    and JOYPAD1
    sta JOYHELD1
:   rts


write_option_palette:
    LDA RDNMI
:   LDA RDNMI
    BPL :-

    LDA #$41
    STA CGADD
    LDX #$80
    LDY #$00

:   LDA palette_lookup, Y
    STA CGDATA
    INY
    DEX
    BNE :-

    LDX #$00
:   
    LDA sprite_palette_0, X
    asl
    TAY
    LDA palette_lookup, Y
    STA CGDATA

    INY
    LDA palette_lookup, Y
    STA CGDATA

    INX
    CPX #$03
    BNE :-

    RTS

write_heart_sprite:
    LDY #$00
    LDA #$40
    STA VMADDH
    STZ VMADDL
:   LDA heart_sprite, Y
    STA VMDATAH
    INY
    LDA heart_sprite, Y
    STA VMDATAL
    INY
    CPY #$20
    BNE :-
    rts

sprite_palette_0:
.byte $16, $28, $07

heart_sprite:
.byte $00, $00, $04, $6C, $62, $9E, $62, $9E, $02, $FE, $04, $7C, $08, $38, $10, $10
.byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
