intro_screen_data:
.byte $e2, $20, $29, $28, $2b, $2d, $1e, $1d, $00                       ; Ported 
.byte $1b, $32, $00                                                     ; by 
.byte $2b, $2e, $26, $1b, $25, $1e, $26, $22, $27, $33, $1e, $00        ; Rumbleminze, 
.byte $12, $10, $12, $14, $ff                                           ; 2024

; MSU1 Arrangements By Batty
.byte $82, $22, $26, $2c, $2e, $11, $34
.byte $1a, $2b, $2b, $1a, $27, $20, $1e, $26, $1e, $27, $2d, $2c, $34
.byte $1b, $32, $34
.byte $1b, $1a, $2d, $2d, $32, $ff

.byte $e1, $22, $12, $1a, $10, $13, $00                                 ; 2A03
.byte $2c, $28, $2e, $27, $1d, $00                                      ; SOUND 
.byte $1e, $26, $2e, $25, $1a, $2d, $28, $2b, $00                       ; EMULATOR
.byte $1b, $32, $00                                                     ; BY
.byte $26, $1e, $26, $1b, $25, $1e, $2b, $2c, $ff                       ; MEMBLERS

.byte $78, $23, $2b, $1e, $2f, $10, $ff ; Version (REV0)
.byte $ff, $ff

write_intro_palette:
    STZ CGADD    
    LDA #$00
    STA CGDATA
    STA CGDATA

    LDA #$FF
    STA CGDATA
    STA CGDATA

    LDA #$B5
    STA CGDATA
    LDA #$56
    STA CGDATA
    
    LDA #$29
    STA CGDATA
    LDA #$25
    STA CGDATA

; sprite default colors
    LDA #$80
    STA CGADD
    LDA #$D0
    STA CGDATA
    LDA #$00
    STA CGDATA
    
    LDA #$b5
    STA CGDATA
    LDA #$56
    STA CGDATA

    LDA #$d0
    STA CGDATA
    LDA #$00
    STA CGDATA
    
    LDA #$00
    STA CGDATA
    LDA #$00
    STA CGDATA

    
    LDA #$90
    STA CGADD
    LDA #$D0
    STA CGDATA
    LDA #$00
    STA CGDATA
    
    LDA #$00
    STA CGDATA
    LDA #$00
    STA CGDATA

    LDA #$d6
    STA CGDATA
    LDA #$10
    STA CGDATA
    
    LDA #$41
    STA CGDATA
    LDA #$02
    STA CGDATA

    
    LDA #$A0
    STA CGADD
    LDA #$D0
    STA CGDATA
    LDA #$00
    STA CGDATA
    
    LDA #$00
    STA CGDATA
    LDA #$00
    STA CGDATA

    LDA #$33
    STA CGDATA
    LDA #$01
    STA CGDATA

    LDA #$D0
    STA CGDATA
    LDA #$00
    STA CGDATA

    
    LDA #$B0
    STA CGADD
    LDA #$D0
    STA CGDATA
    LDA #$00
    STA CGDATA
    
    LDA #$33
    STA CGDATA
    LDA #$01
    STA CGDATA

    LDA #$33
    STA CGDATA
    LDA #$01
    STA CGDATA
    
    LDA #$6a
    STA CGDATA
    LDA #$00
    STA CGDATA

    RTS

write_intro_tiles:
    LDY #$00

next_line:
    ; get starting address
    LDA intro_screen_data, Y
    CMP #$FF
    BEQ exit_intro_write

    PHA
    INY    
    LDA intro_screen_data, Y
    STA VMADDH
    PLA
    STA VMADDL
    INY

next_tile:
    LDA intro_screen_data, Y
    INY

    CMP #$FF
    BEQ next_line

    STA VMDATAL
    BRA next_tile

exit_intro_write:
    RTS

do_intro:
  JSR clearvm_to_12
  jsr zero_oam
      JSR dma_oam_table

    JSR load_intro_tilesets
    JSR write_intro_palette
    JSR write_default_palettes
    JSR write_intro_tiles
    ; JSR write_intro_sprites

    jsr check_for_msu

    LDA #$0F
    STA INIDISP
    LDX #$FF

:
    jsl augment_input
    jsr check_for_sprite_swap

    ; check for "start"
    LDA JOYTRIGGER1
    AND #$10
    BNE :+

    LDA JOYTRIGGER1
    AND #$20
    BEQ :-
    LDA MSU_AVAILABLE
    BEQ :-
        jsr show_msu_track_screen
        jmp do_intro
    BRA :-

:
    LDA INIDISP_STATE
    ORA #$8F
    STA INIDISP_STATE
    STA INIDISP

    RTS




sprite_swap_table:
;      oamo    m?  OAM1/2
.byte $00, $80, $00  ; roper, 80 offset, oam 1
.byte $00, $00, $01  ; linda, OBSEL + 0, 1
; .byte $00, $80, $01  ; abobo
; .byte $01, $01, $01  ; Burnov
; .byte $01, $00, $01  ; Shadow
.byte $02, $00, $01  ; Chin
.byte $02, $80, $01  ; william
.byte $03, $00, $01  ; Right Hand
.byte $03, $80, $01  ; Ninja
sprite_swap_table_end:

CURR_ENEMY_INDEX = $00
NUM_ENEMIES = 16 ; ((sprite_swap_table_end - sprite_swap_table)/3)
; NUM_ENEMIES = 4

: rts
check_for_sprite_swap:

    LDA JOYTRIGGER1
    AND #$20
    CMP #$20
    BNE :-

    LDA CURRENT_ENEMY_LOADED
    INC
    CMP #NUM_ENEMIES
    BNE :+    
    LDA #$00
:
    jsl load_enemy_sprites
;     ASL a
;     CLC
;     ADC CURR_ENEMY_INDEX
;     TAY
;     LDA sprite_swap_table, Y

;     ASL
;     ASL
;     ASL
;     ORA #%0000010
;     STA OBSEL

    INY
    PHY
    LDA CURRENT_ENEMY_TILE_OFFSET
    BEQ :++
        LDY #$00
        LDX #$0A
      : LDA SNES_OAM_START + 2, Y
        ORA #$80
        STA SNES_OAM_START + 2, Y

        INY
        INY
        INY
        INY
        DEX 
        BNE :-
        BRA :+++

    :   LDY #$00
        LDX #$0A
      : LDA SNES_OAM_START + 2, Y
        AND #$7F
        STA SNES_OAM_START + 2, Y

        INY
        INY
        INY
        INY
        DEX 
        BNE :-
    : PLY

    INY
    LDA CURRENT_SPRITE_TABLE_OFFSET
    STA $02
    LDY #$00
    LDX #$0A
:   LDA SNES_OAM_START + 3, Y
    AND #$FE
    ORA $02
    STA SNES_OAM_START + 3, Y
    INY
    INY
    INY
    INY
    DEX
    BNE :-
    JSR dma_oam_table
    rts

check_for_msu:
    LDA MSU_AVAILABLE
    BEQ :++

    ; msu is available 
    LDY #$00

    ; get starting address
    LDA msu_info, Y
    PHA
    INY
    LDA msu_info, Y
    STA VMADDH
    PLA
    STA VMADDL
    INY

:
    LDA msu_info, Y
    INY

    CMP #$FF
    BEQ :+

    STA VMDATAL
    BRA :-

    :

    rts

msu_info:
    .addr $2321
    .byte $29, $2b, $1e, $2c, $2c, $34
    .byte $2c, $1e, $25, $1e, $1c, $2d, $34
    .byte $1f, $28, $2b, $34
    .byte $26, $2c, $2e, $11, $34
    .byte $28, $29, $2d, $22, $28, $27, $2c 
    .byte $FF

; if a sprite wants to be on the intro screen,
; can put the data here    
intro_sprite_info:
    ; x, y, sprite
    .byte $80, $40, $80, $00
    .byte $88, $40, $81, $00
    .byte $80, $48, $90, $00
    .byte $88, $48, $91, $00
    .byte $80, $50, $A0, $00
    .byte $88, $50, $A1, $00
    .byte $80, $58, $B0, $00
    .byte $88, $58, $B1, $00
    .byte $80, $60, $C0, $00
    .byte $88, $60, $C1, $00
    .byte $ff

write_intro_sprites:
    LDY #$00
    LDX #$0A

:   LDA intro_sprite_info, y
    STA SNES_OAM_START, y
    INY
    LDA intro_sprite_info, y
    STA SNES_OAM_START, y
    INY
    LDA intro_sprite_info, y
    STA SNES_OAM_START, y
    INY
    LDA intro_sprite_info, y
    STA SNES_OAM_START, y
    INY
    DEX
    BNE :-

    JSR dma_oam_table

    rts

; loads up the tileset that has the tiles for the intro
load_intro_tilesets:
    lda #$00
    sta NMITIMEN
    LDA VMAIN_STATE
    AND #$0F
    STA VMAIN
    LDA #$8F
    STA INIDISP
    STA INIDISP_STATE

    ; load index 20 bank into both sets of tiles
    ; 20 is our custom intro screen tiles
    LDA #$20
    STA CHR_BANK_BANK_TO_LOAD
    LDA #$01
    STA CHR_BANK_TARGET_BANK
    JSL load_chr_table_to_vm

    LDA #SPRITE_INDEX_PLAYER
    STA CHR_BANK_BANK_TO_LOAD
    STZ CHR_BANK_TARGET_BANK
    jsl load_mmc3_bank_to_slot

    LDA #$01
    STA CHR_BANK_TARGET_BANK    
    LDA #SPRITE_INDEX_MISC
    jsl load_mmc3_bank_to_slot


    LDA #$02
    STA CHR_BANK_TARGET_BANK
    LDA #SPRITE_INDEX_ROPER_B
    jsl load_mmc3_bank_to_slot

    LDA #$03
    STA CHR_BANK_TARGET_BANK
    LDA #SPRITE_INDEX_LINDA
    jsl load_mmc3_bank_to_slot
    
    LDA #$04
    STA CHR_BANK_TARGET_BANK
    LDA #SPRITE_INDEX_WILLIAM
    jsl load_mmc3_bank_to_slot
    
    LDA #$05
    STA CHR_BANK_TARGET_BANK
    LDA #SPRITE_INDEX_RIGHT_HAND
    jsl load_mmc3_bank_to_slot
    
    LDA #$06
    STA CHR_BANK_TARGET_BANK
    LDA #SPRITE_INDEX_CHIN
    jsl load_mmc3_bank_to_slot
    
    LDA #$07
    STA CHR_BANK_TARGET_BANK
    LDA #SPRITE_INDEX_ABOBO
    jsl load_mmc3_bank_to_slot

    LDA #$08
    STA CHR_BANK_TARGET_BANK
    LDA #SPRITE_INDEX_ABORE
    jsl load_mmc3_bank_to_slot

    LDA #$09
    STA CHR_BANK_TARGET_BANK
    LDA #SPRITE_INDEX_BURNOV
    jsl load_mmc3_bank_to_slot


    rts

.include "msu_track_selection_screen.asm"