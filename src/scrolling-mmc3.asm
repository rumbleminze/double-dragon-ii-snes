; SCANLINE_FOR_IRQ                      ; line to start non-hud IRQ
; SCROLL_HDMA_LINE_TO_START_OFFSET    ; line we have to start adjusting for attr
; LINE_TO_START_HUD                   ; line we start for HUD, always #191
; LINES_COMPLETE                      ; lines we've handled

; ordering can be:
; IRQ -> HUD
; ATTR -> HUD (no IRQ set)
; IRQ -> ATTR -> HUD
; ATTR -> IRQ -> HUD
calculate_hdma_l:
    LDA SCANLINE_FOR_IRQ
    CMP #$FF
    BNE :+
    jsl simple_scrolling
    rtl
:
    jsr calculate_hdma
    LDA #$FF
    stA SCANLINE_FOR_IRQ
    rtl
calculate_hdma:
    ; HUD is always last, so the two main cases are ATTR or IRQ first
    ; first easy case is that ATTR > HUD, in which case we don't care about ATTR
    STZ LINES_COMPLETE
    LDX #$00
    LDA #nes_attribute_scanline
    SEC
    SBC curr_voff_low
    SBC #$01
    STA SCROLL_HDMA_LINE_TO_START_OFFSET   
    CMP #LINE_TO_START_HUD
    BCC :++
        ; no need to handle attr
        ; might have IRQ though               
        LDA SCANLINE_FOR_IRQ  
        CMP #$B8
        BCS :+
            jsr store_hdma_entry
            jsr set_values_for_irq
        :
        LDA #LINE_TO_START_HUD
        SEC
        SBC LINES_COMPLETE
        jsr store_hdma_entry
        jsr write_adjusted_hud_values
        jsr write_ending_values
        ; done!
        rts        
    :

    LDA $08AF
    CMP #$B8
    ; game sets B8 for hud, so if it's less than that, then we have a value
    ; that we need to handle an IRQ for
    
    BCC :++    
        ; no irq, does have attr
        ; might have IRQ though
        LDA SCROLL_HDMA_LINE_TO_START_OFFSET
        beq :+
            ; sometimes attr are right at the top!
            jsr store_hdma_entry
        :
        LDA curr_voff_low
        CLC
        ADC #$10
        STA curr_voff_low

        LDA #LINE_TO_START_HUD
        SEC
        SBC LINES_COMPLETE
        
        jsr store_hdma_entry
        jsr write_adjusted_hud_values
        jsr write_ending_values
        ; done!
        rts         

    :

    ; has attr and irq
    LDA SCROLL_HDMA_LINE_TO_START_OFFSET
    CMP SCANLINE_FOR_IRQ
    BCS irq_first
    JMP attr_first

irq_first:
        LDA SCANLINE_FOR_IRQ
        jsr store_hdma_entry

        ; values for h/v offsets is dependant on the value in F4
        ; handle irq for lines from IRQ -> ATTR
        jsr set_values_for_irq

        LDA #LINE_TO_START_HUD ; SCROLL_HDMA_LINE_TO_START_OFFSET
        SEC
        SBC SCANLINE_FOR_IRQ
        jsr store_hdma_entry

        ; now that irq is done, prep for doing attr skip
        ; LDA curr_voff_low
        ; CLC
        ; ADC #$10
        ; STA curr_voff_low

        ; ; do this until hud, no other changes to values
        ; LDA #LINE_TO_START_HUD
        ; SEC
        ; SBC LINES_COMPLETE
        ; jsr store_hdma_entry

        jsr write_adjusted_hud_values
        jsr write_ending_values
        ; done!
        rts

attr_first:

    LDA SCROLL_HDMA_LINE_TO_START_OFFSET
    BEQ :+
        jsr store_hdma_entry
    :
    ; handle attributes
    LDA curr_voff_low
    CLC
    ADC #$10
    STA curr_voff_low

    LDA SCANLINE_FOR_IRQ
    SEC
    SBC SCROLL_HDMA_LINE_TO_START_OFFSET
    jsr store_hdma_entry


    jsr set_values_for_irq
    LDA #LINE_TO_START_HUD
    SEC
    SBC SCANLINE_FOR_IRQ
    jsr store_hdma_entry

    jsr write_adjusted_hud_values
    jsr write_ending_values
    ; done!
    rts

set_values_for_irq:
    LDA $0662
    sta curr_hoff_low

    LDA $F4
    AND #$01
    beq :+
        ; f4 = 1 or 3
        LDA $0661
        sta curr_voff_low
        LDA $0663
        AND #$02
        LSR
        sta VOFS_HB
        rts            
    :
    ; f4 = 2
    LDA #$00
    sta curr_voff_low
    LDA #$01
    sta VOFS_HB
    rts
    
write_ending_values:
    LDA #$00
    STA SCROLL_HDMA_START, X
    STA SCROLL_HDMA_START + 1, X
    rts

write_adjusted_hud_values:
    stz curr_hoff_low
    LDA #$0A
    sta curr_voff_low

    LDA $0663
    AND #$02
    LSR
    EOR #$01
    STA VOFS_HB

    LDA #(240 - LINE_TO_START_HUD)
    jsr store_hdma_entry

    rts

; stores an entry in the hdma table
; for value in A lines
; expects curr_hoff_low, curr_voff_low, VOFS_HB, to be set
; always sets HOFS_HB to 0
;
; increments LINES_COMPLETE by A
; X should be at the current offset, and will be
; increased by 5 (prepping for the next entry)
store_hdma_entry:
    PHA
    CMP #$80
    BCC :+
        LDA #127    
        STA SCROLL_HDMA_START, X

        LDA curr_hoff_low
        STA SCROLL_HDMA_START + 1, X ;hoffl 

        LDA #0
        STA SCROLL_HDMA_START + 2, X ; hoffh

        LDA curr_voff_low
        STA SCROLL_HDMA_START + 3, X ; voffl

        LDA VOFS_HB
        STA SCROLL_HDMA_START + 4, X ; voffh     

        INX
        INX
        INX
        INX
        INX

        PLA
        PHA
        SEC
        SBC #127
:
    STA SCROLL_HDMA_START, X

    LDA curr_hoff_low
    STA SCROLL_HDMA_START + 1, X ;hoffl 

    LDA #0
    STA SCROLL_HDMA_START + 2, X ; hoffh

    LDA curr_voff_low
    STA SCROLL_HDMA_START + 3, X ; voffl

    LDA VOFS_HB
    STA SCROLL_HDMA_START + 4, X ; voffh     

    INX
    INX
    INX
    INX
    INX

    PLA
    CLC
    ADC LINES_COMPLETE
    STA LINES_COMPLETE

    rts