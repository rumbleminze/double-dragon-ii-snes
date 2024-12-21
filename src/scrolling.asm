
infidelitys_scroll_handling:

  ; LDA $F1
  ; AND #$01
  LDA PPU_CONTROL_STATE
  PHA 
  AND #$80
  BNE :+
  LDA #$00
  BRA :++
: LDA #$80
: STA NMITIMEN
  PLA        
  PHA 
  AND #$04
  ; A now has the BG table address
  BNE :+
  LDA #$00
  BRA :++
: LDA #$01   
: STA VMAIN 
  PLA 
  AND #$03
  BEQ :+
  CMP #$01
  BEQ :++
  CMP #$02
  BEQ :+++
  CMP #$03
  BEQ :++++
: STZ HOFS_HB
  STZ VOFS_HB
  BRA :++++   ; RTL
: LDA #$01
  STA HOFS_HB
  STZ VOFS_HB
  BRA :+++    ; RTL
: STZ HOFS_HB
  LDA #$01
  ; STA VOFS_HB
  BRA :++     ; RTL
: LDA #$01
  STA HOFS_HB
  ; STA VOFS_HB

: RTL 


setup_hdma:

  ; line count
  ;   HOFS_LB, HOFS_HB, VOFS_LB, VOFS_LB
  ; x3
  ; 00

  LDX VOFS_LB
  LDA $A0A080,X
  STA SCROLL_HDMA_START + 0
  LDA $A0A180,X
  STA SCROLL_HDMA_START + 3
  LDA $A0A280,X
  STA SCROLL_HDMA_START + 5
  LDA $A0A380,X
  STA SCROLL_HDMA_START + 8
  
  LDA $A0A480,X
  STA SCROLL_HDMA_START + 10
  LDA $A0A560,X
  STA SCROLL_HDMA_START + 13

  LDA HOFS_LB
  STA SCROLL_HDMA_START + 1
  STA SCROLL_HDMA_START + 6
  STA SCROLL_HDMA_START + 11
  
  ; lda $F1
  ; AND #$01
  ; lda #$00
  lda VOFS_HB
  STA SCROLL_HDMA_START + 2
  STA SCROLL_HDMA_START + 7
  STA SCROLL_HDMA_START + 12

  ; v-hi byte
  LDX PPU_CONTROL_STATE
  LDA $A0A610,X
  STA SCROLL_HDMA_START + 4
  STA SCROLL_HDMA_START + 9
  STA SCROLL_HDMA_START + 14

 
  LDY #$0A
  LDA SCROLL_HDMA_START
  STA LINES_COMPLETE


  LDA SCROLL_HDMA_START + 5
  CLC
  ADC LINES_COMPLETE
  STA LINES_COMPLETE
  SEC
  SBC #LINE_TO_START_HUD

  BMI :+
    ; hit the end on 2nd one, back it up
    STA LINES_COMPLETE
    LDA SCROLL_HDMA_START + 5
    SEC
    SBC LINES_COMPLETE
    STA SCROLL_HDMA_START + 5
    BRA write_hud_values
  :

  LDY #$0F
  LDA SCROLL_HDMA_START + 10
  CLC
  ADC LINES_COMPLETE
  STA LINES_COMPLETE
  SEC
  SBC #LINE_TO_START_HUD
  BMI :+
    ; hit the end on the 3rd one, back it up
    STA LINES_COMPLETE
    LDA SCROLL_HDMA_START + 10
    SEC
    SBC LINES_COMPLETE
    STA SCROLL_HDMA_START + 10
    BRA write_hud_values
  :
    ; didn't get to enough lines, we actually have to bump up the last one
    LDA #LINE_TO_START_HUD
    SBC LINES_COMPLETE
    ADC SCROLL_HDMA_START + 10
    STA SCROLL_HDMA_START + 10

write_hud_values:
  LDA #(240 - LINE_TO_START_HUD) ; 40 lines of 0000, 0100
  STA SCROLL_HDMA_START, Y
  INY 
  ; for mode B we want to load 0800, 0001
    ;   LDA $3D
    ;   AND #$04
    ;   BEQ :+
    ;   LDA #$08
    ;   BRA :++
    ; : LDA #$00
    ; :
  LDA #$00
  STA SCROLL_HDMA_START, Y  
  LDA #$00
  INY
  STA SCROLL_HDMA_START, Y
  LDA #$0A
  INY
  STA SCROLL_HDMA_START, Y

  ; this controls if we use 2000 or 2400 for the hud source
  ; we usually use 2400, but if we're scrolling up/down then we use 2000  
    LDX #$01
    LDA $0663
    AND #$02
    BEQ :+
    LDX #$00
  : TXA
  ; : 
  INY
  STA SCROLL_HDMA_START, Y

  ; end hdma byte
  LDA #$00
  INY
  STA SCROLL_HDMA_START, Y


  RTL
default_scrolling_hdma_values:
.byte $6F, $00, $92, $00, $C9, $58, $00, $92, $00, $C9, $27, $00, $00, $00, $01, $00

set_scrolling_hdma_defaults:

  LDA $3D
  AND #$04
  BEQ :+
  LDA $3E
  AND #$01
  BEQ :+
  jmp simple_scrolling

: PHY
  PHB
  LDA #$A0
  PHA
  PLB
  LDY #$00
: LDA default_scrolling_hdma_values, Y
  CPY #$0f
  BEQ :+
  STA SCROLL_HDMA_START, Y
  INY
  BRA :-

: PLB
  PLY
  RTL

  ; used where we just want to set the scroll to 0,0 and not worry about 
; attributes, because they'll naturally be offscreen
simple_scrolling:
  LDA #$00
  STA BG1VOFS
  LDA #$00
  STA BG1VOFS
  STZ BG1HOFS
  STZ BG1HOFS
  STZ SCROLL_HDMA_START
  STZ SCROLL_HDMA_START + 1
  STZ SCROLL_HDMA_START + 2
  RTL

reset_offsets:
  STZ BG1VOFS
  STZ BG1VOFS
  STZ BG1HOFS
  STZ BG1HOFS
  rtl

reset_scroll_from_662:
  LDA $0662
  STA BG1VOFS
  STZ BG1VOFS

  LDA $0663
  STA BG1HOFS
  STZ BG1HOFS
  rtl

set_scroll_for_frame_freeze:
  LDA $F5
  STA BG1HOFS
  STZ BG1HOFS

  LDA $0661
  STA BG1VOFS
  STZ BG1VOFS

  rtl

; set_irq_scroll_if_needed:
;   ; IRQs are triggered based on the value in $F4
;   ; which jumps to one of these addresses at EC64:
;   ; 6C EC 7D EC B7 EC 7D EC
;   ; EC6C (F4 = 0) - Sets the offsets for the HUD, we handle this every frame during scrolling
;   ; EC7D (F4 = 1) - used to scroll BG Horizontally during some middle of level fights, like the first lvl 2 helicopter 
;   ; ECB7 (F4 = 2) - used to scroll the BG Vertically? like 2nd lvl 2 helicopter take off
;   ; EC7D (F4 = 3) -this one is there twice /shrug
;   ;
;   ; This routein will handle the 1 & 3 cases
;   LDA $F4
;   AND #$01
;   BNE :+
;   rtl


  ; the first 4 are always going to be
  ; standard x/y offsets
  ; 
  ; lines_for_this_hdma = $00

  ; irq_scroll_start = $00

  max_lines = 127 ; max number of scanlines we can write for hdma
  voff_to_handle_attributes = 239
  total_scanlines = 224
  hud_start_scanline = 192 ; scanline that we always draw the hud.  NA DD2 is actually 184, but JP is 192.

  nes_attribute_scanline = 240
  hud_voffset = 8
  hud_size = 32
  voffset_where_hud_hides_attributes = 48

  ; voffset_bump = voff_low + 32 ; amount to add to the voffset after the attribute scanlines

  ; if curr_voff_low < 64
  ;   ; no need to hide attributes
  ;   set attribute start to 0
  ;   set attribute offset to 0
  ; else
  ;   set attribute start to 248 - curr_voff_low
  ;   set attribute offset to voff_low + 0x20
  ;   set line count 185 - attribute start


store_values:
    STA SCROLL_HDMA_START, X
    LDA curr_hoff_low
    STA SCROLL_HDMA_START + 1, X ;hoffl  
    LDA curr_voff_low
    STA SCROLL_HDMA_START + 3, X ; voffl
    LDA VOFS_HB
    STA SCROLL_HDMA_START + 4, X ; voffh           
    INX
    INX
    INX
    INX
    INX
    rts

; variables
handle_scroll:
  LDA $F4
  BNE :+
  jmp handle_scroll_no_irq
: 

handle_scroll_f4_is_2_irq:
  ; there are a few weird scenarios we have to handle with irqs
  ; we could have entries to handle these cases
  ; 
  ; IRQ is after 128 & attributes hiddend
  ; 0 - 127  : Standard, first half
  ; 128 - IRQ: Standard, 2nd half
  ; IRQ - 192: IRQ handling
  ; 192 - end: HUD
  ;
  ; IRQ is after 128 & attributes will show after 128
  ; 0 - 127  : Standard, first half
  ; 128 - att: Standard, 2nd half
  ; att - IRQ: adjust voffs to hide attributes
  ; IRQ - 192: IRQ handling
  ; 192 - end: HUD
  ;
  ; 

  ; calculate the line to start voffset increase
  LDA #nes_attribute_scanline
  SEC
  SBC curr_voff_low
  STA SCROLL_HDMA_LINE_TO_START_OFFSET

  STZ SCROLL_HDMA_LINES_HANDLED

  ldx #$00
  STX SCROLL_HDMA_NEXT_TO_HANDLE

  LDA SCANLINE_FOR_IRQ
  CMP SCROLL_HDMA_LINE_TO_START_OFFSET
  BMI :+
    ; if scroll HDMA starts before the IRQ, we need to do that one first
    LDA SCROLL_HDMA_LINE_TO_START_OFFSET
    INC SCROLL_HDMA_NEXT_TO_HANDLE ; set next to handle to IRQ
  :
  STA lines_left_to_handle
  LDA lines_left_to_handle

  BPL :+
    ; current lines to handle is > 127
    LDA #127    
    STA SCROLL_HDMA_LINES_HANDLED
    jsr store_values
    LDA lines_left_to_handle
    SEC
    SBC #$7F
    STA lines_left_to_handle
  :

  PHA
  ADC SCROLL_HDMA_LINES_HANDLED
  STA SCROLL_HDMA_LINES_HANDLED
  PLA
  ; write the rest of the first group (either to attribute or to IRQ)
  jsr store_values

  ; we're either at attribute bump or IRQ handling
  LDA SCROLL_HDMA_NEXT_TO_HANDLE
  beq :+
    ; handle IRQ values
    LDA SCROLL_HDMA_LINE_TO_START_OFFSET
    CMP #LINE_TO_START_HUD


    STA SCROLL_HDMA_START, X
    LDA $0662
    STA SCROLL_HDMA_START + 1, X ; hoffl
    LDA $0663
    STA SCROLL_HDMA_START + 3, X ; voffl
    LDA VOFS_HB
    STA SCROLL_HDMA_START + 4, X

    INX
    INX
    INX
    INX
    INX


    bra :+++
  :
    ; handle attributes
    LDA curr_voff_low
    ADC #$10
    STA curr_voff_low

    LDA IRQ_SCROLL_HDMA_START
    SEC
    SBC SCROLL_HDMA_LINES_HANDLED
    PHA

    BPL :+
      ; over 127 lines
      LDA #127
      jsr store_values
      LDA #127
      ADC SCROLL_HDMA_LINES_HANDLED
      STA SCROLL_HDMA_LINES_HANDLED

      PLA
      SEC
      SBC #127
      PHA           
    :

    PLA
    PHA    
    jsr store_values
    PLA
    ADC SCROLL_HDMA_LINES_HANDLED
    STA SCROLL_HDMA_LINES_HANDLED
  :

handle_scroll_f4_is_1_irq:
  ; this setup is used when f4 is set to $01, which uses IRQ to set the scroll back to stand values 
  ; at a specific line (which was written to $C000, and we read from SCANLINE_FOR_IRQ)
  ; For Double Dragon II, we'll NEVER have to deal with IRQ and Attributes
  ; because it only uses the IRQ for adjusting scrolling when voffset is 0
   LDA $0663 ; PPU_CONTROL_STATE
   AND #$02
   LSR
   STA VOFS_HB
   
  ;  first we do our normal offset to the IRQ line


    ldx #$00
    LDA SCANLINE_FOR_IRQ
    STA lines_left_to_handle

    bpl :+
      ; non-hud irq is > 127 lines
      LDA #127
      STA SCROLL_HDMA_START
      LDA curr_hoff_low
      STA SCROLL_HDMA_START + 1 ;hoffl
      LDA curr_voff_low
      STA SCROLL_HDMA_START + 3 ; voffl
      LDX #$05

      LDA lines_left_to_handle
      SEC
      SBC #$7F
      STA lines_left_to_handle
    :

    jsr store_values

    LDA #hud_start_scanline
    SEC
    SBC SCANLINE_FOR_IRQ

    STA SCROLL_HDMA_START, X
    LDA $0662
    STA SCROLL_HDMA_START + 1, X ; hoffl
    LDA $0661
    STA SCROLL_HDMA_START + 3, X ; voffl
    LDA VOFS_HB
    STA SCROLL_HDMA_START + 4, X

    INX
    INX
    INX
    INX
    INX

    jmp hud_hdma


    ; now we adjust the h/v offset based on logic


handle_scroll_no_irq:
   LDA $0663 ; PPU_CONTROL_STATE
   AND #$02
   LSR
   STA VOFS_HB

   LDA SCANLINE_FOR_IRQ
   BNE :+
    LDA PPU_CONTROL_STATE
    AND #$02
    LSR
    STA VOFS_HB
   :

   LDA curr_voff_low
   CMP #(voffset_where_hud_hides_attributes)
   bcs :+
    jmp handle_scroll_no_irq_no_attributes
  :
   ; need to handle attributes  
   ; we know we have at least 56 lines of setting the current offsets

  ; calculate the number of lines before we need to handle attributes
  ldx #$00
  LDA #voff_to_handle_attributes
  SEC 
  SBC curr_voff_low
  sta lines_left_to_handle
  pha

  bpl :+

  ; more than 127 lines, need to break it up
    LDA #127
    STA SCROLL_HDMA_START
    LDA curr_hoff_low
    STA SCROLL_HDMA_START + 1 ;hoffl
    LDA curr_voff_low
    STA SCROLL_HDMA_START + 3 ; voffl
    LDX #$05

    LDA lines_left_to_handle
    SEC
    SBC #$7F
    STA lines_left_to_handle
  :

  ; if this is 0 we're smack dab in the middle of attributeland
  beq :+
  jsr store_values
:
  ; now until hud needs to be +16 offset
  LDA curr_voff_low
  CLC
  ADC #$10
  STA current_voff_offset

  pla
  STA lines_left_to_handle
  LDA #total_scanlines
  SEC
  sbc lines_left_to_handle
  sbc #hud_size
  STA lines_left_to_handle
  bit lines_left_to_handle
  bpl :+
  ; more than 127 lines, need to break it up
    LDA #127
    jsr store_values
    LDA lines_left_to_handle
    SEC
    SBC #$7F
    STA lines_left_to_handle     
  :
 ; store the rest
 jsr store_values

hud_hdma:
  ; these are always the same
  STZ SCROLL_HDMA_START + 2 ;hoffh
  STZ SCROLL_HDMA_START + 7 ;hoffh
  STZ SCROLL_HDMA_START + 12 ;hoffh
  STZ SCROLL_HDMA_START + 17 ;hoffh
  STZ SCROLL_HDMA_START + 22 ;hoffh

  ; HUD now
  LDA SCANLINE_FOR_IRQ
  beq :+
    LDA #$01
    STA SCROLL_HDMA_START, X
    LDA #$00
    STA SCROLL_HDMA_START + 1, X
    LDA #hud_voffset
    STA SCROLL_HDMA_START + 3, X
    LDA VOFS_HB
    EOR #$01
    STA SCROLL_HDMA_START + 4, X
    STZ SCANLINE_FOR_IRQ
    INX
    INX
    INX
    INX
    INX
:
  LDA #$00
  STA SCROLL_HDMA_START, X
  STA SCROLL_HDMA_START + 1, X

  rtl 

; handles the simplest case, where Voffset < 64 so attributes are hidden either below the screen
; or by the hud
; since we know what all the values are, we can just hardcode these values
handle_scroll_no_irq_no_attributes:

   LDA #max_lines
   STA SCROLL_HDMA_START + (0 * 5)

   STZ SCROLL_HDMA_START + (1 * 5)
   LDA SCANLINE_FOR_IRQ
   beq :+    
   LDA #(hud_start_scanline - max_lines)
   STA SCROLL_HDMA_START + (1 * 5)
   STZ SCANLINE_FOR_IRQ

: 

   LDA #1
   STA SCROLL_HDMA_START + (2 * 5)
   
   LDA curr_hoff_low
   STA SCROLL_HDMA_START + 1 + (0 * 5)
   STA SCROLL_HDMA_START + 1 + (1 * 5)
   ; this it the hud, we always want this to be 0
   STZ SCROLL_HDMA_START + 1 + (2 * 5)

   ; hoff high bit is always 0, since we don't have 2 bg screens
   STZ SCROLL_HDMA_START + 2 + (0 * 5)
   STZ SCROLL_HDMA_START + 2 + (1 * 5)
   STZ SCROLL_HDMA_START + 2 + (2 * 5)

   LDA curr_voff_low
   STA SCROLL_HDMA_START + 3 + (0 * 5)
   STA SCROLL_HDMA_START + 3 + (1 * 5)

   LDA #hud_voffset
   STA SCROLL_HDMA_START + 3 + (2 * 5)
   

   LDA VOFS_HB
   STA SCROLL_HDMA_START + 4 + (0 * 5)
   STA SCROLL_HDMA_START + 4 + (1 * 5)
   EOR #$01
   STA SCROLL_HDMA_START + 4 + (2 * 5)

  ;  AND #$FC
  ;  ORA $0663
  ;  EOR #$02
  ;  STA PPU_CONTROL_STATE

   STZ SCROLL_HDMA_START + (3 * 5)
   STZ SCROLL_HDMA_START + 1 + (3 * 5)

   rtl

.include "scrolling-mmc3.asm"