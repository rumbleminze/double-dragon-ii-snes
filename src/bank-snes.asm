; bank 0 - this houses our init routine and setup stuff
.segment "PRGA0"
init_routine:
  PHK 
  PLB 
  BRA initialize_registers

initialize_registers:
  setAXY16
  setA8

  LDA #$8F
  STA INIDISP
  STA INIDISP_STATE
  STZ OBSEL
  STZ OAMADDL
  STZ OAMADDH
  STZ BGMODE  
  STZ MOSAIC  
  STZ BG1SC   
  STZ BG2SC   
  STZ BG3SC   
  STZ BG4SC   
  STZ BG12NBA 
  STZ BG34NBA 
  STZ BG1HOFS 
  STZ BG1HOFS
  STZ BG1VOFS
  STZ BG1VOFS
  STZ BG2HOFS
  STZ BG2HOFS
  STZ BG2VOFS
  STZ BG2VOFS
  STZ BG3HOFS
  STZ BG3HOFS
  STZ BG3VOFS
  STZ BG3VOFS
  STZ BG4HOFS
  STZ BG4HOFS
  STZ BG4VOFS
  STZ BG4VOFS

  LDA #$80
  STA VMAIN
  STZ VMADDL
  STZ VMADDH
  STZ M7SEL
  STZ M7A

  LDA #$01
  STA M7A
  STA MEMSEL
  STZ M7B
  STZ M7B
  STZ M7C
  STZ M7C
  STZ M7D
  STA M7D
  STZ M7X
  STZ M7X
  STZ M7Y
  STZ M7Y
  STZ CGADD
  STZ W12SEL
  STZ W34SEL
  STZ WOBJSEL
  STZ WH0
  STZ WH1     
  STZ WH2     
  STZ WH3     
  STZ WBGLOG  
  STZ WOBJLOG 
  STZ TM      
  STZ TS      
  STZ TMW     

  LDA #$30
  STA CGWSEL
  STZ CGADSUB

  ; STZ SETINI
  LDA #$00 
  ; LDA #$01 ; uncomment this to use auto-joypoll
  STA NMITIMEN
  STA NMITIMEN_STATE
  STZ VMAIN_STATE
  
  STZ SNES_OAM_TRANSLATE_NEEDED

  LDA #$FF
  STA WRIO   
  STZ WRMPYA 
  STZ WRMPYB 
  STZ WRDIVL 
  STZ WRDIVH 
  STZ WRDIVB 
  STZ HTIMEL 
  STZ HTIMEH 
  STZ VTIMEL 
  STZ VTIMEH 
  STZ MDMAEN 
  STZ HDMAEN 
  STZ MEMSEL 

  STZ EXTRA_VRAM_UPDATE
  STZ LEVEL_SELECT_INDEX
  
  setAXY8
  LDA #$00
  LDY #$0F
: STA ATTRIBUTE_DMA, Y
  DEY
  BNE :-

  LDY #$40
: DEY
  STA $0900, y
  BNE :-
  
  JSR clear_zp 
  JSR clear_buffers
  
  LDA #$20
  STA $00
  JSR clear_bg
  LDA #$24
  STA $00
  JSR clear_bg
  JSR clearvm
  LDA #$E0
  STA COLDATA
  LDA #$0F
  STA INIDISP_STATE

  JSR zero_oam  
  JSR dma_oam_table
  JSR zero_all_palette

  STA OBSEL
  LDA #$11
  STA BG12NBA
  LDA #$77
  STA BG34NBA
  LDA #$01
  STA BGMODE
  LDA #$22
  STA BG1SC
;   LDA #$32
;   STA BG2SC
;   LDA #$28
;   STA BG3SC
;   LDA #$7C
;   STA BG4SC
  LDA #$80
  STA OAMADDH
  LDA #$11
  STA TMW
  LDA #$02
  STA W12SEL
  STA WOBJSEL
  
  lda #%00010001
  STA TM
  LDA #$01
  STA MEMSEL
; Use #$04 to enable overscan if we can.
  LDA #$04
  LDA #$00
  STA SETINI


  lda #%0000010
  sta OBSEL

  STZ ATTR_NES_HAS_VALUES
  STZ ATTR_NES_VM_ADDR_HB
  STZ ATTR_NES_VM_ADDR_LB
  STZ ATTR_NES_VM_ATTR_START
  STZ ATTRIBUTE2_DMA
  STZ ATTRIBUTE_DMA
  LDA #$00
  ; LDA #$01 ; uncomment this to use auto-poll joypad
  STA NMITIMEN_STATE
  ; JSL upload_sound_emulator_to_spc
  
  jsl spc_init_dpcm
  jsl spc_init_driver
  jsr write_sound_wram_routines
    STZ MSU_SELECTED
  jslb check_if_msu_is_available, $b2
  LDA MSU_AVAILABLE
  beq :+
    LDA #$01
    STA MSU_SELECTED
    jslb check_for_all_tracks_present, $b2
  :
  JSR do_intro
  
intro_done:
  STZ TM      
  STZ TS      
  STZ TMW   
    LDA #$30
  STA CGWSEL
  STZ CGADSUB
  
  JSR setup_hide_left_8_pixel_window
  JSL disable_hide_left_8_pixel_window
  JSR clearvm_to_12
  JSR write_default_palettes
  LDA #$FF
  STA PALETTE_FILTER
  ; JSR write_stack_adjustment_routine_to_ram
  ; JSR write_sound_hijack_routine_to_ram
  LDA #$06
  STA ACTIVE_NES_BANK

  LDA #$02
  STA $4D

  LDA #$A7
  PHA
  PLB 
  JML $A7FF75


  snes_nmi:
    LDA RDNMI 

    ; jsr make_the_game_easier
    jslb update_values_for_ppu_mask, $a0
    jslb infidelitys_scroll_handling, $a0
    jslb calculate_hdma_l, $a0

    JSR check_and_copy_nes_attributes_to_buffer

    ; JSR dma_oam_table
    RTL
store_current_hdma_values:

    LDX #$1F
  : LDA SCROLL_HDMA_START, X
    STA SCROLL_HDMA_SAVED, X
    DEX
    BPL :-

    LDA #$7E
    STA A1B3
    LDA #$09
    STA A1T3H
    LDA #$20
    STA A1T3L
    
    LDA #<(BG1HOFS)
    STA BBAD3
    LDA #$03
    STA DMAP3

    LDA #%00001000
    STA HDMAEN
    rtl

make_the_game_easier:
  LDA $E0
  AND #$20
  beq :+
  STZ ENEMY_1_HEALTH
  STZ ENEMY_2_HEALTH  
  PHA
  LDA #$7F
  STA P1_HEALTH
  LDA #$09
  STA P1_LIVES
  PLA
  :
  rts

audio_interrupt_1:
    ; handle sound stuff, which the nes game does via IRQ
    LDA #$FF
    STA BANK_SWITCH_HB
    LDA #$09
    STA BANK_SWITCH_LB
    LDA ACTIVE_NES_BANK
    PHA
    AND #$0F
    INC
    ORA #$A0
    STA BANK_SWITCH_DB    
    PHA
    PLB
    JML [BANK_SWITCH_LB]

return_from_sound:
    rtl

clear_bg_jsl:
  LDA $00
  PHA
  LDA #$20
  STA $00
  jsr clear_bg
  LDA #$24
  STA $00
  jsr clear_bg
  PLA
  STA $00
  rtl
clear_bg:

  LDA #$80
  STA VMAIN

  ; fixed A value, increment B
  
  LDA #$09
  sta DMAP0
  
  LDA $00
  STA VMADDH
  STZ VMADDL

  LDA #$18
  STA BBAD0

  LDA #$A0
  STA A1B0

  LDA #>dma_values
  STA A1T0H
  LDA #<dma_values
  STA A1T0L

  LDA #$08
  STA DAS0H  
  STZ DAS0L

  LDA #$01
  STA MDMAEN

  LDA VMAIN_STATE
  STA VMAIN
  RTS


clearvm_jsl:
  jsr clearvm
  rtl
clearvm:
  LDA #$80
  STA VMAIN

  ; fixed A value, increment B
  setAXY16

  LDA #$0009
  sta DMAP0

  LDA #$0000
  STZ VMADDL

  LDA #$18
  STA BBAD0

  LDA #$A0
  STA A1B0

  setAXY8
  LDA #>dma_values
  STA A1T0H
  LDA #<dma_values
  STA A1T0L
  setAXY16

  STZ DAS0L

  LDA #$0001
  STA MDMAEN

  setAXY8
  LDA VMAIN_STATE
  STA VMAIN
  RTS

clearvm_to_12_long:
  JSR clearvm_to_12
  RTL

clearvm_to_12:

: LDA RDNMI
  BPL :-

  LDA #$00
  STA NMITIMEN
  jslb force_blank_no_store, $a0 
  setAXY16
  ldx #$2000
  stx VMADDL 
	
	lda #$0000
	
	LDY #$0000
	:
		sta VMDATAL
		iny
		CPY #(32*64)
		BNE :-
  
  setAXY8
  jslb reset_inidisp, $a0 

  RTS

clear_zp:
  LDA #$00
  LDY #$00

: STA $00, Y
  INY
  BNE :-
  RTS

clear_buffers:
  LDA #$00
  LDY #$00
  LDX #$FF

: LDA #$00
  STA $0800, Y
  STA $0900, Y
  STA $0A00, Y
  STA $0B00, Y
  STA $0C00, Y
  STA $0D00, Y
  STA $0E00, Y
  STA $0F00, Y
  
  STA $1000, Y
  STA $1100, Y
  STA $1200, Y
  STA $1300, Y
  STA $1400, Y
  STA $1500, Y
  STA $1600, Y
  STA $1700, Y
  
  STA $1800, Y
  STA $1900, Y
  STA $1A00, Y
  STA $1B00, Y
  STA $1C00, Y
  STA $1D00, Y
  STA $1E00, Y
  STA $1F00, Y

  LDA #$FF
  STA $6500, y
  STA $6600, y
  DEY
  BNE :-
  RTS

msu_movie_rti:
  REP #$30
  PLY
  PLX
  PLA
  SEP #$30
  PLP
  RTI



dma_values:
  .byte $00, $12

.if ENABLE_MSU = 1
  .include "msu_intro_screen.asm"
.endif

.if ENABLE_MSU = 0
  .include "intro_screen.asm"
.endif
  .include "scrolling.asm"
  .include "attributes.asm"
  .include "hdma_scroll_lookups.asm"
  .include "2a03_conversion.asm"
  .include "audio.asm"
  .include "windows.asm"
  .include "input.asm"
  .include "konamicode.asm"
  .include "palette_updates.asm"
  .include "palette_lookup.asm"
  .include "sprites.asm"
  .include "tiles.asm"
  .include "hardware-status-switches.asm"


write_sound_wram_routines:
LDY #$00
:
LDA wram_routines, Y
STA $1C00, Y
LDA wram_routines + $100, Y
STA $1D00, Y
LDA wram_routines + $200, Y
STA $1E00, Y
LDA wram_routines + $300, Y
STA $1F00, Y

INY
BNE :-
RTS

wram_routines:
.incbin "wram_routines.bin"

.segment "PRGA0C"
fixeda0:
.include "bank7.asm"
fixeda0_end: