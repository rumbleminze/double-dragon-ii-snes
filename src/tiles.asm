; This is used for bankswapping CHR Rom banks quickly by putting various banks
; at places in VRAM and changing where the BG tiles are loaded from
bankswap_table:
.byte .lobyte(chrom_bank_0_tileset_0),  .hibyte(chrom_bank_0_tileset_0), $A8
.byte .lobyte(chrom_bank_0_tileset_1),  .hibyte(chrom_bank_0_tileset_1), $A8
.byte .lobyte(chrom_bank_0_tileset_2),  .hibyte(chrom_bank_0_tileset_2), $A8
.byte .lobyte(chrom_bank_0_tileset_3),  .hibyte(chrom_bank_0_tileset_3), $A8

.byte .lobyte(chrom_bank_1_tileset_4),  .hibyte(chrom_bank_1_tileset_4), $A9
.byte .lobyte(chrom_bank_1_tileset_5),  .hibyte(chrom_bank_1_tileset_5), $A9
.byte .lobyte(chrom_bank_1_tileset_6),  .hibyte(chrom_bank_1_tileset_6), $A9
.byte .lobyte(chrom_bank_1_tileset_7),  .hibyte(chrom_bank_1_tileset_7), $A9

.byte .lobyte(chrom_bank_2_tileset_8),  .hibyte(chrom_bank_2_tileset_8), $AA
.byte .lobyte(chrom_bank_2_tileset_9),  .hibyte(chrom_bank_2_tileset_9), $AA
.byte .lobyte(chrom_bank_2_tileset_10), .hibyte(chrom_bank_2_tileset_10), $AA
.byte .lobyte(chrom_bank_2_tileset_11), .hibyte(chrom_bank_2_tileset_11), $AA

.byte .lobyte(chrom_bank_3_tileset_12), .hibyte(chrom_bank_3_tileset_12), $AB
.byte .lobyte(chrom_bank_3_tileset_13), .hibyte(chrom_bank_3_tileset_13), $AB
.byte .lobyte(chrom_bank_3_tileset_14), .hibyte(chrom_bank_3_tileset_14), $AB
.byte .lobyte(chrom_bank_3_tileset_15), .hibyte(chrom_bank_3_tileset_15), $AB

.byte .lobyte(chrom_bank_4_tileset_16), .hibyte(chrom_bank_4_tileset_16), $AC
.byte .lobyte(chrom_bank_4_tileset_17), .hibyte(chrom_bank_4_tileset_17), $AC
.byte .lobyte(chrom_bank_4_tileset_18), .hibyte(chrom_bank_4_tileset_18), $AC
.byte .lobyte(chrom_bank_4_tileset_19), .hibyte(chrom_bank_4_tileset_19), $AC

.byte .lobyte(chrom_bank_5_tileset_20), .hibyte(chrom_bank_5_tileset_20), $AD
.byte .lobyte(chrom_bank_5_tileset_21), .hibyte(chrom_bank_5_tileset_21), $AD
.byte .lobyte(chrom_bank_5_tileset_22), .hibyte(chrom_bank_5_tileset_22), $AD
.byte .lobyte(chrom_bank_5_tileset_23), .hibyte(chrom_bank_5_tileset_23), $AD

.byte .lobyte(chrom_bank_6_tileset_24), .hibyte(chrom_bank_6_tileset_24), $AE
.byte .lobyte(chrom_bank_6_tileset_25), .hibyte(chrom_bank_6_tileset_25), $AE
.byte .lobyte(chrom_bank_6_tileset_26), .hibyte(chrom_bank_6_tileset_26), $AE
.byte .lobyte(chrom_bank_6_tileset_27), .hibyte(chrom_bank_6_tileset_27), $AE

.byte .lobyte(chrom_bank_7_tileset_28), .hibyte(chrom_bank_7_tileset_28), $AF
.byte .lobyte(chrom_bank_7_tileset_29), .hibyte(chrom_bank_7_tileset_29), $AF
.byte .lobyte(chrom_bank_7_tileset_30), .hibyte(chrom_bank_7_tileset_30), $AF
.byte .lobyte(chrom_bank_7_tileset_31), .hibyte(chrom_bank_7_tileset_31), $AF

; bank #$20, my basic intro tiles
.byte <(basic_intro_tiles), >(basic_intro_tiles), $B0

; banks of msu tiles for the video
.if ENABLE_MSU = 1
  .byte <(msu_intro_tiles_0), >(msu_intro_tiles_0), $B1
  .byte <(msu_intro_tiles_1), >(msu_intro_tiles_1), $B1
  .byte <(msu_intro_tiles_2), >(msu_intro_tiles_2), $B1
  .byte <(msu_intro_tiles_3), >(msu_intro_tiles_3), $B1
.endif

: RTL
check_for_chr_bankswap:

  LDA OBJ_CHR_BANK_SWITCH
  CMP #$FF
  BEQ :-
  CMP CHR_BANK_CURR_P1
  BEQ :-

  LDA OBJ_CHR_BANK_SWITCH
  STA CHR_BANK_CURR_P1
  ; LDA #$FF
  ; STA OBJ_CHR_BANK_SWITCH
  
  PHB
  LDA #$A0
  PHA
  PLB

  ; looks like we need to switch CHR Banks
  ; we fake this by DMA'ing tiles from the right tileset
  ; multiply by 3 to get the offset
  LDA CHR_BANK_CURR_P1
  ASL A
  ADC CHR_BANK_CURR_P1
  TAY

  LDA #$80
  STA VMAIN

  LDA #$01
  STA DMAP0

  LDA #$18
  STA BBAD0

  ; source LB
  LDA bankswap_table, Y
  STA A1T0L

  ; source HB
  INY
  LDA bankswap_table, y
  STA A1T0H

  ; source DB
  INY
  LDA bankswap_table, y
  STA A1B0

  ; 0x2000 bytes
  LDA #$20
  STA DAS0H
  STZ DAS0L

  ; page 1 is at $0000
  LDA #$00
  STZ VMADDH
  STZ VMADDL

  LDA #$01
  STA MDMAEN

  PLB

  LDA VMAIN_STATE
  STA VMAIN

: RTL


bg_lookup_table:
 ; 00

; we'll put the data at $1000 always
swap_data_bg_chr:
  LDA BG_CHR_BANK_SWITCH
  CMP DATA_CHR_BANK_CURR
  BEQ :-
  STA DATA_CHR_BANK_CURR
  JMP bankswap_start


check_for_bg_chr_bankswap:
  LDA BG_CHR_BANK_SWITCH
  CMP #$FF
  BEQ :-

;   CMP #$1A
;   BPL swap_data_bg_chr

  CMP BG_CHR_BANK_CURR
  BEQ :-


bankswap_start:
  LDA NMITIMEN_STATE
  AND #$7F
  STA NMITIMEN
  
  LDA INIDISP_STATE
  ORA #$80
  STA INIDISP

  ; LDA RDNMI
: LDA RDNMI
  AND #$80
  BEQ :-

  ; LDA #$80
  ; STA INIDISP
  ; STZ TM
  
  LDA BG_CHR_BANK_SWITCH
  STA BG_CHR_BANK_CURR
  ; LDA #$FF
  ; STA OBJ_CHR_BANK_SWITCH

  PHB
  PHK
  PLB

  stz TARGET_BANK_OFFSET
  sta BG_CHR_BANK_CURR
  jsr load_bg_chunk
  lda #$04
  sta TARGET_BANK_OFFSET
  inc BG_CHR_BANK_CURR
  jsr load_bg_chunk
  lda #$08
  sta TARGET_BANK_OFFSET
  inc BG_CHR_BANK_CURR
  jsr load_bg_chunk
  lda #$0C
  sta TARGET_BANK_OFFSET
  inc BG_CHR_BANK_CURR
  jsr load_bg_chunk

  PLB
  LDA VMAIN_STATE
  STA VMAIN

  LDA INIDISP_STATE
  STA INIDISP

  LDA NMITIMEN_STATE
  STA NMITIMEN

  ; LDA #$11
  ; STA TM
  ; LDA INIDISP_STATE
  ; STA INIDISP

  RTL

load_bg_chunk:
  ; looks like we need to switch CHR Banks
  ; we fake this by DMA'ing tiles from the right tileset
  ; multiply by 3 to get the offset
  ; LDA BG_CHR_BANK_CURR
  ; ASL A
  ; ADC BG_CHR_BANK_CURR
  ; TAY

  LDA #$80
  STA VMAIN

  LDA #$01
  STA DMAP1

  LDA #$18
  STA BBAD1

  ; source LB
  STZ A1T1L

  ; source HB
  LDA BG_CHR_BANK_CURR  
  PHA
  AND #$0f
  ASL
  ASL
  ASL
  CLC
  ADC #$80
  STA A1T1H

  ; source DB
  PLA  
  LSR
  LSR
  LSR
  LSR
  CLC
  ADC #$A8
  STA A1B1


  ; if the HB is at F0, then we need to only do 0x1000 bytes
  ; and we need to do another
  ; otherwise 0x2000 bytes
  LDA #$08
  STA DAS1H
  STZ DAS1L


  ; page 2 is at $1000 + , data bank will add 6000 to that
  LDA #$10
  CLC
  ADC TARGET_BANK_OFFSET
  STA VMADDH
  STZ VMADDL

  LDA #$02
  STA MDMAEN
  rts

bankswitch_bg_chr_data:
  PHB
  LDA #$A0
  PHA
  PLB

  ; bgs are on 1000, 3000, 5000, 7000.
  LDY #$01
: LDA CHR_BANK_LOADED_TABLE, y
  CMP CHR_BANK_BANK_TO_LOAD
  BEQ switch_bg_to_y
  CPY #$07
  BEQ new_bg_bank
  INY
  INY
  BRA :-
  RTL

new_bg_bank:

  LDA CHR_BANK_BANK_TO_LOAD
  
  CMP #$19
  BPL new_data_bank
  PLB
  RTL

switch_bg_to_y:
  TYA
  ORA #$10
  STA BG12NBA

  PLB
  RTL
new_data_bank:

  STZ CHR_BANK_TARGET_BANK
  INC CHR_BANK_TARGET_BANK
  jslb load_chr_table_to_vm, $a0

  PLB
  RTL

load_chr_table_to_vm:
  LDA CHR_BANK_TARGET_BANK
  TAY
  LDA CHR_BANK_BANK_TO_LOAD
  STA CHR_BANK_LOADED_TABLE, Y
  
  JSR dma_chr_to_vm

  RTL


; sprite tile location table
sprite_location_table:
.byte <player_sprite_tiles,           >player_sprite_tiles,           ^player_sprite_tiles            ; 40
.byte <roper_bolo_sprites,            >roper_bolo_sprites,            ^roper_bolo_sprites             ; 42
.byte <linda_sprites,                 >linda_sprites,                 ^linda_sprites                  ; 44
.byte <abobo_sprites,                 >abobo_sprites,                 ^abobo_sprites                  ; 46
.byte <burnov_sprites_1,              >burnov_sprites_1,              ^burnov_sprites_1               ; 48    
.byte <shadow_sprites,                >shadow_sprites,                ^shadow_sprites                 ; 4a  
.byte <chin_sprites,                  >chin_sprites,                  ^chin_sprites                   ; 4c
.byte <william_sprites,               >william_sprites,               ^william_sprites                ; 4e    
                    ; 
.byte <burnov_sprites_2,              >burnov_sprites_2,              ^burnov_sprites_2               ; 50      
.byte <abore_sprites,                 >abore_sprites,                 ^abore_sprites                  ; 52  
.byte <right_hand_sprites,            >right_hand_sprites,            ^right_hand_sprites             ; 54        
.byte <ninja_sprites,                 >ninja_sprites,                 ^ninja_sprites                  ; 56  
.byte <mysterious_warrior_sprites,    >mysterious_warrior_sprites,    ^mysterious_warrior_sprites     ; 58                
.byte <misc_sprites,                  >misc_sprites,                  ^misc_sprites                   ; 5A  
.byte <title_screen_1,                >title_screen_1,                ^title_screen_1                 ; 5C  
.byte <title_screen_2,                >title_screen_2,                ^title_screen_2                 ; 5E  
                    ; 
.byte <mysterious_warrior_sprites_2,  >mysterious_warrior_sprites_2,  ^mysterious_warrior_sprites_2   ; 60                  
.byte <burnov_sprites_3,              >burnov_sprites_3,              ^burnov_sprites_3               ; 62      
.byte <roper_grenade_sprites,         >roper_grenade_sprites,         ^roper_grenade_sprites          ; 64          

load_sprite_banks:
  PHB
  PHK
  PLB

  LDY #$00
  LDA SPRITE_LOADED_TABLE, Y
  CMP $0498
  BEQ second_half

  ; first half isn't correct, and we always load 498 to the first slot, because it's
  ; player sprites 99% of the time
  LDA $0498
  STA CHR_BANK_BANK_TO_LOAD
  STZ CHR_BANK_TARGET_BANK
  jslb load_mmc3_bank_to_slot, $a0
  
second_half:
  LDA $0499  
  CMP CURRENT_ENEMY_LOADED
  BEQ already_loaded

  STA CHR_BANK_BANK_TO_LOAD
  LDY #$00  

: INY
  CPY #$0A
  BEQ bank_not_found
  LDA SPRITE_LOADED_TABLE, Y
  CMP CHR_BANK_BANK_TO_LOAD
  BNE :-
found_sprite_bank_at_y:
  TYA
  STA ACTIVE_SPRITE_SECOND_BANK_SLOT
  jsr set_sprite_offsets_based_on_loaded_enemey
already_loaded:  
  PLB
  rtl



set_sprite_offsets_based_on_loaded_enemey:
  LDA $0499
  STA CURRENT_ENEMY_LOADED

  LDA ACTIVE_SPRITE_SECOND_BANK_SLOT  
  AND #$01
  BEQ :+
  LDA #$80
  BRA :++
: LDA #$00
: STA CURRENT_ENEMY_TILE_OFFSET

  STZ CURRENT_SPRITE_TABLE_OFFSET
  LDA ACTIVE_SPRITE_SECOND_BANK_SLOT
  LSR
  BNE :+
  ; this is on the first page, we don't need to both updating the OBSEL
  rts
: LDA #$01
  STA CURRENT_SPRITE_TABLE_OFFSET

  LDA ACTIVE_SPRITE_SECOND_BANK_SLOT
  TAY
  lda sprite_bank_to_table_offset, Y
  STA OBSEL
  
  rts
; set up 

bank_not_found:  
  ; oh noes!  eventually, we'll want to do this more optimatlly during level load or something
  ; for now look for an empty slot
  LDY #$00
: INY
  CPY #$0A
  BNE :+
  LDY #$01
  BRA load_to_y
:
  LDA SPRITE_LOADED_TABLE, Y
  BMI load_to_y
  BRA :--

load_to_y:
  TYA
  STA CHR_BANK_TARGET_BANK
  STA ACTIVE_SPRITE_SECOND_BANK_SLOT
  LDA CHR_BANK_BANK_TO_LOAD
  jslb load_mmc3_bank_to_slot, $a0
  jsr set_sprite_offsets_based_on_loaded_enemey
  PLB
  rtl

load_mmc3_bank_to_slot:
  PHB
  PHK
  PLB

  PHA
  
  STZ NMITIMEN

  LDA #$80
  STA VMAIN
  STA INIDISP

  LDA #$01
  STA DMAP1

  LDA #$18
  STA BBAD1

  ; source LB
  STZ A1T1L

  ; source HB
  PLA
  PHA
  AND #$0f
  ASL
  ASL
  ASL
  CLC
  ADC #$80
  STA A1T1H

  ; source DB
  PLA
  PHA
  LSR
  LSR
  LSR
  LSR
  CLC
  ADC #$A8
  STA A1B1

  ; 0x1000 bytes
  LDA #$10
  STA DAS1H
  STZ DAS1L

  LDA CHR_BANK_TARGET_BANK
  TAY

  ; save which enemy we've loaded to this slot
  PLA
  STA SPRITE_LOADED_TABLE, Y

  lda target_sprite_bank_table, Y  
  STA VMADDH
  STZ VMADDL

  LDA #$02
  STA MDMAEN
  PLB
  LDA VMAIN_STATE
  STA VMAIN
  LDA RDNMI
  LDA NMITIMEN_STATE
  STA NMITIMEN
  LDA INIDISP_STATE
  STA INIDISP
  rtl

; sprite constants
SPRITE_INDEX_PLAYER = $40
SPRITE_INDEX_ROPER_B = $42
SPRITE_INDEX_LINDA = $44
SPRITE_INDEX_ABOBO = $46
SPRITE_INDEX_BURNOV = $48
SPRITE_INDEX_SHADOW = $4A
SPRITE_INDEX_CHIN = $4C
SPRITE_INDEX_WILLIAM = $4E

SPRITE_INDEX_BURNOV2 = $50
SPRITE_INDEX_ABORE = $52
SPRITE_INDEX_RIGHT_HAND = $54
SPRITE_INDEX_NINJA = $56
SPRITE_INDEX_MYST_WARR = $58
SPRITE_INDEX_MISC = $5A

; SPRITE_INDEX_MYST_WARR2 = $5
; SPRITE_INDEX_BURNOV3 = 15
; SPRITE_INDEX_ROPER_G = 16

target_sprite_bank_table:
.byte $40, $48, $50, $58, $60, $68, $70, $78, $00, $08

; DMA's 2k (0x800) bytes from ROM to VM slot
; the VM slots we use are for sprites, and are from 0x4000 - 0x7FFF
; slot 0 = 0x4000
; slot 1 = 0x4800
; slot 2 = 0x5000
; slot 3 = 0x5800
; slot 4 = 0x6000
; slot 5 = 0x6800
; slot 6 = 0x7000
; slot 7 = 0x7800
; slot 8 = 0x0000
; slot 9 = 0x0800
dma_sprite_to_slot:
  PHB
  PHA
  PHY
  PHX
  PHK
  PLB

  ; holds the sprite we need to load tiles for
  LDA CHR_BANK_BANK_TO_LOAD
  ASL
  CLC
  ADC CHR_BANK_BANK_TO_LOAD
  TAY
  
  LDA #$80
  STA VMAIN

  LDA #$01
  STA DMAP1

  LDA #$18
  STA BBAD1

  ; source LB
  LDA sprite_location_table, Y
  STA A1T1L

  ; source HB
  INY
  LDA sprite_location_table, y
  STA A1T1H

  ; source DB
  INY
  LDA sprite_location_table, y
  STA A1B1

  ; 0x1000 bytes
  LDA #$10
  STA DAS1H
  STZ DAS1L

  LDA CHR_BANK_TARGET_BANK
  TAY

  ; save which enemy we've loaded to this slot
  LDA CHR_BANK_BANK_TO_LOAD
  STA SPRITE_LOADED_TABLE, Y

  lda target_sprite_bank_table, Y  
  STA VMADDH
  STZ VMADDL

  LDA #$02
  STA MDMAEN

  PLX
  PLY
  PLA
  PLB
  LDA VMAIN_STATE
  STA VMAIN
  rtl

sprite_bank_to_table_offset:
.byte $02, $02, $02, $02, $0A, $0A, $12, $12, $1A, $1A 

load_enemy_sprites:
  CMP CURRENT_ENEMY_LOADED
  BNE :+
  rtl
: STA ENEMY_TO_LOAD
  STA CURRENT_ENEMY_LOADED

  ; check if we already have it
  LDY #$00
: LDA SPRITE_LOADED_TABLE, Y
  CMP ENEMY_TO_LOAD
  beq found_enemy
  INY
  CPY #$0A
  bne :-

  ; not found, load to last bank for now
  DEY
  STY CHR_BANK_TARGET_BANK
  LDA ENEMY_TO_LOAD
  STA CHR_BANK_BANK_TO_LOAD
  jslb dma_sprite_to_slot, $a0
  LDY #$09
  
found_enemy:
  ; y contains the bank the enemey is in
  STY CURRENT_ENEMY_SLOT
  TYA

  AND #$01
  beq :+
  LDA #$80
: STA CURRENT_ENEMY_TILE_OFFSET

  ; set nametable to 1 for everything but the 1st page
  STZ CURRENT_SPRITE_TABLE_OFFSET
  LDA CURRENT_ENEMY_SLOT
  LSR
  BNE :+
  ; this is on the first page, we don't need to both updating the OBSEL
  rtl
: LDA #$01
  STA CURRENT_SPRITE_TABLE_OFFSET

  LDA CURRENT_ENEMY_SLOT
  TAY
  lda sprite_bank_to_table_offset, Y
  STA OBSEL

  rtl
  

dma_chr_to_vm:
  PHB
  LDA #$A0
  PHA
  PLB

  ; looks like we need to switch CHR Banks
  ; we fake this by DMA'ing tiles from the right tileset
  ; multiply by 3 to get the offset
  LDA CHR_BANK_BANK_TO_LOAD
  ASL A
  ADC CHR_BANK_BANK_TO_LOAD
  TAY

  LDA #$80
  STA VMAIN

  LDA #$01
  STA DMAP1

  LDA #$18
  STA BBAD1

  ; source LB
  LDA bankswap_table, Y
  STA A1T1L

  ; source HB
  INY
  LDA bankswap_table, y
  STA A1T1H

  ; source DB
  INY
  LDA bankswap_table, y
  STA A1B1

  ; 0x2000 bytes
  LDA #$20
  STA DAS1H
  STZ DAS1L

  ; 
  LDA CHR_BANK_TARGET_BANK
  ASL
  ASL
  ASL
  ASL
  STA VMADDH
  STZ VMADDL

  LDA #$02
  STA MDMAEN
  PLB
  LDA VMAIN_STATE
  STA VMAIN

  RTS


level_load_hijack:
  ; original code
  LDA $0422

  jsr load_sprite_sheets_for_area

  ; original code
  ASL
  ASL
  rtl

load_sprite_sheets_for_area:
  PHA
  PHY
  PHX
  PHB
  PHK
  PLB
  STZ CHR_BANK_TARGET_BANK

  AND #$0F
  ASL
  ASL
  ASL
  ASL
  TAY
  LDX #$00

: LDA double_dragon_ii_area_sprite_loads, Y
  CMP #$FF
  BEQ done
  
  STX CHR_BANK_TARGET_BANK
  STX ACTIVE_SPRITE_SECOND_BANK_SLOT
  
  PHY
  PHX
  jslb load_mmc3_bank_to_slot, $a0
  PLX
  PLY

  INY
  INX
  bra :-


done:
  PLB
  PLX
  PLY
  PLA
  rts

double_dragon_ii_area_sprite_loads:
.byte $40, $5A, $4E, $42, $44, $50, $62, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF  ; Area 00
.byte $40, $5A, $42, $44, $4e, $54, $56, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF  ; Area 01
.byte $40, $5A, $4e, $46, $ff, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF  ; Area 02
.byte $40, $5A, $42, $44, $54, $52, $4e, $46, $ff, $FF, $FF, $FF, $FF, $FF, $FF, $FF  ; Area 03
.byte $40, $5A, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF  ; Area 04
.byte $40, $5A, $44, $42, $64, $46, $4c, $54, $52, $ff, $FF, $FF, $FF, $FF, $FF, $FF  ; Area 05
.byte $40, $5A, $54, $4c, $ff, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF  ; Area 06
.byte $40, $5A, $ff, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF  ; Area 07
.byte $40, $5a, $54, $50, $62, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF  ; Area 08
.byte $40, $5A, $ff, $ff, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF  ; Area 09
.byte $40, $5A, $64, $ff, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF  ; Area 0A
.byte $40, $5A, $4e, $64, $4c, $54, $52, $ff, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF  ; Area 0B
.byte $40, $5A, $4c, $54, $52, $46, $56, $4a, $ff, $FF, $FF, $FF, $FF, $FF, $FF, $FF  ; Area 0C
.byte $40, $5A, $60, $ff, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF  ; Area 0D
.byte $40, $5A, $58, $ff, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF  ; Area 0E
.byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF  ; invalid